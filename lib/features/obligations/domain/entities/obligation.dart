enum ObligationStatus { open, dueSoon, overdue, paid, canceled }

class Obligation {
  const Obligation({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paymentCode,
    this.hasFile = false,
    this.competenceMonth,
    this.competenceYear,
    this.generatedAt,
  });

  final String id;
  final String name;
  final DateTime dueDate;
  final double amount;
  final ObligationStatus status;
  final String? paymentCode;
  final bool hasFile;
  final int? competenceMonth;
  final int? competenceYear;
  final DateTime? generatedAt;

  int get referenceMonth => competenceMonth ?? dueDate.month;
  int get referenceYear => competenceYear ?? dueDate.year;

  Obligation copyWith({
    String? id,
    String? name,
    DateTime? dueDate,
    double? amount,
    ObligationStatus? status,
    String? paymentCode,
    bool? hasFile,
    int? competenceMonth,
    int? competenceYear,
    DateTime? generatedAt,
  }) {
    return Obligation(
      id: id ?? this.id,
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentCode: paymentCode ?? this.paymentCode,
      hasFile: hasFile ?? this.hasFile,
      competenceMonth: competenceMonth ?? this.competenceMonth,
      competenceYear: competenceYear ?? this.competenceYear,
      generatedAt: generatedAt ?? this.generatedAt,
    );
  }
}
