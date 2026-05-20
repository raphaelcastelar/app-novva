import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final options = [
      ('Perfil médico', Icons.person_outline, RouteNames.profile),
      ('Gerenciar CNPJs', Icons.business_outlined, RouteNames.cnpjs),
      ('Notificações', Icons.notifications_outlined, RouteNames.notifications),
      (
        'Área administrativa',
        Icons.admin_panel_settings_outlined,
        RouteNames.clients
      ),
    ];
    return AppScaffold(
      title: 'Configurações',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          ...options.map(
            (item) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => context.go(item.$3),
                child: ListTile(
                    contentPadding: EdgeInsets.zero,
                    leading: Icon(item.$2),
                    title: Text(item.$1),
                    trailing: const Icon(Icons.chevron_right)),
              ),
            ),
          ),
          const SizedBox(height: 10),
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
