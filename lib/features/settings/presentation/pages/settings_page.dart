import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  bool? _faceIdAvailable;
  bool _faceIdEnabled = false;
  bool _updatingFaceId = false;

  @override
  void initState() {
    super.initState();
    _loadFaceId();
  }

  Future<void> _loadFaceId() async {
    final service = ref.read(biometricAuthServiceProvider);
    final values = await Future.wait([
      service.canCheckBiometrics(),
      service.isEnabled,
    ]);
    if (!mounted) return;
    setState(() {
      _faceIdAvailable = values[0];
      _faceIdEnabled = values[1];
    });
  }

  Future<void> _toggleFaceId(bool enabled) async {
    if (_updatingFaceId) return;
    setState(() => _updatingFaceId = true);
    final service = ref.read(biometricAuthServiceProvider);
    final changed = enabled ? await service.enable() : true;
    if (!enabled) await service.disable();
    if (!mounted) return;
    setState(() {
      _updatingFaceId = false;
      _faceIdEnabled = enabled && changed;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          enabled
              ? changed
                  ? 'Face ID ativado com sucesso.'
                  : 'Não foi possível ativar o Face ID.'
              : 'Face ID desativado.',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(authControllerProvider).valueOrNull;
    const options = [
      (
        'Notificações',
        'Avisos e diagnóstico de entrega',
        Icons.notifications_outlined,
        RouteNames.notifications,
      ),
      (
        'Privacidade e conta',
        'Seus dados e exclusão da conta',
        Icons.privacy_tip_outlined,
        RouteNames.privacy,
      ),
      (
        'Ajuda e suporte',
        'Canais de atendimento da Novva',
        Icons.help_outline,
        RouteNames.support,
      ),
    ];

    return AppScaffold(
      title: 'Mais',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
        children: [
          AppCard(
            child: Row(
              children: [
                const ProfileAvatar(
                  radius: 26,
                  backgroundColor: AppColors.softAccent,
                  foregroundColor: AppColors.primary,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        user?.name ?? 'Conta Novva',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      if (user?.email case final email?) ...[
                        const SizedBox(height: 2),
                        Text(email,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(color: AppColors.muted)),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppCard(
            child: SwitchListTile(
              contentPadding: EdgeInsets.zero,
              secondary: const CircleAvatar(
                backgroundColor: AppColors.softPrimary,
                child: Icon(Icons.face_outlined, color: AppColors.primary),
              ),
              title: const Text('Entrar com Face ID',
                  style: TextStyle(fontWeight: FontWeight.w900)),
              subtitle: Text(
                _faceIdAvailable == null
                    ? 'Verificando disponibilidade...'
                    : _faceIdAvailable!
                        ? 'Use o Face ID após confirmar o CPF salvo'
                        : 'Face ID não está configurado neste aparelho',
              ),
              value: _faceIdEnabled,
              onChanged: _faceIdAvailable == true && !_updatingFaceId
                  ? _toggleFaceId
                  : null,
            ),
          ),
          const SizedBox(height: 14),
          for (final item in options)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: AppCard(
                onTap: () => context.go(item.$4),
                child: ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.softPrimary,
                    child: Icon(item.$3, color: AppColors.primary),
                  ),
                  title: Text(item.$1,
                      style: const TextStyle(fontWeight: FontWeight.w900)),
                  subtitle: Text(item.$2),
                  trailing: const Icon(Icons.chevron_right),
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
