import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../entities/session.dart';
import '../repositories/auth_repository.dart';

class LoginUseCase {
  const LoginUseCase(this._repository);
  final AuthRepository _repository;

  Future<Session> call({required String cpf, required String password}) {
    final sanitized = cpf.replaceAll(RegExp(r'\D'), '');
    if (!Validators.isValidCpf(sanitized)) {
      throw const ValidationFailure('CPF inválido.');
    }
    if (password.isEmpty) {
      throw const ValidationFailure('Informe sua senha.');
    }
    return _repository.login(cpf: sanitized, password: password);
  }
}
