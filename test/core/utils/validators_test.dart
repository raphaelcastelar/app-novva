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
  });
}
