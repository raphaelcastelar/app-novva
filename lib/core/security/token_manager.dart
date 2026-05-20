import 'secure_storage_service.dart';

class TokenManager {
  TokenManager(this._storage);

  final SecureStorageService _storage;
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _cpfKey = 'cpf';
  static const _userNameKey = 'user_name';

  Future<String?> get accessToken => _storage.read(_accessTokenKey);
  Future<String?> get cpf => _storage.read(_cpfKey);
  Future<String?> get userName => _storage.read(_userNameKey);

  Future<void> saveSession({
    required String accessToken,
    required String cpf,
    required String userName,
    String? refreshToken,
  }) async {
    await _storage.write(_accessTokenKey, accessToken);
    await _storage.write(_cpfKey, cpf);
    await _storage.write(_userNameKey, userName);
    if (refreshToken != null) {
      await _storage.write(_refreshTokenKey, refreshToken);
    }
  }

  Future<void> clear() => _storage.deleteAll();
}
