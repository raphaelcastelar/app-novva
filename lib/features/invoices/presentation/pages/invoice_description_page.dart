import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../core/widgets/status_badge.dart';

class InvoiceDescriptionPage extends StatelessWidget {
  const InvoiceDescriptionPage({super.key});

  @override
  Widget build(BuildContext context) {
    const suggestions = [
      'Serviços médicos prestados conforme contrato.',
      'Atendimento médico especializado.',
      'Plantão médico realizado no período de maio/2026.',
      'Serviços de saúde prestados à instituição contratante.',
    ];

    return AppScaffold(
      title: 'Descrição da NFS-e',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 122),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Etapa 2 de 4',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Descrição do serviço',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 14),
                TimelineStatus(
                  steps: ['Dados', 'Descrição', 'Revisão', 'Status'],
                  currentStep: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          const AppTextField(label: 'Descrição manual', maxLines: 6),
          const SizedBox(height: 16),
          const Text(
            'Sugestões inteligentes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final suggestion in suggestions) ...[
            AppCard(
              onTap: () {},
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_outlined,
                      color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(child: Text(suggestion)),
                  IconButton(
                    tooltip: 'Favoritar descrição',
                    onPressed: () {},
                    icon: const Icon(Icons.star_border_rounded),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          const _ReviewCard(),
          const SizedBox(height: 18),
          AppButton(
            label: 'Confirmar solicitação',
            icon: Icons.send_outlined,
            onPressed: () => _showSuccess(context),
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.drafts_outlined),
            label: const Text('Salvar rascunho'),
          ),
        ],
      ),
    );
  }

  void _showSuccess(BuildContext context) {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge('Solicitação enviada',
                    color: AppColors.success),
                const SizedBox(height: 12),
                const Text(
                  'Sua NFS-e foi enviada para a contabilidade.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Você poderá acompanhar o andamento e baixar a nota quando ela estiver disponível.',
                  style: TextStyle(color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 18),
                const _CompactSuccessTimeline(),
                const SizedBox(height: 18),
                AppButton(
                  label: 'Voltar ao início',
                  onPressed: () {
                    Navigator.of(context).pop();
                    pageContext.go(RouteNames.dashboard);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactSuccessTimeline extends StatelessWidget {
  const _CompactSuccessTimeline();

  static const _steps = ['Solicitada', 'Em análise', 'Emitida', 'Enviada'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stepWidth = constraints.maxWidth / _steps.length;
          return Stack(
            children: [
              Positioned(
                top: 12,
                left: stepWidth / 2,
                right: stepWidth / 2,
                child: Container(
                  height: 2,
                  color: AppColors.border,
                ),
              ),
              Positioned(
                top: 12,
                left: stepWidth / 2,
                right: constraints.maxWidth - stepWidth / 2,
                child: Container(
                  height: 2,
                  color: AppColors.accent,
                ),
              ),
              Row(
                children: [
                  for (var index = 0; index < _steps.length; index++)
                    SizedBox(
                      width: stepWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? AppColors.accent
                                  : AppColors.border,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              index == 0 ? Icons.check : Icons.circle,
                              color: Colors.white,
                              size: index == 0 ? 14 : 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _steps[index],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard();

  @override
  Widget build(BuildContext context) {
    const rows = [
      ('CNPJ emissor', 'Clínica Marina Saúde'),
      ('Município', 'São Paulo'),
      ('Tomador', 'Hospital Exemplo'),
      ('Valor', 'R\$ 8.500,00'),
      ('Tributação', '04.01.01 Medicina'),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Revisão rápida',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final row in rows) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.$1,
                    style: const TextStyle(color: AppColors.muted),
                  ),
                ),
                Flexible(
                  child: Text(
                    row.$2,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (row != rows.last) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}
