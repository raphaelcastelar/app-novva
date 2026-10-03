import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../domain/entities/obligation.dart';

final obligationsDioProvider = Provider<Dio>(
  (ref) => DioClient(ref.watch(tokenManagerProvider)).dio,
);

final obligationListProvider = FutureProvider.autoDispose<List<Obligation>>(
  (ref) async {
    final response = await ref
        .watch(obligationsDioProvider)
        .get<Map<String, dynamic>>('obligations?page=1&limit=100');
    final items = response.data?['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => _obligationFromJson(item as Map<String, dynamic>))
        .toList();
  },
);

final markObligationPaidProvider = Provider(
  (ref) => (String id) async {
    await ref.read(obligationsDioProvider).post<void>('obligations/$id/paid');
    ref.invalidate(obligationListProvider);
  },
);

Obligation _obligationFromJson(Map<String, dynamic> json) {
  return Obligation(
    id: json['id'] as String,
    name: json['name'] as String? ?? 'Guia',
    dueDate: DateTime.parse(json['dueDate'] as String),
    amount: (json['amount'] as num?)?.toDouble() ?? 0,
    status: switch (json['status']) {
      'DUE_SOON' => ObligationStatus.dueSoon,
      'OVERDUE' => ObligationStatus.overdue,
      'PAID' => ObligationStatus.paid,
      'CANCELED' => ObligationStatus.canceled,
      _ => ObligationStatus.open,
    },
    paymentCode: json['paymentCode'] as String?,
  );
}
