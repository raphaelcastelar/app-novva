import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/premium_components.dart';

class InvoiceRequestPage extends StatelessWidget {
  const InvoiceRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Nova NFS-e',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const _StepHeader(current: 1),
          const SizedBox(height: 14),
          AppCard(
            child: Column(
              children: const [
                AppTextField(
                  label: 'Empresa/CNPJ emissor',
                  initialValue: 'Clínica Marina Saúde - 12.345.678/0001-90',
                  readOnly: true,
                  suffixIcon: Icon(Icons.expand_more),
                ),
                SizedBox(height: 12),
                AppTextField(label: 'Município'),
                SizedBox(height: 12),
                AppTextField(label: 'Tomador/CNPJ'),
                SizedBox(height: 12),
                AppTextField(
                  label: 'Data',
                  readOnly: true,
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),
                SizedBox(height: 12),
                AppTextField(
                    label: 'Valor', keyboardType: TextInputType.number),
                SizedBox(height: 12),
                AppTextField(
                  label: 'Código de tributação',
                  initialValue: AppConstants.defaultTaxCode,
                  readOnly: true,
                ),
                SizedBox(height: 12),
                AppTextField(label: 'Serviço prestado'),
              ],
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
            onPressed: () => context.go(RouteNames.invoiceDescription),
          ),
        ],
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
