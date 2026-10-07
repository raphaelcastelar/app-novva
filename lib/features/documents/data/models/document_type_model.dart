import '../../domain/entities/document_type.dart';

class DocumentTypeModel extends DocumentType {
  const DocumentTypeModel({
    required super.id,
    required super.key,
    required super.name,
    required super.category,
    super.validityMonths,
  });

  factory DocumentTypeModel.fromJson(Map<String, dynamic> json) =>
      DocumentTypeModel(
        id: json['id'] as String,
        key: json['key'] as String,
        name: json['name'] as String,
        category: json['category'] as String,
        validityMonths: (json['validityMonths'] as num?)?.toInt(),
      );
}
