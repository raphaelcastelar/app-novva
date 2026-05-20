class AppException implements Exception {
  const AppException(this.message);
  final String message;
}

class UnauthorizedException extends AppException {
  const UnauthorizedException() : super('Não autorizado.');
}
