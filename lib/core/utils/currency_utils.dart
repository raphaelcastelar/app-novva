class CurrencyUtils {
  const CurrencyUtils._();

  static int centsFromInput(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    return digits.isEmpty ? 0 : int.parse(digits);
  }
}
