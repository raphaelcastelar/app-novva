class DocumentType {
  const DocumentType({
    required this.id,
    required this.key,
    required this.name,
    required this.category,
    this.validityMonths,
  });

  final String id;
  final String key;
  final String name;
  final String category;
  final int? validityMonths;

  String get validityLabel => validityMonths == null
      ? 'Sem validade'
      : validityMonths == 1
          ? 'Validade de 1 mês'
          : 'Validade de $validityMonths meses';
}
