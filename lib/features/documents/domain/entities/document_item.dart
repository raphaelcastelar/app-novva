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
    this.hasFile = false,
    this.originalName,
    this.mimeType,
    this.fileUploadedAt,
    this.expiresAt,
    this.validityMonths,
    this.possiblyExpired = false,
    this.documentTypeId,
  });

  final String id;
  final String title;
  final String category;
  final DocumentStatus status;
  final int month;
  final int year;
  final String? rejectionReason;
  final bool hasFile;
  final String? originalName;
  final String? mimeType;
  final DateTime? fileUploadedAt;
  final DateTime? expiresAt;
  final int? validityMonths;
  final bool possiblyExpired;
  final String? documentTypeId;
}
