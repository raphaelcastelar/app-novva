import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/errors/error_handler.dart';
import '../providers/auth_providers.dart';
import '../widgets/auth_page_shell.dart';

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
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      });
    });

    return AuthPageShell(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
        child: _loadingSavedAccount
            ? const Center(
                child: CircularProgressIndicator(color: authAccent),
              )
            : Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    if (_showCpfForm)
                      _CpfForm(
                        controller: _cpfController,
                        loading: state.isLoading,
                        onContinue: _continueWithAnotherAccount,
                      )
                    else
                      _SavedAccount(
                        name: _savedUserName ?? 'Usuário Novva',
                        cpf: _formattedCpf(_savedCpf!),
                        loading: state.isLoading,
                        onContinue: _accessSavedAccount,
                        onChangeAccount: _accessAnotherAccount,
                      ),
                    const Spacer(),
                    const AuthHelpFooter(),
                  ],
                ),
              ),
      ),
    );
  }
}

class _CpfForm extends StatelessWidget {
  const _CpfForm({
    required this.controller,
    required this.loading,
    required this.onContinue,
  });

  final TextEditingController controller;
  final bool loading;
  final VoidCallback onContinue;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        AuthTextField(
          label: 'CPF',
          controller: controller,
          hintText: '000.000.000-00',
          keyboardType: TextInputType.number,
          inputFormatters: [
            FilteringTextInputFormatter.digitsOnly,
            const _CpfInputFormatter(),
          ],
          validator: (value) =>
              (value ?? '').replaceAll(RegExp(r'\D'), '').length == 11
                  ? null
                  : 'Digite 11 números.',
          onFieldSubmitted: (_) => onContinue(),
        ),
        const SizedBox(height: 12),
        AuthPrimaryButton(
          label: 'Continuar',
          loading: loading,
          onPressed: onContinue,
        ),
      ],
    );
  }
}

class _SavedAccount extends StatelessWidget {
  const _SavedAccount({
    required this.name,
    required this.cpf,
    required this.loading,
    required this.onContinue,
    required this.onChangeAccount,
  });

  final String name;
  final String cpf;
  final bool loading;
  final VoidCallback onContinue;
  final VoidCallback onChangeAccount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Text(
          'Continuar como',
          style: TextStyle(color: Color(0xFFC1CED4), fontSize: 12),
        ),
        const SizedBox(height: 7),
        Container(
          height: 62,
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: authSurface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: authAccent),
          ),
          child: Row(
            children: [
              const CircleAvatar(
                radius: 19,
                backgroundColor: Color(0xFF143542),
                foregroundColor: Color(0xFFB7D0DA),
                child: Icon(Icons.person_outline, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      'CPF: $cpf',
                      style: const TextStyle(color: authMuted, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const CircleAvatar(
                radius: 11,
                backgroundColor: authAccent,
                foregroundColor: Color(0xFF063140),
                child: Icon(Icons.check, size: 15),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        AuthPrimaryButton(
          label: 'Continuar',
          loading: loading,
          onPressed: onContinue,
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 50,
          child: OutlinedButton.icon(
            onPressed: loading ? null : onChangeAccount,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.white,
              side: const BorderSide(color: authBorder),
              shape: const StadiumBorder(),
            ),
            icon: const Icon(Icons.swap_horiz, color: authAccent, size: 20),
            label: const Text(
              'Alterar conta',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ),
      ],
    );
  }
}

class _CpfInputFormatter extends TextInputFormatter {
  const _CpfInputFormatter();

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final digits = newValue.text.replaceAll(RegExp(r'\D'), '');
    final limited = digits.length > 11 ? digits.substring(0, 11) : digits;
    final buffer = StringBuffer();
    for (var index = 0; index < limited.length; index++) {
      if (index == 3 || index == 6) buffer.write('.');
      if (index == 9) buffer.write('-');
      buffer.write(limited[index]);
    }
    final text = buffer.toString();
    return TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }
}
