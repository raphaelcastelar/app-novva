import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/obligation.dart';
import '../providers/obligations_providers.dart';

class ObligationsPage extends ConsumerWidget {
  const ObligationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligations = ref.watch(obligationListProvider);
    final featuredObligation = obligations.firstWhere(
      (item) => item.status != ObligationStatus.paid,
      orElse: () => obligations.first,
    );
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        title: 'Guias',
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _DasHeroCard(item: featuredObligation),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Em aberto'),
                Tab(text: 'Pagas'),
                Tab(text: 'Vencidas'),
                Tab(text: 'Todas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ObligationList(
                    obligations: obligations
                        .where((item) =>
                            item.status == ObligationStatus.open ||
                            item.status == ObligationStatus.dueSoon)
                        .toList(),
                  ),
                  _ObligationList(
                    obligations: obligations
                        .where((item) => item.status == ObligationStatus.paid)
                        .toList(),
                  ),
                  _ObligationList(
                    obligations: obligations
                        .where(
                            (item) => item.status == ObligationStatus.overdue)
                        .toList(),
                  ),
                  _AnnualObligationHistory(obligations: obligations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DasHeroCard extends ConsumerWidget {
  const _DasHeroCard({required this.item});

  final Obligation item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _ObligationCard._color(item.status);
    final isPaid = item.status == ObligationStatus.paid;
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.softAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Acompanhe, baixe e informe o pagamento da guia.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _referenceMonth(item.dueDate),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusBadge(_ObligationCard._label(item.status),
                        color: color),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  isPaid
                      ? 'Pagamento informado pelo usuário'
                      : 'Vence em ${AppFormatters.date(item.dueDate)}',
                  style: const TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Text(
                  AppFormatters.money(item.amount),
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Baixar PDF'),
                    ),
                    if (!isPaid)
                      OutlinedButton.icon(
                        onPressed: () => _showPaymentConfirmationSheet(
                          context: context,
                          ref: ref,
                          item: item,
                        ),
                        icon: const Icon(Icons.check_circle_outline, size: 18),
                        label: const Text('Marquei como pago'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: Colors.white,
                          side: const BorderSide(color: Colors.white24),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObligationList extends StatelessWidget {
  const _ObligationList({required this.obligations});

  final List<Obligation> obligations;

  @override
  Widget build(BuildContext context) {
    if (obligations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhuma guia nesta categoria.'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: obligations.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        return _ObligationCard(item: obligations[index]);
      },
    );
  }
}

class _AnnualObligationHistory extends StatefulWidget {
  const _AnnualObligationHistory({required this.obligations});

  final List<Obligation> obligations;

  @override
  State<_AnnualObligationHistory> createState() =>
      _AnnualObligationHistoryState();
}

class _AnnualObligationHistoryState extends State<_AnnualObligationHistory> {
  late int selectedYear;

  @override
  void initState() {
    super.initState();
    selectedYear = _availableYears.first;
  }

  @override
  void didUpdateWidget(covariant _AnnualObligationHistory oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (!_availableYears.contains(selectedYear)) {
      selectedYear = _availableYears.first;
    }
  }

  List<int> get _availableYears {
    final years = widget.obligations.map((item) => item.dueDate.year).toSet()
      ..add(DateTime.now().year);
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  @override
  Widget build(BuildContext context) {
    final yearItems = widget.obligations
        .where((item) => item.dueDate.year == selectedYear)
        .toList()
      ..sort((a, b) => a.dueDate.compareTo(b.dueDate));
    final paidItems = yearItems
        .where((item) => item.status == ObligationStatus.paid)
        .toList();
    final pendingItems = yearItems
        .where((item) => item.status != ObligationStatus.paid)
        .toList();
    final paidTotal = paidItems.fold<double>(
      0,
      (total, item) => total + item.amount,
    );
    final pendingTotal = pendingItems.fold<double>(
      0,
      (total, item) => total + item.amount,
    );
    final progress =
        yearItems.isEmpty ? 0.0 : paidItems.length / yearItems.length;
    final nextOpen = pendingItems.isEmpty
        ? null
        : (pendingItems..sort((a, b) => a.dueDate.compareTo(b.dueDate))).first;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _AnnualSummaryCard(
          year: selectedYear,
          progress: progress,
          paidTotal: paidTotal,
          pendingTotal: pendingTotal,
          nextOpen: nextOpen,
          availableYears: _availableYears,
          onYearSelected: (year) => setState(() => selectedYear = year),
        ),
        const SizedBox(height: 14),
        for (var month = 1; month <= 12; month++) ...[
          _MonthHistoryTile(
            month: month,
            year: selectedYear,
            obligations:
                yearItems.where((item) => item.dueDate.month == month).toList(),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _AnnualSummaryCard extends StatelessWidget {
  const _AnnualSummaryCard({
    required this.year,
    required this.progress,
    required this.paidTotal,
    required this.pendingTotal,
    required this.availableYears,
    required this.onYearSelected,
    this.nextOpen,
  });

  final int year;
  final double progress;
  final double paidTotal;
  final double pendingTotal;
  final Obligation? nextOpen;
  final List<int> availableYears;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.softPrimary,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.auto_graph_outlined,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Histórico $year',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Uma leitura rápida do ano fiscal.',
                      style: TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              Text(
                '${(progress * 100).round()}%',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor:
                  const AlwaysStoppedAnimation<Color>(AppColors.success),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final option in availableYears)
                ChoiceChip(
                  label: Text('$option'),
                  selected: option == year,
                  onSelected: (_) => onYearSelected(option),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _HistoryMetric(
                  label: 'Pago',
                  value: AppFormatters.money(paidTotal),
                  color: AppColors.success,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _HistoryMetric(
                  label: 'A acompanhar',
                  value: AppFormatters.money(pendingTotal),
                  color: AppColors.warning,
                ),
              ),
            ],
          ),
          if (nextOpen != null) ...[
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  const Icon(Icons.event_available_outlined,
                      color: AppColors.primary),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Próxima atenção: ${nextOpen!.name}, ${AppFormatters.date(nextOpen!.dueDate)}',
                      style: const TextStyle(
                        color: AppColors.text,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _HistoryMetric extends StatelessWidget {
  const _HistoryMetric({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthHistoryTile extends ConsumerWidget {
  const _MonthHistoryTile({
    required this.month,
    required this.year,
    required this.obligations,
  });

  final int month;
  final int year;
  final List<Obligation> obligations;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final total = obligations.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );
    final status = _monthStatus(obligations);
    final color = _ObligationCard._color(status);
    final paidCount = obligations
        .where((item) => item.status == ObligationStatus.paid)
        .length;

    return Material(
      color: AppColors.surface,
      borderRadius: BorderRadius.circular(22),
      child: Ink(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
          boxShadow: const [
            BoxShadow(
              color: AppColors.shadow,
              blurRadius: 18,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Theme(
          data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
          child: ExpansionTile(
            tilePadding: const EdgeInsets.symmetric(horizontal: 14),
            childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
            leading: Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.11),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Center(
                child: Text(
                  _monthShortLabel(month),
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
            title: Text(
              _monthLabel(month),
              style: const TextStyle(fontWeight: FontWeight.w900),
            ),
            subtitle: Text(
              obligations.isEmpty
                  ? 'Nenhuma guia prevista'
                  : '$paidCount/${obligations.length} pagas • ${AppFormatters.money(total)}',
              style: const TextStyle(color: AppColors.muted),
            ),
            trailing: StatusBadge(_monthStatusLabel(obligations), color: color),
            children: [
              if (obligations.isEmpty)
                const _EmptyMonthStrip()
              else
                for (final item in obligations) ...[
                  _CompactObligationRow(item: item, ref: ref),
                  if (item != obligations.last) const SizedBox(height: 8),
                ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CompactObligationRow extends StatelessWidget {
  const _CompactObligationRow({required this.item, required this.ref});

  final Obligation item;
  final WidgetRef ref;

  @override
  Widget build(BuildContext context) {
    final color = _ObligationCard._color(item.status);
    final isPaid = item.status == ObligationStatus.paid;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.receipt_outlined, color: color, size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 2),
                Text(
                  '${AppFormatters.money(item.amount)} • ${AppFormatters.date(item.dueDate)}',
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          if (isPaid)
            const Icon(Icons.check_circle, color: AppColors.success)
          else
            IconButton.filledTonal(
              tooltip: 'Marcar como pago',
              onPressed: () {
                ref.read(obligationListProvider.notifier).markAsPaid(item.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${item.name} marcada como paga.')),
                );
              },
              icon: const Icon(Icons.check_rounded),
            ),
        ],
      ),
    );
  }
}

class _EmptyMonthStrip extends StatelessWidget {
  const _EmptyMonthStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Text(
        'Sem guias registradas para este mês.',
        style: TextStyle(color: AppColors.muted),
      ),
    );
  }
}

class _ObligationCard extends ConsumerWidget {
  const _ObligationCard({required this.item});

  final Obligation item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final color = _color(item.status);
    final isPaid = item.status == ObligationStatus.paid;
    return AppCard(
      onTap: () => context.go(RouteNames.obligationDetails),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.receipt_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mês de referência: ${_referenceMonth(item.dueDate)}',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusBadge(_label(item.status), color: color),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  label: 'Vencimento',
                  value: AppFormatters.date(item.dueDate),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  label: 'Valor',
                  value: AppFormatters.money(item.amount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (isPaid) ...[
            const _PaidConfirmationStrip(),
            const SizedBox(height: 12),
          ],
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallAction(
                  icon: Icons.download_outlined, label: 'PDF', onTap: () {}),
              if (!isPaid)
                _SmallAction(
                  icon: Icons.check_circle_outline,
                  label: 'Marquei como pago',
                  onTap: () => _showPaymentConfirmationSheet(
                    context: context,
                    ref: ref,
                    item: item,
                  ),
                ),
              if (item.paymentCode != null)
                _SmallAction(
                  icon: Icons.copy_outlined,
                  label: 'Copiar código',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item.paymentCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado.')),
                    );
                  },
                ),
              _SmallAction(
                icon: Icons.share_outlined,
                label: 'Compartilhar',
                onTap: () {},
              ),
              _SmallAction(
                icon: Icons.upload_file_outlined,
                label: 'Comprovante',
                onTap: () => context.go(RouteNames.documentUpload),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _label(ObligationStatus status) => switch (status) {
        ObligationStatus.open => 'Em aberto',
        ObligationStatus.dueSoon => 'A vencer',
        ObligationStatus.overdue => 'Vencido',
        ObligationStatus.paid => 'Pago',
        ObligationStatus.canceled => 'Cancelado',
      };

  static Color _color(ObligationStatus status) => switch (status) {
        ObligationStatus.open => AppColors.primary,
        ObligationStatus.dueSoon => AppColors.warning,
        ObligationStatus.overdue => AppColors.danger,
        ObligationStatus.paid => AppColors.success,
        ObligationStatus.canceled => AppColors.muted,
      };
}

Future<void> _showPaymentConfirmationSheet({
  required BuildContext context,
  required WidgetRef ref,
  required Obligation item,
}) {
  return showModalBottomSheet<void>(
    context: context,
    showDragHandle: true,
    isScrollControlled: true,
    builder: (sheetContext) {
      return SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: const Icon(
                      Icons.verified_outlined,
                      color: AppColors.success,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Confirmar pagamento',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                item.name,
                style: const TextStyle(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '${AppFormatters.money(item.amount)} • vence em ${AppFormatters.date(item.dueDate)}',
                style: const TextStyle(color: AppColors.muted),
              ),
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.softAccent,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(Icons.info_outline, color: AppColors.accent),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'A guia será movida para Pagas. Depois, você ainda pode enviar o comprovante pelo card.',
                        style: TextStyle(
                          color: AppColors.text,
                          height: 1.35,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: FilledButton.icon(
                  onPressed: () {
                    ref
                        .read(obligationListProvider.notifier)
                        .markAsPaid(item.id);
                    Navigator.of(sheetContext).pop();
                    DefaultTabController.maybeOf(context)?.animateTo(1);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text('${item.name} marcada como paga.'),
                      ),
                    );
                  },
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar como pago'),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _PaidConfirmationStrip extends StatelessWidget {
  const _PaidConfirmationStrip();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.success.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.success.withValues(alpha: 0.18)),
      ),
      child: const Row(
        children: [
          Icon(Icons.check_circle, color: AppColors.success, size: 18),
          SizedBox(width: 8),
          Expanded(
            child: Text(
              'Pagamento informado pelo usuário',
              style: TextStyle(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _referenceMonth(DateTime date) {
  return '${_monthLabel(date.month).toLowerCase()}/${date.year}';
}

String _monthLabel(int month) {
  const months = [
    'Janeiro',
    'Fevereiro',
    'Março',
    'Abril',
    'Maio',
    'Junho',
    'Julho',
    'Agosto',
    'Setembro',
    'Outubro',
    'Novembro',
    'Dezembro',
  ];
  return months[month - 1];
}

String _monthShortLabel(int month) {
  const months = [
    'JAN',
    'FEV',
    'MAR',
    'ABR',
    'MAI',
    'JUN',
    'JUL',
    'AGO',
    'SET',
    'OUT',
    'NOV',
    'DEZ',
  ];
  return months[month - 1];
}

ObligationStatus _monthStatus(List<Obligation> obligations) {
  if (obligations.isEmpty) return ObligationStatus.canceled;
  if (obligations.any((item) => item.status == ObligationStatus.overdue)) {
    return ObligationStatus.overdue;
  }
  if (obligations.any((item) => item.status == ObligationStatus.dueSoon)) {
    return ObligationStatus.dueSoon;
  }
  if (obligations.any((item) => item.status == ObligationStatus.open)) {
    return ObligationStatus.open;
  }
  return ObligationStatus.paid;
}

String _monthStatusLabel(List<Obligation> obligations) {
  if (obligations.isEmpty) return 'Sem guias';
  final paidCount =
      obligations.where((item) => item.status == ObligationStatus.paid).length;
  if (paidCount == obligations.length) return 'Fechado';
  if (paidCount > 0) return 'Parcial';
  return _ObligationCard._label(_monthStatus(obligations));
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
