import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/features/takers/domain/entities/taker.dart';

void main() {
  test('maps a taker returned by the API', () {
    final taker = Taker.fromJson(const {
      'id': 'taker-id',
      'name': 'Hospital Vida',
      'cnpj': '11222333000181',
      'municipality': 'Campos dos Goytacazes',
    });

    expect(taker.id, 'taker-id');
    expect(taker.name, 'Hospital Vida');
    expect(taker.cnpj, '11222333000181');
    expect(taker.municipality, 'Campos dos Goytacazes');
  });
}
