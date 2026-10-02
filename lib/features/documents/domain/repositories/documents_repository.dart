import '../entities/document_item.dart';

abstract interface class DocumentsRepository {
  Future<List<DocumentItem>> fetchDocuments();
}
