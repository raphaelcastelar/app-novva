import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final name =
        user?.name.trim().isNotEmpty == true ? user!.name.trim() : 'Olá';

    return AppScaffold(
      title: '',
      child: summary.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorState(
          message: 'Não foi possível carregar seu resumo.',
          onRetry: () => ref.invalidate(dashboardSummaryProvider),
        ),
        data: (data) => RefreshIndicator(
          onRefresh: () => ref.refresh(dashboardSummaryProvider.future),
          child: ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 130),
            children: [
              _Header(name: name),
              const SizedBox(height: 14),
              _RevenueCard(summary: data),
              const SizedBox(height: 12),
              if (data.nextObligation case final obligation?)
                _NextObligationCard(obligation: obligation)
              else
                const _EmptyObligationCard(),
              const SizedBox(height: 16),
              _Counters(summary: data),
              const SizedBox(height: 18),
              const _Actions(),
            ],
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const ProfileAvatar(
          radius: 25,
          backgroundColor: AppColors.softAccent,
          foregroundColor: AppColors.primary,
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context)
                      .textTheme
                      .titleLarge
                      ?.copyWith(fontWeight: FontWeight.w900)),
              const Text('Confira a situação atual da sua conta.',
                  style: TextStyle(color: AppColors.muted)),
            ],
          ),
        ),
      ],
    );
  }
}

class _RevenueCard extends StatelessWidget {
  const _RevenueCard({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: AppColors.premiumGradient,
        borderRadius: BorderRadius.circular(26),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Faturamento emitido neste mês',
              style: TextStyle(color: Colors.white70)),
          const SizedBox(height: 6),
          Text(AppFormatters.money(summary.monthRevenue),
              style: Theme.of(context)
                  .textTheme
                  .headlineMedium
                  ?.copyWith(color: Colors.white, fontWeight: FontWeight.w900)),
          const SizedBox(height: 6),
          Text(
            summary.orders == 1
                ? '1 nota emitida'
                : '${summary.orders} notas emitidas',
            style: const TextStyle(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}

class _NextObligationCard extends StatelessWidget {
  const _NextObligationCard({required this.obligation});
  final DashboardObligation obligation;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: () => context.go(RouteNames.obligations),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: const CircleAvatar(
          backgroundColor: AppColors.softPrimary,
          child: Icon(Icons.receipt_long_outlined, color: AppColors.primary),
        ),
        title: Text(obligation.name,
            style: const TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text(
          'Vencimento ${AppFormatters.date(obligation.dueDate)} • ${AppFormatters.money(obligation.amount)}',
        ),
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _EmptyObligationCard extends StatelessWidget {
  const _EmptyObligationCard();

  @override
  Widget build(BuildContext context) {
    return const AppCard(
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: CircleAvatar(
          backgroundColor: AppColors.softAccent,
          child: Icon(Icons.check_rounded, color: AppColors.success),
        ),
        title: Text('Nenhuma guia pendente',
            style: TextStyle(fontWeight: FontWeight.w900)),
        subtitle: Text('Quando houver uma nova guia, ela aparecerá aqui.'),
      ),
    );
  }
}

class _Counters extends StatelessWidget {
  const _Counters({required this.summary});
  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _CounterCard(
            label: 'Documentos',
            value: summary.pendingDocuments,
            icon: Icons.folder_copy_outlined,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _CounterCard(
            label: 'Guias',
            value: summary.dueObligations,
            icon: Icons.receipt_long_outlined,
          ),
        ),
      ],
    );
  }
}

class _CounterCard extends StatelessWidget {
  const _CounterCard(
      {required this.label, required this.value, required this.icon});
  final String label;
  final int value;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary),
          const SizedBox(height: 12),
          Text('$value',
              style:
                  const TextStyle(fontSize: 25, fontWeight: FontWeight.w900)),
          Text(label, style: const TextStyle(color: AppColors.muted)),
        ],
      ),
    );
  }
}

class _Actions extends StatelessWidget {
  const _Actions();

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Acesso rápido',
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900)),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: FilledButton.icon(
                onPressed: () => context.go(RouteNames.invoices),
                icon: const Icon(Icons.add_rounded),
                label: const Text('Solicitar nota'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => context.go(RouteNames.documents),
                icon: const Icon(Icons.folder_outlined),
                label: const Text('Documentos'),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
