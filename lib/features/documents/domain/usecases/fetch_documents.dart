import '../entities/document_item.dart';
import '../repositories/documents_repository.dart';

class FetchDocuments {
  const FetchDocuments(this._repository);

  final DocumentsRepository _repository;

  Future<List<DocumentItem>> call() => _repository.fetchDocuments();
}
