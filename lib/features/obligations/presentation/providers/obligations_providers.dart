import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/obligation.dart';

final obligationListProvider =
    StateNotifierProvider<ObligationsNotifier, List<Obligation>>(
  (_) => ObligationsNotifier(),
);

class ObligationsNotifier extends StateNotifier<List<Obligation>> {
  ObligationsNotifier()
      : super([
          Obligation(
              id: 'das-2026-05',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 5, 20),
              amount: 1680.30,
              status: ObligationStatus.dueSoon,
              paymentCode: '85890000016 80300385262 60520126052 00123456789'),
          Obligation(
              id: 'inss-2026-05',
              name: 'INSS pró-labore',
              dueDate: DateTime(2026, 5, 25),
              amount: 642.10,
              status: ObligationStatus.open),
          Obligation(
              id: 'iss-2026-04',
              name: 'ISS',
              dueDate: DateTime(2026, 4, 20),
              amount: 910.00,
              status: ObligationStatus.paid),
          Obligation(
              id: 'das-2026-04',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 4, 20),
              amount: 1538.45,
              status: ObligationStatus.overdue,
              paymentCode: '85890000015 38450385262 60420126052 00123456788'),
          Obligation(
              id: 'das-2026-03',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 3, 20),
              amount: 1475.80,
              status: ObligationStatus.paid),
          Obligation(
              id: 'inss-2026-03',
              name: 'INSS pró-labore',
              dueDate: DateTime(2026, 3, 25),
              amount: 618.40,
              status: ObligationStatus.paid),
          Obligation(
              id: 'das-2026-02',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 2, 20),
              amount: 1398.22,
              status: ObligationStatus.paid),
          Obligation(
              id: 'das-2026-01',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 1, 20),
              amount: 1320.90,
              status: ObligationStatus.paid),
          Obligation(
              id: 'das-2026-06',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 6, 20),
              amount: 1712.64,
              status: ObligationStatus.open,
              paymentCode: '85890000017 12640385262 60620126052 00123456790'),
          Obligation(
              id: 'inss-2026-06',
              name: 'INSS pró-labore',
              dueDate: DateTime(2026, 6, 25),
              amount: 642.10,
              status: ObligationStatus.open),
          Obligation(
              id: 'das-2026-07',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 7, 20),
              amount: 1748.12,
              status: ObligationStatus.dueSoon,
              paymentCode: '85890000017 48120385262 60720126052 00123456791'),
          Obligation(
              id: 'das-2026-08',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 8, 20),
              amount: 1760.00,
              status: ObligationStatus.open),
          Obligation(
              id: 'das-2026-09',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 9, 20),
              amount: 1760.00,
              status: ObligationStatus.open),
          Obligation(
              id: 'das-2026-10',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 10, 20),
              amount: 1760.00,
              status: ObligationStatus.open),
          Obligation(
              id: 'das-2026-11',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 11, 20),
              amount: 1760.00,
              status: ObligationStatus.open),
          Obligation(
              id: 'das-2026-12',
              name: 'DAS Simples Nacional',
              dueDate: DateTime(2026, 12, 20),
              amount: 1760.00,
              status: ObligationStatus.open),
        ]);

  void markAsPaid(String id) {
    state = [
      for (final obligation in state)
        if (obligation.id == id)
          obligation.copyWith(status: ObligationStatus.paid)
        else
          obligation,
    ];
  }
}
