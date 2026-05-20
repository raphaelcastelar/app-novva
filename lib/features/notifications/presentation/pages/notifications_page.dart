import 'package:flutter/material.dart';

import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    const items = [
      'DAS vence hoje. Copie o código de pagamento.',
      'Documento rejeitado: comprovante hospital.',
      'Seu contador respondeu ao chamado de dúvida fiscal.',
    ];
    return AppScaffold(
      title: 'Notificações',
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: items.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) => AppCard(
            child: ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.notifications_outlined),
                title: Text(items[index]))),
      ),
    );
  }
}
