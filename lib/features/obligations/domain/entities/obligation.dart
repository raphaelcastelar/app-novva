enum ObligationStatus { open, dueSoon, overdue, paid, canceled }

class Obligation {
  const Obligation({
    required this.id,
    required this.name,
    required this.dueDate,
    required this.amount,
    required this.status,
    this.paymentCode,
  });

  final String id;
  final String name;
  final DateTime dueDate;
  final double amount;
  final ObligationStatus status;
  final String? paymentCode;
}
