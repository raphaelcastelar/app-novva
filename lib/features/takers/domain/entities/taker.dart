class Taker {
  const Taker({
    required this.id,
    required this.name,
    required this.cnpj,
    required this.municipality,
  });

  final String id;
  final String name;
  final String cnpj;
  final String municipality;

  factory Taker.fromJson(Map<String, dynamic> json) => Taker(
        id: json['id'] as String,
        name: json['name'] as String,
        cnpj: json['cnpj'] as String,
        municipality: json['municipality'] as String,
      );
}
