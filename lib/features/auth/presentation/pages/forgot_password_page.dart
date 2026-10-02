import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../providers/auth_providers.dart';

class ForgotPasswordPage extends ConsumerStatefulWidget {
  const ForgotPasswordPage({this.initialCpf = '', super.key});

  final String initialCpf;

  @override
  ConsumerState<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends ConsumerState<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _cpf;
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    _cpf = TextEditingController(text: widget.initialCpf);
  }

  @override
  void dispose() {
    _cpf.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _isSubmitting) return;
    final cpf = _cpf.text.replaceAll(RegExp(r'\D'), '');
    setState(() => _isSubmitting = true);

    try {
      await ref.read(authRepositoryProvider).requestPasswordReset(cpf);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) => AlertDialog(
          icon: const Icon(Icons.mark_email_read_outlined),
          title: const Text('Verifique seu e-mail'),
          content: const Text(
            'Se o CPF estiver cadastrado, você receberá um link para criar uma nova senha. O link é válido por 30 minutos.',
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('Voltar para entrar'),
            ),
          ],
        ),
      );
      if (mounted) context.go('${RouteNames.loginPassword}?cpf=$cpf');
    } catch (_) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
          'Não foi possível enviar as instruções agora. Tente novamente em instantes.',
        ),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar senha')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              const Text(
                'Informe seu CPF. Enviaremos um link seguro para o e-mail cadastrado, caso a conta esteja ativa.',
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'CPF',
                controller: _cpf,
                keyboardType: TextInputType.number,
                validator: (value) =>
                    (value ?? '').replaceAll(RegExp(r'\D'), '').length == 11
                        ? null
                        : 'Digite os 11 números do CPF.',
              ),
              const SizedBox(height: 20),
              AppButton(
                label: 'Enviar instruções',
                icon: Icons.send_outlined,
                loading: _isSubmitting,
                onPressed: _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
