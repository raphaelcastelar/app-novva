import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
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
  String? _savedCpf;
  String? _savedUserName;
  bool _loadingSavedAccount = true;
  bool _showCpfForm = false;

  @override
  void initState() {
    super.initState();
    _loadSavedAccount();
  }

  Future<void> _loadSavedAccount() async {
    final tokenManager = ref.read(tokenManagerProvider);
    final values = await Future.wait([tokenManager.cpf, tokenManager.userName]);
    if (!mounted) return;
    setState(() {
      _savedCpf = values[0]?.isNotEmpty == true ? values[0] : null;
      _savedUserName = values[1]?.isNotEmpty == true ? values[1] : null;
      _loadingSavedAccount = false;
      _showCpfForm = _savedCpf == null;
    });
  }

  @override
  void dispose() {
    _cpfController.dispose();
    super.dispose();
  }

  Future<void> _accessSavedAccount() async {
    final cpf = _savedCpf;
    if (cpf == null) return;
    final authenticated = await ref
        .read(authControllerProvider.notifier)
        .loginWithBiometrics(cpf);
    if (!mounted || authenticated) return;
    context.go('${RouteNames.loginPassword}?cpf=$cpf');
  }

  void _accessAnotherAccount() {
    _cpfController.clear();
    setState(() => _showCpfForm = true);
  }

  Future<void> _continueWithAnotherAccount() async {
    if (!_formKey.currentState!.validate()) return;
    final user = await ref
        .read(authControllerProvider.notifier)
        .verifyCpf(_cpfController.text);
    if (!mounted) return;
    if (ref.read(authControllerProvider).hasError) return;
    if (user == null) {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('CPF não encontrado.')));
      return;
    }
    if (user.needsPasswordCreation) {
      context.go('${RouteNames.createPassword}?cpf=${user.cpf}');
      return;
    }

    context.go('${RouteNames.loginPassword}?cpf=${user.cpf}');
  }

  String _formattedCpf(String cpf) {
    final digits = cpf.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return cpf;
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.'
        '${digits.substring(6, 9)}-${digits.substring(9)}';
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
                  child: _loadingSavedAccount
                      ? const SizedBox(
                          height: 160,
                          child: Center(child: CircularProgressIndicator()),
                        )
                      : Form(
                          key: _formKey,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                _showCpfForm
                                    ? 'Acesse sua área contábil'
                                    : 'Bem-vindo de volta',
                                style: Theme.of(context)
                                    .textTheme
                                    .titleLarge
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 6),
                              Text(
                                _showCpfForm
                                    ? 'Informe seu CPF para continuar.'
                                    : 'Confirme a conta que deseja acessar.',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                              if (_showCpfForm) ...[
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
                                  onPressed: _continueWithAnotherAccount,
                                ),
                              ] else ...[
                                const SizedBox(height: 20),
                                Container(
                                  padding: const EdgeInsets.all(16),
                                  decoration: BoxDecoration(
                                    color: AppColors.softPrimary,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(color: AppColors.border),
                                  ),
                                  child: Row(
                                    children: [
                                      const CircleAvatar(
                                        backgroundColor: AppColors.primary,
                                        foregroundColor: Colors.white,
                                        child: Icon(Icons.person_outline),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            if (_savedUserName case final name?)
                                              Text(
                                                name,
                                                maxLines: 1,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.w800,
                                                ),
                                              ),
                                            Text(
                                              _formattedCpf(_savedCpf!),
                                              style: const TextStyle(
                                                color: AppColors.muted,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 16),
                                AppButton(
                                  label: 'Acessar',
                                  icon: Icons.login,
                                  loading: state.isLoading,
                                  onPressed: _accessSavedAccount,
                                ),
                                const SizedBox(height: 8),
                                OutlinedButton(
                                  onPressed: state.isLoading
                                      ? null
                                      : _accessAnotherAccount,
                                  child: const Text('Acessar com outra conta'),
                                ),
                              ],
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
