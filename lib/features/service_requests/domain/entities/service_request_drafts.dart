class LocalDoctorIdentity {
  const LocalDoctorIdentity({
    required this.cpf,
    required this.name,
    required this.email,
    required this.company,
    this.crm = '',
    this.specialty = '',
  });

  final String cpf;
  final String name;
  final String email;
  final String company;
  final String crm;
  final String specialty;

  Map<String, dynamic> toJson() => {
        'cpf': cpf,
        'name': name,
        'email': email,
        'company': company,
        'crm': crm,
        'specialty': specialty,
      };
}

class DocumentRequestDraft {
  const DocumentRequestDraft({
    required this.doctor,
    required this.title,
    required this.category,
    this.description = '',
  });

  final LocalDoctorIdentity doctor;
  final String title;
  final String category;
  final String description;
}

class InvoiceRequestDraft {
  const InvoiceRequestDraft({
    required this.doctor,
    required this.takerCnpj,
    required this.takerName,
    required this.municipality,
    required this.serviceDate,
    required this.amount,
    required this.taxationCode,
    required this.description,
  });

  final LocalDoctorIdentity doctor;
  final String takerCnpj;
  final String takerName;
  final String municipality;
  final DateTime serviceDate;
  final double amount;
  final String taxationCode;
  final String description;

  InvoiceRequestDraft copyWith({String? description}) => InvoiceRequestDraft(
        doctor: doctor,
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
