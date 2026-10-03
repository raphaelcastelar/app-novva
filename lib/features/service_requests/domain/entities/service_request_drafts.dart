class DocumentRequestDraft {
  const DocumentRequestDraft({
    required this.title,
    required this.category,
    this.description = '',
  });

  final String title;
  final String category;
  final String description;
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

class CreatedServiceRequest {
  const CreatedServiceRequest({required this.id, required this.status});
  final String id;
  final String status;
}
