import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../service_requests/domain/entities/service_request_drafts.dart';
import '../../../service_requests/presentation/providers/service_request_providers.dart';

class InvoiceRequestPage extends ConsumerStatefulWidget {
  const InvoiceRequestPage({super.key});

  @override
  ConsumerState<InvoiceRequestPage> createState() => _InvoiceRequestPageState();
}

class _InvoiceRequestPageState extends ConsumerState<InvoiceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _municipality = TextEditingController();
  final _takerName = TextEditingController();
  final _takerCnpj = TextEditingController();
  final _date = TextEditingController(
    text: DateTime.now().toIso8601String().split('T').first,
  );
  final _amount = TextEditingController();
  final _service = TextEditingController(text: 'Serviços médicos');

  @override
  void dispose() {
    for (final controller in [
      _municipality,
      _takerName,
      _takerCnpj,
      _date,
      _amount,
      _service
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nova NFS-e',
      child: Stack(
        children: [
          const Positioned.fill(child: _InvoicesWatermark()),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _StepHeader(current: 1),
              const SizedBox(height: 14),
              AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      AppTextField(
                          label: 'Município',
                          controller: _municipality,
                          validator: _required),
                      const SizedBox(height: 12),
                      AppTextField(
                          label: 'Nome do tomador',
                          controller: _takerName,
                          validator: _required),
                      const SizedBox(height: 12),
                      AppTextField(
                          label: 'CNPJ do tomador',
                          controller: _takerCnpj,
                          keyboardType: TextInputType.number,
                          validator: _cnpj),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Data (AAAA-MM-DD)',
                        controller: _date,
                        validator: _required,
                        suffixIcon: const Icon(Icons.calendar_today_outlined),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                          label: 'Valor',
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: _required),
                      const SizedBox(height: 12),
                      const AppTextField(
                        label: 'Código de tributação',
                        initialValue: AppConstants.defaultTaxCode,
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                          label: 'Serviço prestado',
                          controller: _service,
                          validator: _required),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const InsightCard(
                title: 'Dica Novva',
                description:
                    'Use o nome do hospital ou clínica no tomador para facilitar seus relatórios de faturamento.',
                icon: Icons.lightbulb_outline,
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Continuar para descrição',
                icon: Icons.arrow_forward,
                onPressed: _continue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  String? _cnpj(String? value) {
    final digits = (value ?? '').replaceAll(RegExp(r'\D'), '');
    return digits.length == 14 ? null : 'Informe os 14 dígitos do CNPJ';
  }

  void _continue() {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount =
        double.tryParse(_amount.text.replaceAll('.', '').replaceAll(',', '.'));
    final date = DateTime.tryParse(_date.text);
    if (amount == null || amount <= 0 || date == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confira a data e o valor informados.')),
      );
      return;
    }
    ref.read(pendingInvoiceDraftProvider.notifier).state = InvoiceRequestDraft(
      takerCnpj: _takerCnpj.text,
      takerName: _takerName.text.trim(),
      municipality: _municipality.text.trim(),
      serviceDate: date,
      amount: amount,
      taxationCode: AppConstants.defaultTaxCode,
      description: _service.text.trim(),
    );
    context.go(RouteNames.invoiceDescription);
  }
}

class _InvoicesWatermark extends StatelessWidget {
  const _InvoicesWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(-0.68, 0.38),
        child: Opacity(
          opacity: 0.045,
          child: Transform.rotate(
            angle: 0.16,
            child: Image.asset(
              'assets/images/logo.png',
              width: MediaQuery.sizeOf(context).width * 1.1,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Etapa 1 de 4',
            style:
                TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          const Text(
            'Dados da nota',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          TimelineStatus(
            steps: const ['Dados', 'Descrição', 'Revisão', 'Status'],
            currentStep: current - 1,
          ),
        ],
      ),
    );
  }
}
