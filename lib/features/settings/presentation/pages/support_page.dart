import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class SupportPage extends StatelessWidget {
  const SupportPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Ajuda e suporte',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppColors.softAccent,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.support_agent,
                      color: AppColors.primary, size: 28),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Como podemos ajudar?',
                  style: TextStyle(fontSize: 21, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Envie sua dúvida, relate um problema ou solicite informações sobre seus dados e sua conta.',
                  style: TextStyle(color: AppColors.muted, height: 1.5),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: const CircleAvatar(
                backgroundColor: AppColors.softPrimary,
                child: Icon(Icons.email_outlined, color: AppColors.primary),
              ),
              title: const Text('Atendimento por e-mail',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: const Padding(
                padding: EdgeInsets.only(top: 4),
                child: SelectableText(AppConstants.supportEmail),
              ),
              trailing: IconButton(
                tooltip: 'Copiar e-mail',
                icon: const Icon(Icons.copy_outlined),
                onPressed: () async {
                  await Clipboard.setData(
                    const ClipboardData(text: AppConstants.supportEmail),
                  );
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('E-mail copiado.')),
                  );
                },
              ),
            ),
          ),
          const SizedBox(height: 12),
          const AppCard(
            child: ListTile(
              contentPadding: EdgeInsets.zero,
              leading: CircleAvatar(
                backgroundColor: AppColors.softPrimary,
                child: Icon(Icons.schedule_outlined, color: AppColors.primary),
              ),
              title: Text('Prazo de resposta',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Padding(
                padding: EdgeInsets.only(top: 4),
                child: Text('Até 2 dias úteis.'),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Ao entrar em contato, não envie senhas, códigos de acesso ou documentos sensíveis por e-mail.',
            textAlign: TextAlign.center,
            style:
                TextStyle(color: AppColors.muted, fontSize: 12, height: 1.45),
          ),
        ],
      ),
    );
  }
}
