import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';

class InvoiceDescriptionPage extends StatelessWidget {
  const InvoiceDescriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Descrição da NFs-e',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppTextField(label: 'Descrição do serviço', maxLines: 6),
          const SizedBox(height: 16),
          AppButton(
              label: 'Solicitar emissão da NFs-e',
              icon: Icons.send_outlined,
              onPressed: () {}),
        ],
      ),
    );
  }
}
