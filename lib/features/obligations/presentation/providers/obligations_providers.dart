import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/obligation.dart';

final obligationsProvider = Provider<List<Obligation>>(
  (_) => [
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
  ],
);
