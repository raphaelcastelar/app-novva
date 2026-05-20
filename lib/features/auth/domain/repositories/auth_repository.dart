import '../entities/auth_user.dart';
import '../entities/session.dart';

abstract interface class AuthRepository {
  Future<AuthUser?> verifyCpf(String cpf);
  Future<Session> login({required String cpf, required String password});
  Future<Session> createPassword(
      {required String cpf, required String password});
  Future<void> requestPasswordReset(String cpf);
  Future<void> changePassword(
      {required String currentPassword, required String newPassword});
  Future<void> logout();
}
