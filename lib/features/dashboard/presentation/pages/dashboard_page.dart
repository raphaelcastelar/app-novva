import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final name = user?.name.trim().isNotEmpty == true
        ? user!.name.trim()
        : 'Dra. Marina';

    return AppScaffold(
      title: '',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _DashboardHeader(summary: summary, userName: name),
          const SizedBox(height: 16),
          _HealthCard(summary: summary),
          const SizedBox(height: 16),
          _SectionTitle(
            title: 'Faturamento do mês',
            action: 'Ver relatório',
            onPressed: () => context.go(RouteNames.reports),
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 164,
            child: Row(
              children: [
                Expanded(
                  child: MetricCard(
                    title: 'Faturado',
                    value: AppFormatters.money(summary.monthRevenue),
                    subtitle: '${summary.orders} notas emitidas',
                    variation: '+${summary.revenueGrowth.toStringAsFixed(1)}%',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    title: 'Ticket médio',
                    value: AppFormatters.money(summary.averageTicket),
                    subtitle: 'Por nota fiscal',
                    icon: Icons.payments_outlined,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          _CurrentDasCard(),
          const SizedBox(height: 16),
          _SectionTitle(
            title: 'Pendências',
            action: 'Resolver',
            onPressed: () => context.go(RouteNames.documents),
          ),
          const SizedBox(height: 10),
          _PendingList(),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Atalhos rápidos'),
          const SizedBox(height: 10),
          _ShortcutGrid(),
          const SizedBox(height: 18),
          const _SectionTitle(title: 'Explicado para você'),
          const SizedBox(height: 10),
          const _LearningList(),
        ],
      ),
    );
  }
}

class _DashboardHeader extends StatelessWidget {
  const _DashboardHeader({required this.summary, required this.userName});

  final DashboardSummary summary;
  final String userName;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppCard(
      padding: EdgeInsets.zero,
      radius: 28,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: AppColors.premiumGradient,
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 24,
                    backgroundColor: AppColors.accent,
                    backgroundImage: const NetworkImage(
                      'https://images.unsplash.com/photo-1494790108377-be9c29b29330?auto=format&fit=crop&w=160&q=80',
                    ),
                    onBackgroundImageError: (_, __) {},
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          userName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Veja sua situação contábil de maio',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: Colors.white.withValues(alpha: 0.76),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filledTonal(
                    tooltip: 'Notificações',
                    onPressed: () => context.go(RouteNames.notifications),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white.withValues(alpha: 0.14),
                      foregroundColor: Colors.white,
                    ),
                    icon: const Icon(Icons.notifications_outlined, size: 20),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              _RevenueChartCard(summary: summary),
              const SizedBox(height: 14),
              _PerformanceStrip(summary: summary),
            ],
          ),
        ),
      ),
    );
  }
}

class _RevenueChartCard extends StatelessWidget {
  const _RevenueChartCard({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.24)),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -46,
            bottom: -76,
            child: IgnorePointer(
              child: Opacity(
                opacity: 0.11,
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 220,
                  alignment: Alignment.bottomCenter,
                ),
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'Faturamento',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: AppColors.muted,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.arrow_upward_rounded,
                          color: AppColors.success,
                          size: 14,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '+${summary.revenueGrowth.toStringAsFixed(1)}%',
                          style: const TextStyle(
                            color: AppColors.success,
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                AppFormatters.money(summary.monthRevenue),
                style: theme.textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 2),
              const Text(
                'Últimos 7 dias vs mês anterior',
                style: TextStyle(color: AppColors.muted, fontSize: 12),
              ),
              const SizedBox(height: 18),
              SizedBox(
                height: 178,
                width: double.infinity,
                child: _RevenueChart(points: summary.revenueSeries),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PerformanceStrip extends StatelessWidget {
  const _PerformanceStrip({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const _MiniPerformance(
          label: 'Fechamento',
          value: '78%',
          color: Color(0xFFF6C453),
          icon: Icons.task_alt_outlined,
        ),
        const SizedBox(width: 10),
        _MiniPerformance(
          label: 'Pendências',
          value: '${summary.pendingDocuments}',
          color: AppColors.warning,
          icon: Icons.folder_copy_outlined,
        ),
        const SizedBox(width: 10),
        const _MiniPerformance(
          label: 'Saúde fiscal',
          value: '92',
          color: AppColors.accent,
          icon: Icons.speed_outlined,
        ),
      ],
    );
  }
}

class _MiniPerformance extends StatelessWidget {
  const _MiniPerformance({
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String label;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        ),
        child: Row(
          children: [
            Icon(icon, color: color, size: 19),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w900,
                      fontSize: 16,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    label,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.68),
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _RevenueChart extends StatelessWidget {
  const _RevenueChart({required this.points});

  final List<RevenuePoint> points;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RevenueChartPainter(points),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final point in points)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.only(top: 150),
                child: Text(
                  point.label,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _RevenueChartPainter extends CustomPainter {
  const _RevenueChartPainter(this.points);

  final List<RevenuePoint> points;

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    const chartTop = 8.0;
    const chartBottom = 34.0;
    final chartHeight = size.height - chartTop - chartBottom;
    final maxValue = points.map((point) => point.value).reduce(
          (value, element) => value > element ? value : element,
        );
    final minValue = points.map((point) => point.value).reduce(
          (value, element) => value < element ? value : element,
        );
    final range = (maxValue - minValue).abs() < 1 ? 1 : maxValue - minValue;
    final stepX = points.length == 1 ? 0.0 : size.width / (points.length - 1);

    final gridPaint = Paint()
      ..color = AppColors.border.withValues(alpha: 0.72)
      ..strokeWidth = 1;
    for (var i = 0; i < 4; i++) {
      final y = chartTop + (chartHeight / 3) * i;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final offsets = <Offset>[];
    for (var i = 0; i < points.length; i++) {
      final normalized = (points[i].value - minValue) / range;
      final x = points.length == 1 ? size.width / 2 : stepX * i;
      final y = chartTop + chartHeight - (normalized * chartHeight);
      offsets.add(Offset(x, y));
    }

    final areaPath = Path()
      ..moveTo(offsets.first.dx, size.height - chartBottom)
      ..lineTo(offsets.first.dx, offsets.first.dy);
    final linePath = Path()..moveTo(offsets.first.dx, offsets.first.dy);
    for (var i = 1; i < offsets.length; i++) {
      final previous = offsets[i - 1];
      final current = offsets[i];
      final controlX = previous.dx + (current.dx - previous.dx) / 2;
      areaPath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
      linePath.cubicTo(
        controlX,
        previous.dy,
        controlX,
        current.dy,
        current.dx,
        current.dy,
      );
    }
    areaPath
      ..lineTo(offsets.last.dx, size.height - chartBottom)
      ..close();

    final areaPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0x332F9E8F), Color(0x002F9E8F)],
      ).createShader(Rect.fromLTWH(0, chartTop, size.width, chartHeight));
    canvas.drawPath(areaPath, areaPaint);

    final linePaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(linePath, linePaint);

    final dotPaint = Paint()..color = Colors.white;
    final dotBorderPaint = Paint()
      ..color = AppColors.accent
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    for (final point in offsets) {
      canvas.drawCircle(point, 4.5, dotPaint);
      canvas.drawCircle(point, 4.5, dotBorderPaint);
    }
  }

  @override
  bool shouldRepaint(covariant _RevenueChartPainter oldDelegate) {
    return oldDelegate.points != points;
  }
}

class _HealthCard extends StatelessWidget {
  const _HealthCard({required this.summary});

  final DashboardSummary summary;

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
                child: const Icon(Icons.health_and_safety_outlined,
                    color: AppColors.accent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Saúde Contábil',
                      style: TextStyle(
                        color: AppColors.text,
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Sua empresa está regular, com atenção em 2 itens.',
                      style: TextStyle(color: AppColors.muted, height: 1.35),
                    ),
                  ],
                ),
              ),
              const StatusBadge('Regular', color: AppColors.success),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: const LinearProgressIndicator(
              value: 0.92,
              minHeight: 10,
              backgroundColor: AppColors.softPrimary,
              valueColor: AlwaysStoppedAnimation<Color>(AppColors.accent),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              const Text(
                '92% em dia',
                style: TextStyle(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const Spacer(),
              TextButton(
                onPressed: () => context.go(RouteNames.documents),
                child: Text('${summary.pendingDocuments} pendências'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CurrentDasCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: const [
              Expanded(
                child: Text(
                  'Próxima obrigação',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
              ),
              StatusBadge('A vencer', color: AppColors.warning),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'DAS Simples Nacional',
            style: TextStyle(
              color: AppColors.text,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Mês de referência: maio/2026 • Vencimento: 20/05/2026',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 10),
          Text(
            'R\$ 1.680,30',
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppColors.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _MiniAction(
                icon: Icons.download_outlined,
                label: 'Baixar',
                onTap: () {},
              ),
              _MiniAction(
                icon: Icons.copy_outlined,
                label: 'Copiar código',
                onTap: () {},
              ),
              _MiniAction(
                icon: Icons.upload_file_outlined,
                label: 'Comprovante',
                onTap: () => context.go(RouteNames.documentUpload),
              ),
              _MiniAction(
                icon: Icons.refresh_rounded,
                label: 'Nova guia',
                onTap: () => context.go(RouteNames.chat),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    const items = [
      ('Enviar notas do mês', 'Precisamos conferir seu faturamento.', 'Hoje'),
      (
        'Enviar comprovante do DAS',
        'Anexe o recibo para fecharmos maio.',
        '20 mai'
      ),
      (
        'Confirmar faturamento',
        'Valide os valores antes do relatório.',
        '31 mai'
      ),
    ];
    return Column(
      children: [
        for (final item in items) ...[
          AppCard(
            onTap: () => context.go(RouteNames.documents),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(Icons.task_alt_outlined,
                      color: AppColors.warning),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.$1,
                        style: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        item.$2,
                        style: const TextStyle(color: AppColors.muted),
                      ),
                    ],
                  ),
                ),
                StatusBadge(item.$3, color: AppColors.warning),
              ],
            ),
          ),
          if (item != items.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _ShortcutGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final items = [
      ('Solicitar DAS', Icons.receipt_long_outlined, RouteNames.obligations),
      ('Emitir NFS-e', Icons.note_add_outlined, RouteNames.invoices),
      ('Solicitar documento', Icons.description_outlined, RouteNames.documents),
      ('Falar com contador', Icons.support_agent_outlined, RouteNames.chat),
      ('Ver faturamento', Icons.bar_chart_outlined, RouteNames.reports),
      ('Gerenciar CNPJs', Icons.business_outlined, RouteNames.cnpjs),
      ('Imposto de Renda', Icons.assignment_ind_outlined, RouteNames.reports),
      ('Regularidade fiscal', Icons.verified_outlined, RouteNames.documents),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 720 ? 4 : 2;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: columns == 4 ? 1.16 : 1.05,
          ),
          itemBuilder: (_, index) {
            final item = items[index];
            return ActionTile(
              title: item.$1,
              icon: item.$2,
              onTap: () => context.go(item.$3),
            );
          },
        );
      },
    );
  }
}

class _LearningList extends StatelessWidget {
  const _LearningList();

  @override
  Widget build(BuildContext context) {
    const items = [
      (
        'O que é DAS?',
        'A guia mensal que reúne os impostos da sua empresa médica.',
        Icons.school_outlined,
      ),
      (
        'Quando emitir nota?',
        'Entenda como registrar plantões e serviços prestados sem burocracia.',
        Icons.lightbulb_outline,
      ),
      (
        'Pró-labore e lucros',
        'Veja a diferença entre remuneração e distribuição de lucros.',
        Icons.account_balance_wallet_outlined,
      ),
    ];
    return Column(
      children: [
        for (final item in items) ...[
          InsightCard(title: item.$1, description: item.$2, icon: item.$3),
          if (item != items.last) const SizedBox(height: 10),
        ],
      ],
    );
  }
}

class _MiniAction extends StatelessWidget {
  const _MiniAction({
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title, this.action, this.onPressed});

  final String title;
  final String? action;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: AppColors.text,
                  fontWeight: FontWeight.w900,
                ),
          ),
        ),
        if (action != null)
          TextButton(onPressed: onPressed, child: Text(action!)),
      ],
    );
  }
}
