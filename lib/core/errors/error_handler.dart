import 'failures.dart';

class ErrorHandler {
  const ErrorHandler._();

  static String userMessage(Object error) {
    if (error is Failure) return error.message;
    return 'Algo não saiu como esperado. Tente novamente.';
  }
}
