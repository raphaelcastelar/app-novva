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
  });

  final String id;
  final String name;
  final DateTime dueDate;
  final double amount;
  final ObligationStatus status;
  final String? paymentCode;
  final bool hasFile;

  Obligation copyWith({
    String? id,
    String? name,
    DateTime? dueDate,
    double? amount,
    ObligationStatus? status,
    String? paymentCode,
    bool? hasFile,
  }) {
    return Obligation(
      id: id ?? this.id,
      name: name ?? this.name,
      dueDate: dueDate ?? this.dueDate,
      amount: amount ?? this.amount,
      status: status ?? this.status,
      paymentCode: paymentCode ?? this.paymentCode,
      hasFile: hasFile ?? this.hasFile,
    );
  }
}
