import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _cpf = TextEditingController();

  @override
  void dispose() {
    _cpf.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
                'Informe seu CPF. A recuperação real deve ser conectada ao backend seguro, sem enviar senhas por e-mail.'),
            const SizedBox(height: 16),
            AppTextField(
                label: 'CPF',
                controller: _cpf,
                keyboardType: TextInputType.number),
            const SizedBox(height: 20),
            AppButton(
              label: 'Enviar instruções',
              loading: state.isLoading,
              onPressed: () async {
                await ref.read(authRepositoryProvider).requestPasswordReset(
                    _cpf.text.replaceAll(RegExp(r'\D'), ''));
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                      content: Text('Instruções enviadas, se o CPF existir.')));
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
