import '../../../../core/errors/failures.dart';
import '../../../../core/utils/validators.dart';
import '../entities/auth_user.dart';
import '../repositories/auth_repository.dart';

class VerifyCpfUseCase {
  const VerifyCpfUseCase(this._repository);
  final AuthRepository _repository;

  Future<AuthUser?> call(String cpf) {
    final sanitized = cpf.replaceAll(RegExp(r'\D'), '');
    if (!Validators.isValidCpf(sanitized)) {
      throw const ValidationFailure('CPF inválido.');
    }
    return _repository.verifyCpf(sanitized);
  }
}
