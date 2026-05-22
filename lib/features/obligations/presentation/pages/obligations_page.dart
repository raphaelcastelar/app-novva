import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/obligation.dart';
import '../providers/obligations_providers.dart';

class ObligationsPage extends ConsumerWidget {
  const ObligationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligations = ref.watch(obligationsProvider);
    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        title: 'Guias',
        child: Column(
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: _DasHeroCard(),
            ),
            const TabBar(
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              tabs: [
                Tab(text: 'Em aberto'),
                Tab(text: 'Pagas'),
                Tab(text: 'Vencidas'),
                Tab(text: 'Todas'),
              ],
            ),
            Expanded(
              child: TabBarView(
                children: [
                  _ObligationList(
                    obligations: obligations
                        .where((item) =>
                            item.status == ObligationStatus.open ||
                            item.status == ObligationStatus.dueSoon)
                        .toList(),
                  ),
                  _ObligationList(
                    obligations: obligations
                        .where((item) => item.status == ObligationStatus.paid)
                        .toList(),
                  ),
                  _ObligationList(
                    obligations: obligations
                        .where(
                            (item) => item.status == ObligationStatus.overdue)
                        .toList(),
                  ),
                  _ObligationList(obligations: obligations),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DasHeroCard extends StatelessWidget {
  const _DasHeroCard();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColors.softAccent,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(Icons.receipt_long_outlined,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DAS Simples Nacional',
                      style:
                          TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'A guia mensal que reúne os impostos da sua empresa.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.primaryDark,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Maio/2026',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    StatusBadge('A vencer', color: AppColors.warning),
                  ],
                ),
                const SizedBox(height: 6),
                const Text(
                  'Vence em 20/05/2026',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 10),
                Text(
                  'R\$ 1.680,30',
                  style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    FilledButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.download_outlined, size: 18),
                      label: const Text('Baixar PDF'),
                    ),
                    OutlinedButton.icon(
                      onPressed: () {},
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Gerar nova guia'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(color: Colors.white24),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ObligationList extends StatelessWidget {
  const _ObligationList({required this.obligations});

  final List<Obligation> obligations;

  @override
  Widget build(BuildContext context) {
    if (obligations.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Nenhuma guia nesta categoria.'),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.all(16),
      itemCount: obligations.length + 1,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        if (index == 0) {
          return const InsightCard(
            title: 'Histórico por ano',
            description:
                'Em breve: acordeão por ano e busca por mês de referência.',
            icon: Icons.calendar_month_outlined,
          );
        }
        return _ObligationCard(item: obligations[index - 1]);
      },
    );
  }
}

class _ObligationCard extends StatelessWidget {
  const _ObligationCard({required this.item});

  final Obligation item;

  @override
  Widget build(BuildContext context) {
    final color = _color(item.status);
    return AppCard(
      onTap: () => context.go(RouteNames.obligationDetails),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(Icons.receipt_outlined, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Mês de referência: maio/2026',
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusBadge(_label(item.status), color: color),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _InfoPill(
                  label: 'Vencimento',
                  value: AppFormatters.date(item.dueDate),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _InfoPill(
                  label: 'Valor',
                  value: AppFormatters.money(item.amount),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _SmallAction(
                  icon: Icons.download_outlined, label: 'PDF', onTap: () {}),
              if (item.paymentCode != null)
                _SmallAction(
                  icon: Icons.copy_outlined,
                  label: 'Copiar código',
                  onTap: () {
                    Clipboard.setData(ClipboardData(text: item.paymentCode!));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Código copiado.')),
                    );
                  },
                ),
              _SmallAction(
                icon: Icons.share_outlined,
                label: 'Compartilhar',
                onTap: () {},
              ),
              _SmallAction(
                icon: Icons.upload_file_outlined,
                label: 'Comprovante',
                onTap: () => context.go(RouteNames.documentUpload),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static String _label(ObligationStatus status) => switch (status) {
        ObligationStatus.open => 'Em aberto',
        ObligationStatus.dueSoon => 'A vencer',
        ObligationStatus.overdue => 'Vencido',
        ObligationStatus.paid => 'Pago',
        ObligationStatus.canceled => 'Cancelado',
      };

  static Color _color(ObligationStatus status) => switch (status) {
        ObligationStatus.open => AppColors.primary,
        ObligationStatus.dueSoon => AppColors.warning,
        ObligationStatus.overdue => AppColors.danger,
        ObligationStatus.paid => AppColors.success,
        ObligationStatus.canceled => AppColors.muted,
      };
}

class _InfoPill extends StatelessWidget {
  const _InfoPill({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(color: AppColors.muted, fontSize: 11)),
          const SizedBox(height: 2),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class _SmallAction extends StatelessWidget {
  const _SmallAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: onTap,
      icon: Icon(icon, size: 18),
      label: Text(label),
    );
  }
}
