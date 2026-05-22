import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = [
      (
        'Relatórios',
        'Faturamento, impostos e insights',
        Icons.bar_chart_outlined,
        RouteNames.reports
      ),
      (
        'Chat / Meu contador',
        'Converse com a equipe Novva',
        Icons.support_agent_outlined,
        RouteNames.chat
      ),
      (
        'Perfil médico',
        'Dados pessoais, CRM e preferências',
        Icons.person_outline,
        RouteNames.profile
      ),
      (
        'CNPJs',
        'Empresas vinculadas e CNPJ ativo',
        Icons.business_outlined,
        RouteNames.cnpjs
      ),
      (
        'Configurações',
        'Tema, biometria e segurança',
        Icons.tune_outlined,
        RouteNames.settings
      ),
      (
        'Notificações',
        'Guias, documentos e mensagens',
        Icons.notifications_outlined,
        RouteNames.notifications
      ),
      (
        'Ajuda',
        'Central de aprendizado e suporte',
        Icons.help_outline,
        RouteNames.chat
      ),
      (
        'Segurança',
        'Senha, acesso e biometria',
        Icons.lock_outline,
        RouteNames.profile
      ),
      (
        'Área administrativa',
        'Clientes e rotinas internas',
        Icons.admin_panel_settings_outlined,
        RouteNames.clients
      ),
    ];

    return AppScaffold(
      title: 'Mais',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppCard(
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: AppColors.softAccent,
                  child: Text(
                    'DM',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Dra. Marina Almeida',
                        style: TextStyle(fontWeight: FontWeight.w900),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Cardiologia • CRM-SP 123456',
                        style: TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                StatusBadge('Regular', color: AppColors.success),
              ],
            ),
          ),
          const SizedBox(height: 14),
          ...options.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () {
                  if (item.$4 != RouteNames.settings) context.go(item.$4);
                },
                child: Row(
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: AppColors.softPrimary,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(item.$3, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.$1,
                            style: const TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.$2,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.muted),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            icon: const Icon(Icons.logout),
            label: const Text('Sair com segurança'),
          ),
        ],
      ),
    );
  }
}
