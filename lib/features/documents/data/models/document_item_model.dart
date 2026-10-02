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
