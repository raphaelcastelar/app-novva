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
    final obligations = ref.watch(obligationsProvider);
    return AppScaffold(
      title: 'Guias e obrigações',
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: obligations.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = obligations[index];
          return AppCard(
            onTap: () => context.go(RouteNames.obligationDetails),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(item.name,
                            style:
                                const TextStyle(fontWeight: FontWeight.w600))),
                    StatusBadge(_label(item.status),
                        color: _color(item.status)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                    'Vence em ${AppFormatters.date(item.dueDate)} - ${AppFormatters.money(item.amount)}'),
                if (item.paymentCode != null)
                  TextButton.icon(
                    onPressed: () => Clipboard.setData(
                        ClipboardData(text: item.paymentCode!)),
                    icon: const Icon(Icons.copy, size: 18),
                    label: const Text('Copiar código de pagamento'),
                  ),
              ],
            ),
          );
        },
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
