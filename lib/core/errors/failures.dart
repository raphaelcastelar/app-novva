sealed class Failure {
  const Failure(this.message);
  final String message;
}

class ValidationFailure extends Failure {
  const ValidationFailure(super.message);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([super.message = 'Sessão expirada.']);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sem conexão.']);
}

class ServerFailure extends Failure {
  const ServerFailure(
      [super.message = 'Não foi possível concluir a operação.']);
}
