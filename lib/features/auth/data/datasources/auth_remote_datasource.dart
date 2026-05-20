import '../../../../core/errors/failures.dart';
import '../models/auth_user_model.dart';

abstract interface class AuthRemoteDataSource {
  Future<AuthUserModel?> verifyCpf(String cpf);
  Future<AuthUserModel> login(String cpf, String password);
  Future<AuthUserModel> createPassword(String cpf, String password);
  Future<void> requestPasswordReset(String cpf);
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
  Future<AuthUserModel> login(String cpf, String password) async {
    await Future<void>.delayed(const Duration(milliseconds: 500));
    final data = _users[cpf];
    if (data == null) {
      throw const UnauthorizedFailure('CPF não encontrado.');
    }
    if (data['senha'] != password) {
      throw const UnauthorizedFailure('Senha incorreta.');
    }
    return AuthUserModel.fromJson(data);
  }

  @override
  Future<AuthUserModel> createPassword(String cpf, String password) async {
    final data = _users[cpf];
    if (data == null) {
      throw const UnauthorizedFailure('CPF não encontrado.');
    }
    data['senha'] = password;
    return AuthUserModel.fromJson(data);
  }

  @override
  Future<void> requestPasswordReset(String cpf) async {
    await Future<void>.delayed(const Duration(milliseconds: 450));
  }
}
