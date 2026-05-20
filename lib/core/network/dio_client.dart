import 'package:dio/dio.dart';

import '../../app/config/env.dart';
import '../security/token_manager.dart';
import 'api_interceptors.dart';

class DioClient {
  DioClient(TokenManager tokenManager)
      : dio = Dio(
          BaseOptions(
            baseUrl: Env.apiBaseUrl,
            connectTimeout: const Duration(seconds: 15),
            receiveTimeout: const Duration(seconds: 20),
            sendTimeout: const Duration(seconds: 20),
            headers: {'Accept': 'application/json'},
          ),
        ) {
    dio.interceptors.add(AuthInterceptor(tokenManager));
  }

  final Dio dio;
}
