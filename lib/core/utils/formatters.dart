import 'package:intl/intl.dart';

class AppFormatters {
  const AppFormatters._();

  static String cpf(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 11) return value;
    return '${digits.substring(0, 3)}.${digits.substring(3, 6)}.${digits.substring(6, 9)}-${digits.substring(9)}';
  }

  static String cnpj(String value) {
    final digits = value.replaceAll(RegExp(r'\D'), '');
    if (digits.length != 14) return value;
    return '${digits.substring(0, 2)}.${digits.substring(2, 5)}.${digits.substring(5, 8)}/${digits.substring(8, 12)}-${digits.substring(12)}';
  }

  static String money(num value) =>
      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  static String date(DateTime value) =>
      DateFormat('dd/MM/yyyy', 'pt_BR').format(value);
}
