import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class ObligationDetailsPage extends StatelessWidget {
  const ObligationDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detalhe da guia',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('DAS Simples Nacional',
                    style:
                        TextStyle(fontWeight: FontWeight.w600, fontSize: 18)),
                SizedBox(height: 8),
                Text('Competência: 05/2026'),
                Text('Valor: R\$ 1.680,30'),
                Text('Status: A vencer'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
              label: 'Marcar como pago',
              icon: Icons.check_circle_outline,
              onPressed: () {}),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Visualizar PDF')),
        ],
      ),
    );
  }
}
