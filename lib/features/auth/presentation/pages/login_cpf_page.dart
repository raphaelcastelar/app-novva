import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class LoginCpfPage extends ConsumerStatefulWidget {
  const LoginCpfPage({super.key});

  @override
  ConsumerState<LoginCpfPage> createState() => _LoginCpfPageState();
}

class _LoginCpfPageState extends ConsumerState<LoginCpfPage> {
  final _formKey = GlobalKey<FormState>();
  final _cpfController = TextEditingController();

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _continue() async {
    if (!_formKey.currentState!.validate()) return;
    final user = await ref
        .read(authControllerProvider.notifier)
        .verifyCpf(_cpfController.text);
    if (!mounted) return;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('CPF não encontrado.')));
      return;
    }
    final route = user.needsPasswordCreation
        ? RouteNames.createPassword
        : RouteNames.loginPassword;
    context.go('$route?cpf=${user.cpf}');
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
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset('assets/images/logo.png', height: 132),
                  const SizedBox(height: 12),
                  Text('Novva',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.displaySmall),
                  const SizedBox(height: 32),
                  AppTextField(
                    label: 'Informe seu CPF',
                    controller: _cpfController,
                    keyboardType: TextInputType.number,
                    validator: (value) =>
                        (value ?? '').replaceAll(RegExp(r'\D'), '').length == 11
                            ? null
                            : 'Digite 11 números.',
                  ),
                  const SizedBox(height: 20),
                  AppButton(
                    label: 'Continuar',
                    icon: Icons.arrow_forward,
                    loading: state.isLoading,
                    onPressed: _continue,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
