import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return AppScaffold(
      title: 'Relatórios',
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Row(
            children: [
              Expanded(
                  child: AppCard(
                      child: _ReportMetric(
                          label: 'Faturamento', value: 'R\$ 48.250'))),
              SizedBox(width: 10),
              Expanded(
                  child: AppCard(
                      child: _ReportMetric(
                          label: 'Lucro estimado', value: 'R\$ 31.900'))),
            ],
          ),
          const SizedBox(height: 12),
          AppCard(
            child: SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  borderData: FlBorderData(show: false),
                  gridData: const FlGridData(show: false),
                  titlesData: const FlTitlesData(
                      leftTitles: AxisTitles(),
                      topTitles: AxisTitles(),
                      rightTitles: AxisTitles()),
                  barGroups: [
                    BarChartGroupData(x: 1, barRods: [
                      BarChartRodData(toY: 32, color: AppColors.primary)
                    ]),
                    BarChartGroupData(x: 2, barRods: [
                      BarChartRodData(toY: 37, color: AppColors.primary)
                    ]),
                    BarChartGroupData(x: 3, barRods: [
                      BarChartRodData(toY: 48, color: AppColors.accent)
                    ]),
                    BarChartGroupData(x: 4, barRods: [
                      BarChartRodData(toY: 41, color: AppColors.primary)
                    ]),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          OutlinedButton.icon(
              onPressed: () {},
              icon: const Icon(Icons.picture_as_pdf_outlined),
              label: const Text('Exportar PDF')),
        ],
      ),
    );
  }
}

class _ReportMetric extends StatelessWidget {
  const _ReportMetric({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label),
      Text(value, style: Theme.of(context).textTheme.titleMedium)
    ]);
  }
}
