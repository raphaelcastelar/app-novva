import '../../../../core/security/token_manager.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_remote_datasource.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(this._remote, this._tokenManager);

  final AuthRemoteDataSource _remote;
  final TokenManager _tokenManager;

  @override
  Future<Session> login({required String cpf, required String password}) async {
    final user = await _remote.login(cpf, password);
    final session = Session(accessToken: 'mock-access-token', user: user);
    await _tokenManager.saveSession(
        accessToken: session.accessToken, cpf: cpf, userName: user.name);
    return session;
  }

  @override
  Future<Session> createPassword(
      {required String cpf, required String password}) async {
    final user = await _remote.createPassword(cpf, password);
    final session = Session(accessToken: 'mock-access-token', user: user);
    await _tokenManager.saveSession(
        accessToken: session.accessToken, cpf: cpf, userName: user.name);
    return session;
  }

  @override
  Future<void> requestPasswordReset(String cpf) =>
      _remote.requestPasswordReset(cpf);

  @override
  Future<AuthUser?> verifyCpf(String cpf) => _remote.verifyCpf(cpf);

  @override
  Future<void> changePassword(
      {required String currentPassword, required String newPassword}) async {}

  @override
  Future<void> logout() => _tokenManager.clear();
}
