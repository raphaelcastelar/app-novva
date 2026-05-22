import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.pendingDocuments,
    required this.openIssues,
    required this.dueObligations,
    required this.pendingPayments,
    required this.monthRevenue,
    required this.orders,
    required this.averageTicket,
    required this.activeClients,
    required this.revenueGrowth,
    required this.revenueSeries,
  });

  final int pendingDocuments;
  final int openIssues;
  final int dueObligations;
  final int pendingPayments;
  final double monthRevenue;
  final int orders;
  final double averageTicket;
  final int activeClients;
  final double revenueGrowth;
  final List<RevenuePoint> revenueSeries;
}

class RevenuePoint {
  const RevenuePoint({
    required this.label,
    required this.value,
  });

  final String label;
  final double value;
}

final dashboardSummaryProvider = Provider(
  (_) => const DashboardSummary(
    pendingDocuments: 3,
    openIssues: 2,
    dueObligations: 4,
    pendingPayments: 1,
    monthRevenue: 48920,
    orders: 186,
    averageTicket: 263,
    activeClients: 74,
    revenueGrowth: 12.4,
    revenueSeries: [
      RevenuePoint(label: 'Seg', value: 5200),
      RevenuePoint(label: 'Ter', value: 6100),
      RevenuePoint(label: 'Qua', value: 5750),
      RevenuePoint(label: 'Qui', value: 7350),
      RevenuePoint(label: 'Sex', value: 6900),
      RevenuePoint(label: 'Sáb', value: 9050),
      RevenuePoint(label: 'Dom', value: 8570),
    ],
  ),
);
