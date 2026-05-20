import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class DocumentDetailsPage extends StatelessWidget {
  const DocumentDetailsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Detalhe do documento',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Comprovante hospital',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 8),
                const Text('Categoria: Comprovantes'),
                const Text('Competência: Maio/2026'),
                const SizedBox(height: 12),
                const Text('Motivo de rejeição',
                    style: TextStyle(
                        fontWeight: FontWeight.w600, color: AppColors.danger)),
                const Text(
                    'Arquivo ilegível. Envie uma foto com melhor iluminação.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppButton(
              label: 'Reenviar documento',
              icon: Icons.upload_file,
              onPressed: () {}),
          const SizedBox(height: 10),
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.download_outlined),
              label: const Text('Baixar anexo')),
        ],
      ),
    );
  }
}
