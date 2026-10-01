import 'package:dio/dio.dart';

import '../../../../core/errors/failures.dart';
import '../../domain/entities/session.dart';
import '../models/auth_user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthUserModel?> verifyCpf(String cpf);
  Future<Session> login(String cpf, String password);
  Future<Session> createPassword(String cpf, String password);
  Future<void> requestPasswordReset(String cpf);
}

class DioAuthRemoteDataSource implements AuthRemoteDataSource {
  const DioAuthRemoteDataSource(this._dio);
  final Dio _dio;

  @override
  Future<AuthUserModel?> verifyCpf(String cpf) async {
    final response = await _dio.post<Map<String, dynamic>>(
      'auth/verify-cpf',
      data: {'cpf': cpf},
    );
    return AuthUserModel.fromJson(response.data!);
  }

  @override
  Future<Session> login(String cpf, String password) =>
      _createSession('auth/login', cpf, password);

  @override
  Future<Session> createPassword(String cpf, String password) =>
      _createSession('auth/create-password', cpf, password);

  Future<Session> _createSession(
      String path, String cpf, String password) async {
    final response = await _dio.post<Map<String, dynamic>>(
      path,
      data: {'cpf': cpf, 'password': password},
    );
    final data = response.data!;
    return Session(
      accessToken: data['accessToken'] as String,
      refreshToken: data['refreshToken'] as String?,
      user: AuthUserModel.fromJson(data['user'] as Map<String, dynamic>),
    );
  }

  @override
  Future<void> requestPasswordReset(String cpf) async {
    await _dio.post<void>('auth/forgot-password', data: {'cpf': cpf});
  }
}

class MockAuthRemoteDataSource implements AuthRemoteDataSource {
  final Map<String, Map<String, dynamic>> _users = {
    '12831146747': {
      'cpf': '12831146747',
      'nome': 'Dra. Marina Almeida',
      'email': 'marina@example.com',
      'senha': 'novva1234',
    },
    '93541134780': {
      'cpf': '93541134780',
      'nome': 'Dr. Felipe Castro',
      'email': 'felipe@example.com',
    },
  };

  @override
  Future<AuthUserModel?> verifyCpf(String cpf) async {
    await Future<void>.delayed(const Duration(milliseconds: 350));
    final data = _users[cpf];
    if (data == null) return null;
    return AuthUserModel.fromJson(
        {...data, 'needsPasswordCreation': data['senha'] == null});
  }

  @override
  Future<Session> login(String cpf, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final data = _users[cpf];
    if (data == null) {
      throw const UnauthorizedFailure('CPF não encontrado.');
    }
    if (data['senha'] != password) {
      throw const UnauthorizedFailure('Senha incorreta.');
    }
    final user = AuthUserModel.fromJson(data);
    return Session(accessToken: 'mock-access-token', user: user);
  }

  @override
  Future<Session> createPassword(String cpf, String password) async {
    final data = _users[cpf];
    if (data == null) {
      throw const UnauthorizedFailure('CPF não encontrado.');
    }
    data['senha'] = password;
    final user = AuthUserModel.fromJson(data);
    return Session(accessToken: 'mock-access-token', user: user);
  }

  @override
  Future<void> requestPasswordReset(String cpf) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }
}
