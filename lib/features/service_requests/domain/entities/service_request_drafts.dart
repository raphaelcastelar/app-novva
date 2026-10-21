class DocumentRequestDraft {
  const DocumentRequestDraft({
    required this.title,
    required this.category,
    this.description = '',
    this.documentTypeId,
  });

  final String title;
  final String category;
  final String description;
  final String? documentTypeId;
}

class InvoiceRequestDraft {
  const InvoiceRequestDraft({
    required this.takerCnpj,
    required this.takerName,
    required this.municipality,
    required this.serviceDate,
    required this.amount,
    required this.taxationCode,
    required this.description,
  });

  final String takerCnpj;
  final String takerName;
  final String municipality;
  final DateTime serviceDate;
  final double amount;
  final String taxationCode;
  final String description;

  factory InvoiceRequestDraft.fromJson(Map<String, dynamic> json) =>
      InvoiceRequestDraft(
        takerCnpj: json['takerCnpj'] as String,
        takerName: json['takerName'] as String,
        municipality: json['municipality'] as String,
        serviceDate: DateTime.parse(json['serviceDate'] as String),
        amount: (json['amount'] as num).toDouble(),
        taxationCode: json['taxationCode'] as String,
        description: json['description'] as String,
      );

  InvoiceRequestDraft copyWith({String? description}) => InvoiceRequestDraft(
        takerCnpj: takerCnpj,
        takerName: takerName,
        municipality: municipality,
        serviceDate: serviceDate,
        amount: amount,
        taxationCode: taxationCode,
        description: description ?? this.description,
      );
}

class InvoiceDescriptionFavorite {
  const InvoiceDescriptionFavorite({
    required this.id,
    required this.description,
  });

  final String id;
  final String description;

  factory InvoiceDescriptionFavorite.fromJson(Map<String, dynamic> json) =>
      InvoiceDescriptionFavorite(
        id: json['id'] as String,
        description: json['description'] as String,
      );
}

class CreatedServiceRequest {
  const CreatedServiceRequest({required this.id, required this.status});
  final String id;
  final String status;
}
