import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class MedicalProfilePage extends StatelessWidget {
  const MedicalProfilePage({super.key});

  @override
  Widget build(BuildContext context) {
    const fields = {
      'Nome': 'Dra. Marina Almeida',
      'CPF': '128.311.467-47',
      'CNPJ': '12.345.678/0001-99',
      'CRM': 'CRM-SP 123456',
      'Especialidade': 'Cardiologia',
      'Regime tributário': 'Simples Nacional',
      'Empresa': 'Marina Almeida Serviços Médicos LTDA',
      'Status': 'Cadastro regular',
    };
    return AppScaffold(
      title: 'Perfil médico',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: fields.entries
            .map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: AppCard(
                    child: ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(entry.key),
                        subtitle: Text(entry.value))),
              ),
            )
            .toList(),
      ),
    );
  }
}
