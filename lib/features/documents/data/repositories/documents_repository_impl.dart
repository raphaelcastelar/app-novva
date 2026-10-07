import '../../domain/entities/document_item.dart';
import '../../domain/repositories/documents_repository.dart';
import '../datasources/documents_remote_datasource.dart';
import '../models/document_item_model.dart';
import '../models/document_type_model.dart';
import '../../domain/entities/document_type.dart';

class DocumentsRepositoryImpl implements DocumentsRepository {
  const DocumentsRepositoryImpl(this._remote);

  final DocumentsRemoteDataSource _remote;

  @override
  Future<List<DocumentItem>> fetchDocuments() async {
    final items = await _remote.fetchDocuments();
    return items.map(DocumentItemModel.fromJson).toList(growable: false);
  }

  @override
  Future<List<DocumentType>> fetchDocumentTypes() async {
    final items = await _remote.fetchDocumentTypes();
    return items.map(DocumentTypeModel.fromJson).toList(growable: false);
  }

  @override
  Future<List<int>> downloadDocument(String id) => _remote.downloadDocument(id);
}
