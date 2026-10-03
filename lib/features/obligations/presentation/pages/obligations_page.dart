import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
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
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.refresh(obligationListProvider.future),
          child: items.isEmpty
              ? const _EmptyObligations()
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, index) => _ObligationCard(items[index]),
                ),
        ),
      ),
    );
  }
}

class _EmptyObligations extends StatelessWidget {
  const _EmptyObligations();

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(32),
      children: const [
        SizedBox(height: 100),
        Icon(Icons.receipt_long_outlined, size: 54, color: AppColors.muted),
        SizedBox(height: 16),
        Text('Nenhuma guia disponível',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
        SizedBox(height: 6),
        Text(
          'As guias cadastradas pela contabilidade aparecerão aqui.',
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.muted),
        ),
      ],
    );
  }
}

class _ObligationCard extends ConsumerStatefulWidget {
  const _ObligationCard(this.item);
  final Obligation item;

  @override
  ConsumerState<_ObligationCard> createState() => _ObligationCardState();
}

class _ObligationCardState extends ConsumerState<_ObligationCard> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = _statusColor(item.status);
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              CircleAvatar(
                backgroundColor: color.withValues(alpha: 0.12),
                child: Icon(Icons.receipt_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item.name,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    Text('Vence em ${AppFormatters.date(item.dueDate)}',
                        style: const TextStyle(color: AppColors.muted)),
                  ],
                ),
              ),
              StatusBadge(_statusLabel(item.status), color: color),
            ],
          ),
          const SizedBox(height: 16),
          Text(AppFormatters.money(item.amount),
              style:
                  const TextStyle(fontSize: 22, fontWeight: FontWeight.w900)),
          if (item.paymentCode case final code?) ...[
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _copyCode(code),
              icon: const Icon(Icons.copy_outlined),
              label: const Text('Copiar código de pagamento'),
            ),
          ],
          if (item.status != ObligationStatus.paid &&
              item.status != ObligationStatus.canceled) ...[
            const SizedBox(height: 8),
            FilledButton.icon(
              onPressed: _saving ? null : _markAsPaid,
              icon: _saving
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.check_circle_outline),
              label: const Text('Informar pagamento'),
            ),
          ],
        ],
      ),
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
