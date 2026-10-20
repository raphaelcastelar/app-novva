import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/core/errors/error_handler.dart';

void main() {
  RequestOptions request() => RequestOptions(path: 'auth/verify-cpf');

  test('uses the API message for an HTTP error', () {
    final error = DioException(
      requestOptions: request(),
      response: Response<Map<String, dynamic>>(
        requestOptions: request(),
        statusCode: 404,
        data: const {'message': 'CPF não encontrado.'},
      ),
      type: DioExceptionType.badResponse,
    );

    expect(ErrorHandler.userMessage(error), 'CPF não encontrado.');
  });

  test('identifies a connection error instead of reporting missing CPF', () {
    final error = DioException(
      requestOptions: request(),
      type: DioExceptionType.connectionError,
      error: const SocketException('Failed host lookup'),
    );

    expect(
      ErrorHandler.userMessage(error),
      'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.',
    );
  });

  test('identifies a timeout', () {
    final error = DioException(
      requestOptions: request(),
      type: DioExceptionType.connectionTimeout,
    );

    expect(
      ErrorHandler.userMessage(error),
      'A conexão demorou demais. Tente novamente.',
    );
  });
}
