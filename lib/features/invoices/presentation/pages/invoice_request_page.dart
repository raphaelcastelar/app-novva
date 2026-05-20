import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';

class InvoiceRequestPage extends StatelessWidget {
  const InvoiceRequestPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Emitir NFs-e',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const AppTextField(label: 'Município'),
          const SizedBox(height: 10),
          const AppTextField(label: 'CNPJ do tomador'),
          const SizedBox(height: 10),
          const AppTextField(
              label: 'Valor', keyboardType: TextInputType.number),
          const SizedBox(height: 10),
          const AppTextField(
              label: 'Data',
              readOnly: true,
              suffixIcon: Icon(Icons.calendar_today_outlined)),
          const SizedBox(height: 10),
          const AppTextField(
              label: 'Código de tributação',
              initialValue: AppConstants.defaultTaxCode,
              readOnly: true),
          const SizedBox(height: 16),
          AppButton(
              label: 'Próximo',
              icon: Icons.arrow_forward,
              onPressed: () => context.go(RouteNames.invoiceDescription)),
        ],
      ),
    );
  }
}
