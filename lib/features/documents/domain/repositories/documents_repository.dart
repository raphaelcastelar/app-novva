import '../entities/document_item.dart';
import '../entities/document_type.dart';

abstract interface class DocumentsRepository {
  Future<List<DocumentItem>> fetchDocuments();
  Future<List<DocumentType>> fetchDocumentTypes();
  Future<List<int>> downloadDocument(String id);
}
