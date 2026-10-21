import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/core/utils/validators.dart';

void main() {
  group('Validators', () {
    test('accepts valid CPF', () {
      expect(Validators.isValidCpf('12831146747'), isTrue);
    });

    test('rejects invalid CPF', () {
      expect(Validators.isValidCpf('11111111111'), isFalse);
      expect(Validators.isValidCpf('123'), isFalse);
    });

    test('accepts valid CNPJ with or without formatting', () {
      expect(Validators.isValidCnpj('11.222.333/0001-81'), isTrue);
      expect(Validators.isValidCnpj('11222333000181'), isTrue);
    });

    test('rejects invalid CNPJ', () {
      expect(Validators.isValidCnpj('11.222.333/0001-82'), isFalse);
      expect(Validators.isValidCnpj('11.111.111/1111-11'), isFalse);
      expect(Validators.isValidCnpj('123'), isFalse);
    });
  });
}
