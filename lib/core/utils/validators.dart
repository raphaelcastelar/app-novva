class Validators {
  const Validators._();

  static bool isValidCpf(String value) {
    final cpf = value.replaceAll(RegExp(r'\D'), '');
    if (cpf.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(cpf)) return false;

    String digit(String source, int weight) {
      var sum = 0;
      for (var i = 0; i < weight - 1; i++) {
        sum += int.parse(source[i]) * (weight - i);
      }
      final rest = sum % 11;
      return rest < 2 ? '0' : '${11 - rest}';
    }

    return digit(cpf, 10) == cpf[9] && digit(cpf, 11) == cpf[10];
  }

  static bool isValidCnpj(String value) =>
      value.replaceAll(RegExp(r'\D'), '').length == 14;
  static bool isValidEmail(String value) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value);
  static bool isStrongPassword(String value) => value.length >= 8;
}
