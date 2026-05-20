import '../../domain/entities/auth_user.dart';

class AuthUserModel extends AuthUser {
  const AuthUserModel({
    required super.cpf,
    required super.name,
    super.email,
    super.needsPasswordCreation,
  });

  factory AuthUserModel.fromJson(Map<String, dynamic> json) {
    return AuthUserModel(
      cpf: json['cpf'] as String,
      name: (json['nome'] ?? json['name'] ?? 'Usuário') as String,
      email: json['email'] as String?,
      needsPasswordCreation: json['needsPasswordCreation'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'cpf': cpf,
        'nome': name,
        'email': email,
        'needsPasswordCreation': needsPasswordCreation,
      };
}
