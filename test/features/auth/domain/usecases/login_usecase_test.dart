import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/core/errors/failures.dart';
import 'package:novva_app/features/auth/domain/entities/auth_user.dart';
import 'package:novva_app/features/auth/domain/entities/session.dart';
import 'package:novva_app/features/auth/domain/repositories/auth_repository.dart';
import 'package:novva_app/features/auth/domain/usecases/login_usecase.dart';

class FakeAuthRepository implements AuthRepository {
  @override
  Future<Session> login({required String cpf, required String password}) async {
    return Session(
        accessToken: 'token', user: AuthUser(cpf: cpf, name: 'Teste'));
  }

  @override
  Future<Session> createPassword(
          {required String cpf, required String password}) =>
      throw UnimplementedError();
  @override
  Future<void> requestPasswordReset(String cpf) => throw UnimplementedError();
  @override
  Future<AuthUser?> verifyCpf(String cpf) => throw UnimplementedError();
  @override
  Future<void> changePassword(
          {required String currentPassword, required String newPassword}) =>
      throw UnimplementedError();
  @override
  Future<void> logout() => throw UnimplementedError();
}

void main() {
  test('validates cpf before login', () async {
    final useCase = LoginUseCase(FakeAuthRepository());
    expect(
      () => useCase(cpf: '123', password: 'senha'),
      throwsA(isA<ValidationFailure>()),
    );
  });
}
