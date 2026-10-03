import 'package:dio/dio.dart';

import '../security/token_manager.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenManager, this._retryDio);

  final TokenManager _tokenManager;
  final Dio _retryDio;

  static const _retriedKey = 'novva_auth_retried';
  static const _unauthenticatedPaths = <String>{
    'auth/verify-cpf',
    'auth/login',
    'auth/create-password',
    'auth/refresh',
    'auth/forgot-password',
    'auth/reset-password',
  };

  @override
  Future<void> onRequest(
      RequestOptions options, RequestInterceptorHandler handler) async {
    final token = await _tokenManager.accessToken;
    if (token != null && token.isNotEmpty) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    handler.next(options);
  }

  @override
  Future<void> onError(
      DioException err, ErrorInterceptorHandler handler) async {
    final request = err.requestOptions;
    final normalizedPath =
        request.path.startsWith('/') ? request.path.substring(1) : request.path;
    final canRefresh = err.response?.statusCode == 401 &&
        request.extra[_retriedKey] != true &&
        !_unauthenticatedPaths.contains(normalizedPath);

    if (!canRefresh) {
      handler.next(err);
      return;
    }

    try {
      final accessToken = await _tokenManager.refreshAccessToken(
        (refreshToken) async {
          final response = await _retryDio.post<Map<String, dynamic>>(
            'auth/refresh',
            data: {'refreshToken': refreshToken},
          );
          final data = response.data;
          final newAccessToken = data?['accessToken'] as String?;
          final newRefreshToken = data?['refreshToken'] as String?;
          if (newAccessToken == null || newRefreshToken == null) {
            throw const FormatException('Resposta de renovação inválida.');
          }
          return RefreshedSessionTokens(
            accessToken: newAccessToken,
            refreshToken: newRefreshToken,
          );
        },
      );

      if (accessToken == null) {
        await _tokenManager.clear();
        handler.next(err);
        return;
      }

      request.extra[_retriedKey] = true;
      request.headers['Authorization'] = 'Bearer $accessToken';
      final response = await _retryDio.fetch<dynamic>(request);
      handler.resolve(response);
    } catch (_) {
      handler.next(err);
    }
  }
}
