import 'secure_storage_service.dart';

class RefreshedSessionTokens {
  const RefreshedSessionTokens({
    required this.accessToken,
    required this.refreshToken,
  });

  final String accessToken;
  final String refreshToken;
}

class TokenManager {
  TokenManager(this._storage);

  final SecureStorageService _storage;
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _cpfKey = 'cpf';
  static const _userNameKey = 'user_name';

  Future<String?>? _refreshInProgress;

  Future<String?> get accessToken => _storage.read(_accessTokenKey);
  Future<String?> get refreshToken => _storage.read(_refreshTokenKey);
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

  Future<String?> refreshAccessToken(
    Future<RefreshedSessionTokens> Function(String refreshToken) refresh,
  ) {
    final runningRefresh = _refreshInProgress;
    if (runningRefresh != null) return runningRefresh;

    final operation = _performRefresh(refresh);
    _refreshInProgress = operation;
    return operation.whenComplete(() {
      if (identical(_refreshInProgress, operation)) {
        _refreshInProgress = null;
      }
    });
  }

  Future<String?> _performRefresh(
    Future<RefreshedSessionTokens> Function(String refreshToken) refresh,
  ) async {
    final storedRefreshToken = await refreshToken;
    if (storedRefreshToken == null || storedRefreshToken.isEmpty) return null;

    try {
      final tokens = await refresh(storedRefreshToken);
      await _storage.write(_accessTokenKey, tokens.accessToken);
      await _storage.write(_refreshTokenKey, tokens.refreshToken);
      return tokens.accessToken;
    } catch (_) {
      await clear();
      rethrow;
    }
  }

  Future<void> clear() async {
    await Future.wait([
      _storage.delete(_accessTokenKey),
      _storage.delete(_refreshTokenKey),
      _storage.delete(_cpfKey),
      _storage.delete(_userNameKey),
    ]);
  }
}
