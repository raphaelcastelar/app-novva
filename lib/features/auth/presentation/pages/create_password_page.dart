import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class CreatePasswordPage extends ConsumerStatefulWidget {
  const CreatePasswordPage({required this.cpf, super.key});

  final String cpf;

  @override
  ConsumerState<CreatePasswordPage> createState() => _CreatePasswordPageState();
}

class _CreatePasswordPageState extends ConsumerState<CreatePasswordPage> {
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Use pelo menos 8 caracteres.')));
      return;
    }
    if (_password.text != _confirm.text) {
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('As senhas não coincidem.')));
      return;
    }
    await ref
        .read(authControllerProvider.notifier)
        .createPassword(widget.cpf, _password.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(ErrorHandler.userMessage(error))));
      });
    });
    return Scaffold(
      appBar: AppBar(),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text('Crie sua senha',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Nova senha', controller: _password, obscureText: true),
            const SizedBox(height: 12),
            AppTextField(
                label: 'Confirmar senha',
                controller: _confirm,
                obscureText: true),
            const SizedBox(height: 20),
            AppButton(
                label: 'Cadastrar',
                loading: state.isLoading,
                onPressed: _submit),
          ],
        ),
      ),
    );
  }
}
