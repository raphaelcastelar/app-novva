enum DocumentStatus { pending, sent, review, approved, rejected }

class DocumentItem {
  const DocumentItem({
    required this.id,
    required this.title,
    required this.category,
    required this.status,
    required this.month,
    required this.year,
    this.rejectionReason,
  });

  final String id;
  final String title;
  final String category;
  final DocumentStatus status;
  final int month;
  final int year;
  final String? rejectionReason;
}
