import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../providers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final shortcuts = [
      _Shortcut(
        'Pendências',
        Icons.warning_amber_outlined,
        RouteNames.documents,
        '${summary.pendingDocuments} docs',
      ),
      const _Shortcut(
        'Documentos',
        Icons.description_outlined,
        RouteNames.documents,
        'Enviar',
      ),
      _Shortcut(
        'Guias',
        Icons.receipt_long_outlined,
        RouteNames.obligations,
        '${summary.dueObligations} a vencer',
      ),
      const _Shortcut(
        'Declarações',
        Icons.assignment_outlined,
        RouteNames.reports,
        'IRPF',
      ),
      _Shortcut(
        'Mensagens',
        Icons.forum_outlined,
        RouteNames.chat,
        '${summary.openIssues} abertas',
      ),
      const _Shortcut(
        'Relatórios',
        Icons.bar_chart_outlined,
        RouteNames.reports,
        'Ver',
      ),
      const _Shortcut(
        'Meu contador',
        Icons.support_agent_outlined,
        RouteNames.chat,
        'Online',
      ),
      const _Shortcut(
        'NFs-e',
        Icons.note_add_outlined,
        RouteNames.invoices,
        'Solicitar',
      ),
    ];

    return AppScaffold(
      title: 'Olá, Dra. Marina',
      actions: [
        IconButton(
            onPressed: () => context.go(RouteNames.notifications),
            icon: const Icon(Icons.notifications_outlined)),
      ],
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Situação contábil',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                const LinearProgressIndicator(value: 0.78, minHeight: 8),
                const SizedBox(height: 10),
                Text('Cadastro regular, com documentos pendentes para maio.',
                    style: Theme.of(context).textTheme.bodyMedium),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _Metric(
                      label: 'Faturamento',
                      value: AppFormatters.money(summary.monthRevenue),
                      color: AppColors.primary)),
              const SizedBox(width: 10),
              Expanded(
                  child: _Metric(
                      label: 'Pagamentos',
                      value: '${summary.pendingPayments}',
                      color: AppColors.warning)),
            ],
          ),
          const SizedBox(height: 16),
          Text('Atalhos', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 10),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: shortcuts.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 1.28,
            ),
            itemBuilder: (_, index) {
              final item = shortcuts[index];
              return AppCard(
                onTap: () => context.go(item.route),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(item.icon, color: AppColors.primary),
                    const Spacer(),
                    Text(item.title,
                        style: const TextStyle(fontWeight: FontWeight.w600)),
                    Text(item.subtitle,
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  const _Metric(
      {required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(color: AppColors.muted)),
          const SizedBox(height: 6),
          Text(value,
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(color: color)),
        ],
      ),
    );
  }
}

class _Shortcut {
  const _Shortcut(this.title, this.icon, this.route, this.subtitle);
  final String title;
  final IconData icon;
  final String route;
  final String subtitle;
}
