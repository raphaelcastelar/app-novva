class AuthUser {
  const AuthUser({
    required this.cpf,
    required this.name,
    this.email,
    this.needsPasswordCreation = false,
  });

  final String cpf;
  final String name;
  final String? email;
  final bool needsPasswordCreation;
}
