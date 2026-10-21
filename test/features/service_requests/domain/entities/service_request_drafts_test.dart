import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/features/service_requests/domain/entities/service_request_drafts.dart';

void main() {
  test('maps a saved invoice draft returned by the API', () {
    final draft = InvoiceRequestDraft.fromJson(const {
      'takerCnpj': '11222333000181',
      'takerName': 'Hospital Vida',
      'municipality': 'Campos dos Goytacazes',
      'serviceDate': '2026-10-21T00:00:00.000Z',
      'amount': 1250.50,
      'taxationCode': '04.01.01 Medicina',
      'description': 'Atendimento médico especializado.',
    });

    expect(draft.takerName, 'Hospital Vida');
    expect(draft.serviceDate, DateTime.utc(2026, 10, 21));
    expect(draft.amount, 1250.50);
    expect(draft.description, 'Atendimento médico especializado.');
  });
}
