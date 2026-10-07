import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/obligation.dart';
import '../providers/obligations_providers.dart';

class ObligationsPage extends ConsumerWidget {
  const ObligationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligations = ref.watch(obligationListProvider);
    return AppScaffold(
      title: 'Guias',
      child: obligations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorState(
          message: 'Não foi possível carregar suas guias.',
          onRetry: () => ref.invalidate(obligationListProvider),
        ),
        data: (items) => _GuidesTimeline(
          items: items,
          onRefresh: () => ref.refresh(obligationListProvider.future),
        ),
      ),
    );
  }
}

class _GuidesTimeline extends StatefulWidget {
  const _GuidesTimeline({required this.items, required this.onRefresh});

  final List<Obligation> items;
  final Future<void> Function() onRefresh;

  @override
  State<_GuidesTimeline> createState() => _GuidesTimelineState();
}

class _GuidesTimelineState extends State<_GuidesTimeline>
    with WidgetsBindingObserver {
  late int _selectedYear;
  late int _currentCalendarYear;

  @override
  void initState() {
    super.initState();
    _currentCalendarYear = DateTime.now().year;
    _selectedYear = _currentCalendarYear;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final yearNow = DateTime.now().year;
    if (yearNow == _currentCalendarYear) return;
    setState(() {
      _currentCalendarYear = yearNow;
      _selectedYear = yearNow;
    });
  }

  List<int> get _availableYears {
    final years = widget.items.map((item) => item.dueDate.year).toSet()
      ..add(DateTime.now().year);
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  List<int> get _orderedMonths {
    final now = DateTime.now();
    if (_selectedYear != now.year) {
      return List.generate(12, (index) => 12 - index);
    }
    return [
      for (var month = now.month; month >= 1; month--) month,
      for (var month = now.month + 1; month <= 12; month++) month,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final yearItems = widget.items
        .where((item) => item.dueDate.year == _selectedYear)
        .toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    final availableMonths = yearItems.map((item) => item.dueDate.month).toSet();
    final monthsWithFile = yearItems
        .where((item) => item.hasFile)
        .map((item) => item.dueDate.month)
        .toSet();

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 132),
        children: [
          _GuidesHero(
            year: _selectedYear,
            years: _availableYears,
            registeredCount: availableMonths.length,
            downloadCount: monthsWithFile.length,
            onYearSelected: (year) => setState(() => _selectedYear = year),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              const Expanded(
                child: Text(
                  'Competências',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                ),
              ),
              Text(
                '$_selectedYear',
                style: const TextStyle(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Baixe sua guia ou solicite um recálculo em cada mês.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 14),
          for (final month in _orderedMonths) ...[
            _MonthGuideCard(
              month: month,
              year: _selectedYear,
              items: yearItems
                  .where((item) => item.dueDate.month == month)
                  .toList(),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _GuidesHero extends StatelessWidget {
  const _GuidesHero({
    required this.year,
    required this.years,
    required this.registeredCount,
    required this.downloadCount,
    required this.onYearSelected,
  });

  final int year;
  final List<int> years;
  final int registeredCount;
  final int downloadCount;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(28),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 30,
            offset: Offset(0, 16),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned(
            right: -24,
            top: -28,
            child: Icon(
              Icons.receipt_long_outlined,
              color: Colors.white.withValues(alpha: 0.08),
              size: 150,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.2),
                  ),
                ),
                child: const Icon(
                  Icons.calendar_view_month_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Central de guias',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 5),
              const Text(
                'Tudo organizado por competência, em um só lugar.',
                style: TextStyle(color: Color(0xD9FFFFFF), height: 1.35),
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _HeroMetric(
                      value: '$downloadCount',
                      label: 'para baixar',
                      icon: Icons.download_done_rounded,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _HeroMetric(
                      value: '$registeredCount',
                      label: 'cadastradas',
                      icon: Icons.task_alt_rounded,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final option in years) ...[
                      ChoiceChip(
                        label: Text('$option'),
                        selected: option == year,
                        onSelected: (_) => onYearSelected(option),
                        selectedColor: Colors.white,
                        backgroundColor: Colors.white.withValues(alpha: 0.12),
                        side: BorderSide(
                          color: Colors.white.withValues(alpha: 0.22),
                        ),
                        labelStyle: TextStyle(
                          color: option == year
                              ? AppColors.primaryDark
                              : Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroMetric extends StatelessWidget {
  const _HeroMetric({
    required this.value,
    required this.label,
    required this.icon,
  });

  final String value;
  final String label;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 20),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: Color(0xCFFFFFFF),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MonthGuideCard extends ConsumerStatefulWidget {
  const _MonthGuideCard({
    required this.month,
    required this.year,
    required this.items,
  });

  final int month;
  final int year;
  final List<Obligation> items;

  @override
  ConsumerState<_MonthGuideCard> createState() => _MonthGuideCardState();
}

class _MonthGuideCardState extends ConsumerState<_MonthGuideCard> {
  bool _downloading = false;
  bool _requesting = false;

  List<Obligation> get _downloadable =>
      widget.items.where((item) => item.hasFile).toList();

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return now.year == widget.year && now.month == widget.month;
  }

  @override
  Widget build(BuildContext context) {
    final presentation = _monthPresentation(widget.items);
    final total = widget.items.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: _isCurrentMonth ? AppColors.accent : AppColors.border,
          width: _isCurrentMonth ? 1.5 : 1,
        ),
        boxShadow: const [
          BoxShadow(
            color: AppColors.shadow,
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _MonthBadge(
                  month: widget.month,
                  color: presentation.color,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              _monthLabel(widget.month),
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.w900,
                              ),
                            ),
                          ),
                          if (_isCurrentMonth) ...[
                            const SizedBox(width: 7),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 7,
                                vertical: 3,
                              ),
                              decoration: BoxDecoration(
                                color: AppColors.softAccent,
                                borderRadius: BorderRadius.circular(999),
                              ),
                              child: const Text(
                                'MÊS ATUAL',
                                style: TextStyle(
                                  color: AppColors.accent,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 5),
                      Text(
                        presentation.description,
                        style: const TextStyle(
                          color: AppColors.muted,
                          height: 1.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(presentation.label, color: presentation.color),
              ],
            ),
            const SizedBox(height: 14),
            if (widget.items.isEmpty)
              const _WaitingGuidePanel()
            else ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 11,
                ),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.account_balance_wallet_outlined,
                      color: AppColors.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 9),
                    const Expanded(
                      child: Text(
                        'Total da competência',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    Text(
                      AppFormatters.money(total),
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              for (var index = 0; index < widget.items.length; index++) ...[
                _GuideEntry(widget.items[index]),
                if (index < widget.items.length - 1) const Divider(height: 22),
              ],
            ],
            const SizedBox(height: 16),
            LayoutBuilder(
              builder: (context, constraints) {
                final buttonWidth = (constraints.maxWidth - 8) / 2;
                return Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    SizedBox(
                      width: buttonWidth,
                      child: FilledButton.icon(
                        onPressed: _downloadable.isEmpty || _downloading
                            ? null
                            : _downloadGuide,
                        icon: _downloading
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.download_rounded, size: 19),
                        label: Text(
                          _downloading ? 'Baixando...' : 'Baixar guia',
                          maxLines: 1,
                        ),
                      ),
                    ),
                    SizedBox(
                      width: buttonWidth,
                      child: OutlinedButton.icon(
                        onPressed: _requesting ? null : _requestRecalculation,
                        icon: _requesting
                            ? const SizedBox.square(
                                dimension: 17,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Icon(Icons.refresh_rounded, size: 19),
                        label: const Text(
                          'Pedir recálculo',
                          maxLines: 1,
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),
            if (_downloadable.isEmpty) ...[
              const SizedBox(height: 8),
              const Row(
                children: [
                  Icon(
                    Icons.info_outline_rounded,
                    size: 15,
                    color: AppColors.muted,
                  ),
                  SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'O download será liberado quando o PDF for publicado.',
                      style: TextStyle(
                        color: AppColors.muted,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Future<void> _downloadGuide() async {
    final selected = await _selectGuideToDownload();
    if (selected == null || !mounted) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref.read(downloadObligationProvider)(selected.id);
      final directory = await getTemporaryDirectory();
      final safeName = selected.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final month = widget.month.toString().padLeft(2, '0');
      final file = File(
        '${directory.path}/${safeName}_$month-${widget.year}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível baixar a guia.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<Obligation?> _selectGuideToDownload() async {
    if (_downloadable.length == 1) return _downloadable.first;
    return showModalBottomSheet<Obligation>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Qual guia deseja baixar?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              for (final item in _downloadable)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const CircleAvatar(
                    backgroundColor: AppColors.softPrimary,
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(AppFormatters.money(item.amount)),
                  trailing: const Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, item),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _requestRecalculation() async {
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: const Icon(
                      Icons.refresh_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Solicitar recálculo',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${_monthLabel(widget.month)} de ${widget.year}',
                          style: const TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Text(
                'A equipe Novva receberá uma solicitação para revisar os valores e disponibilizar uma nova guia para esta competência.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _requesting = true);
    try {
      await ref.read(requestObligationRecalculationProvider)(
        month: widget.month,
        year: widget.year,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Recálculo de ${_monthLabel(widget.month).toLowerCase()} solicitado.',
          ),
        ),
      );
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Não foi possível solicitar o recálculo.'),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _requesting = false);
    }
  }
}

class _MonthBadge extends StatelessWidget {
  const _MonthBadge({required this.month, required this.color});

  final int month;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 48,
      height: 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month.toString().padLeft(2, '0'),
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            _monthShortLabel(month),
            style: TextStyle(
              color: color,
              fontSize: 9,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}

class _WaitingGuidePanel extends StatelessWidget {
  const _WaitingGuidePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.schedule_rounded, color: AppColors.muted, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhuma guia foi cadastrada para este mês.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideEntry extends ConsumerStatefulWidget {
  const _GuideEntry(this.item);

  final Obligation item;

  @override
  ConsumerState<_GuideEntry> createState() => _GuideEntryState();
}

class _GuideEntryState extends ConsumerState<_GuideEntry> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = _statusColor(item.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: const TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(_statusLabel(item.status), color: color),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          'Vencimento ${AppFormatters.date(item.dueDate)} • ${AppFormatters.money(item.amount)}',
          style: const TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        if (!item.hasFile) ...[
          const SizedBox(height: 6),
          const Text(
            'PDF aguardando publicação',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (item.paymentCode != null ||
            (item.status != ObligationStatus.paid &&
                item.status != ObligationStatus.canceled)) ...[
          const SizedBox(height: 7),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (item.paymentCode case final code?)
                TextButton.icon(
                  onPressed: () => _copyCode(code),
                  icon: const Icon(Icons.copy_outlined, size: 17),
                  label: const Text('Copiar código'),
                ),
              if (item.status != ObligationStatus.paid &&
                  item.status != ObligationStatus.canceled)
                TextButton.icon(
                  onPressed: _saving ? null : _markAsPaid,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.check_circle_outline, size: 17),
                  label: const Text('Informar pagamento'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  Future<void> _markAsPaid() async {
    setState(() => _saving = true);
    try {
      await ref.read(markObligationPaidProvider)(widget.item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento informado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível informar o pagamento.')),
      );
    }
  }
}

class _MonthPresentation {
  const _MonthPresentation({
    required this.label,
    required this.description,
    required this.color,
  });

  final String label;
  final String description;
  final Color color;
}

_MonthPresentation _monthPresentation(List<Obligation> items) {
  if (items.isEmpty) {
    return const _MonthPresentation(
      label: 'Aguardando',
      description: 'A guia ainda não está no sistema.',
      color: AppColors.muted,
    );
  }
  if (items.every((item) => item.status == ObligationStatus.paid)) {
    return const _MonthPresentation(
      label: 'Concluído',
      description: 'Todas as guias desta competência estão pagas.',
      color: AppColors.success,
    );
  }
  if (items.any((item) => item.status == ObligationStatus.overdue)) {
    return const _MonthPresentation(
      label: 'Atenção',
      description: 'Existe uma guia vencida nesta competência.',
      color: AppColors.danger,
    );
  }
  if (!items.any((item) => item.hasFile)) {
    return const _MonthPresentation(
      label: 'Preparando',
      description: 'A guia foi cadastrada e o PDF será publicado em breve.',
      color: AppColors.warning,
    );
  }
  return const _MonthPresentation(
    label: 'Disponível',
    description: 'Sua guia está pronta para download.',
    color: AppColors.primary,
  );
}

String _monthLabel(int month) => const [
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
    ][month - 1];

String _monthShortLabel(int month) => const [
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
    ][month - 1];

String _statusLabel(ObligationStatus status) => switch (status) {
      ObligationStatus.open => 'Em aberto',
      ObligationStatus.dueSoon => 'A vencer',
      ObligationStatus.overdue => 'Vencida',
      ObligationStatus.paid => 'Paga',
      ObligationStatus.canceled => 'Cancelada',
    };

Color _statusColor(ObligationStatus status) => switch (status) {
      ObligationStatus.paid => AppColors.success,
      ObligationStatus.overdue => AppColors.danger,
      ObligationStatus.dueSoon => AppColors.warning,
      ObligationStatus.canceled => AppColors.muted,
      ObligationStatus.open => AppColors.primary,
    };
