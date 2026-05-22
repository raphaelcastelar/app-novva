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
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/firstpage.png',
              fit: BoxFit.cover,
            ),
          ),
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.04),
                    Colors.black.withValues(alpha: 0.24),
                    Colors.black.withValues(alpha: 0.58),
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Align(
              alignment: Alignment.bottomCenter,
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 12),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.92),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.72),
                    ),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Acesse sua área contábil',
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Informe seu CPF para continuar.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 20),
                        AppTextField(
                          label: 'Informe seu CPF',
                          controller: _cpfController,
                          keyboardType: TextInputType.number,
                          validator: (value) => (value ?? '')
                                      .replaceAll(RegExp(r'\D'), '')
                                      .length ==
                                  11
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
          ),
        ],
      ),
    );
  }
}
