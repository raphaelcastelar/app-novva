import 'package:dio/dio.dart';

import '../security/token_manager.dart';

class AuthInterceptor extends Interceptor {
  AuthInterceptor(this._tokenManager);

  final TokenManager _tokenManager;

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
    if (err.response?.statusCode == 401 || err.response?.statusCode == 403) {
      await _tokenManager.clear();
    }
    handler.next(err);
  }
}
