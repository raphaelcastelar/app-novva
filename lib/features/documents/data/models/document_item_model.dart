import '../../domain/entities/document_item.dart';

class DocumentItemModel extends DocumentItem {
  const DocumentItemModel({
    required super.id,
    required super.title,
    required super.category,
    required super.status,
    required super.month,
    required super.year,
    super.rejectionReason,
    super.hasFile,
    super.originalName,
    super.mimeType,
    super.fileUploadedAt,
    super.expiresAt,
    super.validityMonths,
    super.possiblyExpired,
    super.documentTypeId,
    super.adminNote,
  });

  factory DocumentItemModel.fromJson(Map<String, dynamic> json) {
    final createdAt = DateTime.tryParse(json['createdAt'] as String? ?? '');
    final now = DateTime.now();

    return DocumentItemModel(
      id: json['id'] as String,
      title: json['title'] as String,
      category: json['category'] as String,
      status: _statusFromApi(json['status'] as String?),
      month: (json['month'] as num?)?.toInt() ?? createdAt?.month ?? now.month,
      year: (json['year'] as num?)?.toInt() ?? createdAt?.year ?? now.year,
      rejectionReason: json['rejectionReason'] as String?,
      hasFile: json['hasFile'] as bool? ?? false,
      originalName: json['originalName'] as String?,
      mimeType: json['mimeType'] as String?,
      fileUploadedAt:
          DateTime.tryParse(json['fileUploadedAt'] as String? ?? ''),
      expiresAt: DateTime.tryParse(json['expiresAt'] as String? ?? ''),
      validityMonths: (json['validityMonths'] as num?)?.toInt(),
      possiblyExpired: json['possiblyExpired'] as bool? ?? false,
      documentTypeId: json['documentTypeId'] as String? ??
          (json['documentType'] as Map?)?['id'] as String?,
      adminNote: json['adminNote'] as String?,
    );
  }

  static DocumentStatus _statusFromApi(String? value) {
    return switch (value?.toUpperCase()) {
      'PENDING' => DocumentStatus.pending,
      'SENT' => DocumentStatus.sent,
      'REVIEW' => DocumentStatus.review,
      'APPROVED' => DocumentStatus.approved,
      'REJECTED' => DocumentStatus.rejected,
      _ => throw FormatException('Status de documento desconhecido: $value'),
    };
  }
}
