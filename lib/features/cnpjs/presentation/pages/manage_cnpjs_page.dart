import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';

class ManageCnpjsPage extends StatelessWidget {
  const ManageCnpjsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const cnpjs = [
      ('Hospital Vida', '12.345.678/0001-99'),
      ('Clínica Norte', '98.765.432/0001-10')
    ];
    return AppScaffold(
      title: 'Gerenciar CNPJs',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppTextField(label: 'Apelido'),
          const SizedBox(height: 10),
          const AppTextField(label: 'CNPJ', keyboardType: TextInputType.number),
          const SizedBox(height: 12),
          AppButton(
              label: 'Adicionar CNPJ',
              icon: Icons.add_business_outlined,
              onPressed: () {}),
          const SizedBox(height: 20),
          ...cnpjs.map((item) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: AppCard(
                  child: ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(item.$1),
                      subtitle: Text(item.$2),
                      trailing: const Icon(Icons.delete_outline))))),
        ],
      ),
    );
  }
}
