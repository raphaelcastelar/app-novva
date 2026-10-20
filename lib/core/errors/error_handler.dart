import 'dart:io';

import 'package:dio/dio.dart';

import 'failures.dart';

class ErrorHandler {
  const ErrorHandler._();

  static String userMessage(Object error) {
    if (error is Failure) return error.message;
    if (error is DioException) {
      final apiMessage = _apiMessage(error.response?.data);
      if (apiMessage != null) return apiMessage;

      if (error.type == DioExceptionType.connectionTimeout ||
          error.type == DioExceptionType.sendTimeout ||
          error.type == DioExceptionType.receiveTimeout) {
        return 'A conexão demorou demais. Tente novamente.';
      }

      if (error.type == DioExceptionType.connectionError ||
          error.error is SocketException) {
        return 'Não foi possível conectar ao servidor. Verifique sua internet e tente novamente.';
      }

      return 'Não foi possível concluir a solicitação. Tente novamente.';
    }
    return 'Algo não saiu como esperado. Tente novamente.';
  }

  static String? _apiMessage(Object? data) {
    if (data is! Map) return null;
    final message = data['message'];
    if (message is String && message.trim().isNotEmpty) return message;
    if (message is List) {
      final messages = message.whereType<String>().toList();
      if (messages.isNotEmpty) return messages.join(' ');
    }
    return null;
  }
}
