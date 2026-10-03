import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class PrivacyPage extends ConsumerStatefulWidget {
  const PrivacyPage({super.key});

  @override
  ConsumerState<PrivacyPage> createState() => _PrivacyPageState();
}

class _PrivacyPageState extends ConsumerState<PrivacyPage> {
  bool _deleting = false;

  Future<void> _requestDeletion() async {
    final password = await _confirmPassword();
    if (password == null || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(authControllerProvider.notifier).deleteAccount(password);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_deletionError(error))),
      );
      setState(() => _deleting = false);
    }
  }

  Future<String?> _confirmPassword() async {
    final controller = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.warning_amber_rounded,
            color: AppColors.danger, size: 34),
        title: const Text('Excluir sua conta?'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Esta ação é permanente. Seu acesso, solicitações, documentos e demais dados vinculados serão excluídos.',
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: controller,
                obscureText: true,
                autofocus: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Confirme sua senha',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
                validator: (value) => (value?.length ?? 0) < 8
                    ? 'Informe sua senha atual.'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: AppColors.danger),
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, controller.text);
              }
            },
            child: const Text('Excluir definitivamente'),
          ),
        ],
      ),
    );
    controller.dispose();
    return result;
  }

  String _deletionError(Object error) {
    if (error is DioException) {
      final data = error.response?.data;
      if (data is Map<String, dynamic>) {
        final message = data['message'];
        if (message is String && message.isNotEmpty) return message;
      }
    }
    return 'Não foi possível excluir a conta. Tente novamente.';
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Privacidade e conta',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
        children: [
          const _PrivacySection(
            icon: Icons.shield_outlined,
            title: 'Como cuidamos dos seus dados',
            body:
                'Usamos seus dados cadastrais, profissionais, solicitações e documentos para prestar os serviços contábeis solicitados, proteger sua conta e cumprir obrigações legais.',
          ),
          const SizedBox(height: 12),
          const _PrivacySection(
            icon: Icons.storage_outlined,
            title: 'Armazenamento e segurança',
            body:
                'Os dados ficam em infraestrutura protegida. Documentos só podem ser acessados pela sua conta e pela equipe administrativa autorizada.',
          ),
          const SizedBox(height: 12),
          const _PrivacySection(
            icon: Icons.manage_accounts_outlined,
            title: 'Seus direitos',
            body:
                'Você pode solicitar confirmação, acesso, correção e exclusão dos seus dados. Para dúvidas, fale com a Novva pelo e-mail ${AppConstants.supportEmail}.',
          ),
          const SizedBox(height: 12),
          const _PrivacySection(
            icon: Icons.backup_outlined,
            title: 'Exclusão e backups',
            body:
                'Ao excluir a conta, os dados ativos e arquivos vinculados são removidos. Cópias protegidas em backups deixam de existir conforme o ciclo de retenção, em até 30 dias.',
          ),
          const SizedBox(height: 24),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Excluir conta',
                  style: TextStyle(
                    color: AppColors.danger,
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'A exclusão é permanente e encerra imediatamente todas as suas sessões.',
                  style: TextStyle(color: AppColors.muted, height: 1.45),
                ),
                const SizedBox(height: 16),
                AppButton(
                  label: 'Excluir minha conta',
                  icon: Icons.delete_outline,
                  loading: _deleting,
                  onPressed: _requestDeletion,
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Center(
            child: Text(
              'Política atualizada em 3 de outubro de 2026',
              style: TextStyle(color: AppColors.muted, fontSize: 12),
            ),
          ),
        ],
      ),
    );
  }
}

class _PrivacySection extends StatelessWidget {
  const _PrivacySection({
    required this.icon,
    required this.title,
    required this.body,
  });

  final IconData icon;
  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.softPrimary,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icon, color: AppColors.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 5),
                Text(body,
                    style:
                        const TextStyle(color: AppColors.muted, height: 1.45)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
