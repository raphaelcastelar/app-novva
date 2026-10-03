import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.pendingDocuments,
    required this.dueObligations,
    required this.monthRevenue,
    required this.orders,
    this.nextObligation,
  });

  final int pendingDocuments;
  final int dueObligations;
  final double monthRevenue;
  final int orders;
  final DashboardObligation? nextObligation;

  factory DashboardSummary.fromJson(Map<String, dynamic> json) {
    final next = json['nextObligation'];
    return DashboardSummary(
      pendingDocuments: (json['pendingDocuments'] as num?)?.toInt() ?? 0,
      dueObligations: (json['dueObligations'] as num?)?.toInt() ?? 0,
      monthRevenue: (json['monthRevenue'] as num?)?.toDouble() ?? 0,
      orders: (json['orders'] as num?)?.toInt() ?? 0,
      nextObligation: next is Map<String, dynamic>
          ? DashboardObligation.fromJson(next)
          : null,
    );
  }
}

class DashboardObligation {
  const DashboardObligation({
    required this.name,
    required this.dueDate,
    required this.amount,
  });

  final String name;
  final DateTime dueDate;
  final double amount;

  factory DashboardObligation.fromJson(Map<String, dynamic> json) {
    return DashboardObligation(
      name: json['name'] as String? ?? 'Obrigação',
      dueDate: DateTime.parse(json['dueDate'] as String),
      amount: (json['amount'] as num?)?.toDouble() ?? 0,
    );
  }
}

final dashboardDioProvider = Provider<Dio>(
  (ref) => DioClient(ref.watch(tokenManagerProvider)).dio,
);

final dashboardSummaryProvider = FutureProvider.autoDispose<DashboardSummary>(
  (ref) async {
    final response = await ref
        .watch(dashboardDioProvider)
        .get<Map<String, dynamic>>('dashboard/summary');
    return DashboardSummary.fromJson(response.data!);
  },
);
