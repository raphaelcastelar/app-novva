import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/errors/error_handler.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_page_shell.dart';

class LoginPasswordPage extends ConsumerStatefulWidget {
  const LoginPasswordPage({required this.cpf, super.key});

  final String cpf;

  @override
  ConsumerState<LoginPasswordPage> createState() => _LoginPasswordPageState();
}

class _LoginPasswordPageState extends ConsumerState<LoginPasswordPage> {
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _passwordController.dispose();
    super.dispose();
  }

  void _login() {
    ref.read(authControllerProvider.notifier).login(
          widget.cpf,
          _passwordController.text,
        );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(authControllerProvider);
    ref.listen(authControllerProvider, (_, next) {
      next.whenOrNull(error: (error, _) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      });
    });

    return AuthPageShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AuthTextField(
              label: 'Senha',
              controller: _passwordController,
              hintText: 'Digite sua senha',
              obscureText: _obscurePassword,
              onFieldSubmitted: (_) => _login(),
              suffixIcon: IconButton(
                tooltip: _obscurePassword ? 'Mostrar senha' : 'Ocultar senha',
                onPressed: () => setState(
                  () => _obscurePassword = !_obscurePassword,
                ),
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: authMuted,
                  size: 20,
                ),
              ),
            ),
            const SizedBox(height: 5),
            Row(
              children: [
                TextButton.icon(
                  onPressed: () => context.go(RouteNames.loginCpf),
                  style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFC1CED4),
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  icon: const Icon(Icons.chevron_left, size: 18),
                  label: const Text('Alterar CPF'),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => context.push(
                    '${RouteNames.forgotPassword}?cpf=${widget.cpf}',
                  ),
                  style: TextButton.styleFrom(
                    foregroundColor: authAccent,
                    padding: EdgeInsets.zero,
                    textStyle: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: const Text('Esqueci minha senha'),
                ),
              ],
            ),
            const SizedBox(height: 6),
            AuthPrimaryButton(
              label: 'Entrar',
              loading: state.isLoading,
              onPressed: _login,
            ),
            const Spacer(),
            const AuthHelpFooter(),
          ],
        ),
      ),
    );
  }
}
