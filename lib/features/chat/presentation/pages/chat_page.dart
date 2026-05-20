import 'package:flutter/material.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    const tickets = [
      (
        'Dúvida fiscal',
        'Em atendimento',
        'Como declarar plantões pagos por PJ?'
      ),
      (
        'Envio de documento',
        'Respondido',
        'Contrato do novo hospital recebido.'
      ),
      ('Pagamento', 'Finalizado', 'Boleto da mensalidade confirmado.'),
    ];
    return AppScaffold(
      title: 'Mensagens',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          AppButton(
              label: 'Novo chamado',
              icon: Icons.add_comment_outlined,
              onPressed: () {}),
          const SizedBox(height: 12),
          ...tickets.map(
            (ticket) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: const Icon(Icons.forum_outlined),
                  title: Text(ticket.$1),
                  subtitle: Text(ticket.$3),
                  trailing: Text(ticket.$2),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
