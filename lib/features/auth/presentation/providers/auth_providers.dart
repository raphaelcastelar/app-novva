import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../../core/security/secure_storage_service.dart';
import '../../../../core/security/token_manager.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/verify_cpf_usecase.dart';

final authListenable = AuthListenable();

class AuthListenable extends ChangeNotifier {
  bool isAuthenticated = false;

  void setAuthenticated(bool value) {
    isAuthenticated = value;
    notifyListeners();
  }
}

final secureStorageProvider = Provider(
  (_) => const SecureStorageService(FlutterSecureStorage()),
);

final tokenManagerProvider =
    Provider((ref) => TokenManager(ref.watch(secureStorageProvider)));
final authRemoteDataSourceProvider =
    Provider<AuthRemoteDataSource>((_) => MockAuthRemoteDataSource());
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
      ref.watch(authRemoteDataSourceProvider), ref.watch(tokenManagerProvider)),
);
final verifyCpfUseCaseProvider =
    Provider((ref) => VerifyCpfUseCase(ref.watch(authRepositoryProvider)));
final loginUseCaseProvider =
    Provider((ref) => LoginUseCase(ref.watch(authRepositoryProvider)));

final authControllerProvider =
    StateNotifierProvider<AuthController, AsyncValue<AuthUser?>>(
  (ref) => AuthController(
    ref.watch(authRepositoryProvider),
    ref.watch(verifyCpfUseCaseProvider),
    ref.watch(loginUseCaseProvider),
  ),
);

class AuthController extends StateNotifier<AsyncValue<AuthUser?>> {
  AuthController(this._repository, this._verifyCpf, this._login)
      : super(const AsyncData(null));

  final AuthRepository _repository;
  final VerifyCpfUseCase _verifyCpf;
  final LoginUseCase _login;

  Future<AuthUser?> verifyCpf(String cpf) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(() => _verifyCpf(cpf));
    state = result;
    return result.valueOrNull;
  }

  Future<void> login(String cpf, String password) async {
    state = const AsyncLoading();
    final result =
        await AsyncValue.guard(() => _login(cpf: cpf, password: password));
    result.when(
      data: (session) {
        authListenable.setAuthenticated(true);
        state = AsyncData(session.user);
      },
      error: (error, stackTrace) => state = AsyncError(error, stackTrace),
      loading: () {},
    );
  }

  Future<void> createPassword(String cpf, String password) async {
    state = const AsyncLoading();
    final result = await AsyncValue.guard(
        () => _repository.createPassword(cpf: cpf, password: password));
    result.when(
      data: (session) {
        authListenable.setAuthenticated(true);
        state = AsyncData(session.user);
      },
      error: (error, stackTrace) => state = AsyncError(error, stackTrace),
      loading: () {},
    );
  }

  Future<void> logout() async {
    await _repository.logout();
    authListenable.setAuthenticated(false);
    state = const AsyncData(null);
  }
}
