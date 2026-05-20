import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';

class DocumentUploadPage extends StatefulWidget {
  const DocumentUploadPage({super.key});

  @override
  State<DocumentUploadPage> createState() => _DocumentUploadPageState();
}

class _DocumentUploadPageState extends State<DocumentUploadPage> {
  String category = 'Notas fiscais';

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Enviar documento',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          DropdownButtonFormField<String>(
            initialValue: category,
            items: const [
              'Notas fiscais',
              'Recibos',
              'Extratos bancários',
              'Comprovantes',
              'Impostos',
              'Contratos',
              'Declarações',
              'Outros',
            ]
                .map((item) => DropdownMenuItem(value: item, child: Text(item)))
                .toList(),
            onChanged: (value) => setState(() => category = value ?? category),
            decoration: const InputDecoration(labelText: 'Categoria'),
          ),
          const SizedBox(height: 12),
          const AppTextField(label: 'Observação', maxLines: 4),
          const SizedBox(height: 16),
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.photo_camera_outlined),
              label: const Text('Tirar foto')),
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.attach_file),
              label: const Text('Anexar arquivo')),
          const SizedBox(height: 16),
          AppButton(
              label: 'Enviar para análise',
              icon: Icons.lock_outline,
              onPressed: () {}),
        ],
      ),
    );
  }
}
