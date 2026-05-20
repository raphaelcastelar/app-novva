import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';

class PaymentsPage extends StatelessWidget {
  const PaymentsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Mensalidade contábil', '20/05/2026', 'R\$ 490,00', 'Pendente'),
      ('DAS Simples Nacional', '20/05/2026', 'R\$ 1.680,30', 'A vencer'),
      ('Mensalidade abril', '20/04/2026', 'R\$ 490,00', 'Pago'),
    ];
    return AppScaffold(
      title: 'Financeiro',
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          final item = items[index];
          return AppCard(
            child: Row(
              children: [
                const Icon(Icons.account_balance_wallet_outlined),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(item.$1,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${item.$2} - ${item.$3}'),
                    ],
                  ),
                ),
                StatusBadge(item.$4),
              ],
            ),
          );
        },
      ),
    );
  }
}
