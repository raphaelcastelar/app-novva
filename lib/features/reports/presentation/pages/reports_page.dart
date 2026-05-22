import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/premium_components.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Relatórios',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Inteligência financeira',
            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Acompanhe faturamento, notas e estimativa de impostos com clareza.',
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 164,
            child: Row(
              children: const [
                Expanded(
                  child: MetricCard(
                    title: 'Faturamento do mês',
                    value: 'R\$ 48.920',
                    subtitle: '6 notas emitidas',
                    variation: '+18%',
                    icon: Icons.trending_up_rounded,
                    color: AppColors.success,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    title: 'Estimativa de imposto',
                    value: 'R\$ 4.120',
                    subtitle: 'Base atual',
                    icon: Icons.account_balance_outlined,
                    color: AppColors.warning,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            height: 164,
            child: Row(
              children: const [
                Expanded(
                  child: MetricCard(
                    title: 'Faturamento do ano',
                    value: 'R\$ 286.400',
                    subtitle: 'Média R\$ 47.733',
                    icon: Icons.calendar_month_outlined,
                    color: AppColors.primary,
                  ),
                ),
                SizedBox(width: 10),
                Expanded(
                  child: MetricCard(
                    title: 'Ticket médio',
                    value: 'R\$ 8.153',
                    subtitle: 'Por tomador',
                    icon: Icons.receipt_long_outlined,
                    color: AppColors.accent,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Faturamento por mês',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: BarChart(
                    BarChartData(
                      borderData: FlBorderData(show: false),
                      gridData: FlGridData(
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: AppColors.border,
                          strokeWidth: 1,
                        ),
                      ),
                      titlesData: const FlTitlesData(
                        leftTitles: AxisTitles(),
                        topTitles: AxisTitles(),
                        rightTitles: AxisTitles(),
                      ),
                      barGroups: [
                        _bar(1, 32, AppColors.primary),
                        _bar(2, 37, AppColors.primary),
                        _bar(3, 48, AppColors.accent),
                        _bar(4, 41, AppColors.primary),
                        _bar(5, 54, AppColors.accent),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          const InsightCard(
            title: 'Insight Novva',
            description:
                'Seu faturamento subiu 18% em relação ao mês anterior. O maior tomador foi Hospital Exemplo.',
            icon: Icons.auto_awesome_outlined,
          ),
          const SizedBox(height: 10),
          const InsightCard(
            title: 'Alerta preventivo',
            description:
                'Seu faturamento anual está saudável. Se continuar crescendo, revise o regime tributário no segundo semestre.',
            icon: Icons.notification_important_outlined,
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Exportar PDF'),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _bar(int x, double y, Color color) {
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          width: 18,
          borderRadius: BorderRadius.circular(8),
          color: color,
        ),
      ],
    );
  }
}
