import 'package:flutter_riverpod/flutter_riverpod.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.pendingDocuments,
    required this.openIssues,
    required this.dueObligations,
    required this.pendingPayments,
    required this.monthRevenue,
  });

  final int pendingDocuments;
  final int openIssues;
  final int dueObligations;
  final int pendingPayments;
  final double monthRevenue;
}

final dashboardSummaryProvider = Provider(
  (_) => const DashboardSummary(
    pendingDocuments: 3,
    openIssues: 2,
    dueObligations: 4,
    pendingPayments: 1,
    monthRevenue: 48250,
  ),
);
