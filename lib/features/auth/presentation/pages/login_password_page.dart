import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class LoginPasswordPage extends ConsumerStatefulWidget {
  const LoginPasswordPage({required this.cpf, super.key});

  final String cpf;

  @override
  ConsumerState<LoginPasswordPage> createState() => _LoginPasswordPageState();
}

class _LoginPasswordPageState extends ConsumerState<LoginPasswordPage> {
  final _passwordController = TextEditingController();

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
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
      appBar: AppBar(
          leading:
              BackButton(onPressed: () => context.go(RouteNames.loginCpf))),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Image.asset('assets/images/logo.png', height: 112),
            const SizedBox(height: 24),
            Text('Informe sua senha',
                style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            AppTextField(
                label: 'Senha',
                controller: _passwordController,
                obscureText: true),
            const SizedBox(height: 16),
            AppButton(
              label: 'Entrar',
              icon: Icons.login,
              loading: state.isLoading,
              onPressed: () => ref
                  .read(authControllerProvider.notifier)
                  .login(widget.cpf, _passwordController.text),
            ),
            TextButton(
              onPressed: () => context.push(RouteNames.forgotPassword),
              child: const Text('Esqueceu a senha?'),
            ),
          ],
        ),
      ),
    );
  }
}
