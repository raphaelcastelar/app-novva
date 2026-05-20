import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/status_badge.dart';

class ClientsPage extends StatelessWidget {
  const ClientsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const clients = [
      ('Dra. Marina Almeida', 'CRM-SP 123456', '3 pendências'),
      ('Dr. Felipe Castro', 'CRM-RJ 654321', 'Regular'),
    ];
    return AppScaffold(
      title: 'Clientes médicos',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppTextField(
              label: 'Buscar por nome, CPF, CNPJ, CRM ou e-mail'),
          const SizedBox(height: 16),
          ...clients.map((client) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: AppCard(
                  child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading:
                        const CircleAvatar(child: Icon(Icons.person_outline)),
                    title: Text(client.$1),
                    subtitle: Text(client.$2),
                    trailing: StatusBadge(client.$3),
                  ),
                ),
              )),
        ],
      ),
    );
  }
}
