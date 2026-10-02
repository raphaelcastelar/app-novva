import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/features/documents/domain/entities/document_item.dart';
import 'package:novva_app/features/documents/domain/repositories/documents_repository.dart';
import 'package:novva_app/features/documents/domain/usecases/fetch_documents.dart';
import 'package:novva_app/features/documents/presentation/providers/documents_providers.dart';

class FakeDocumentsRepository implements DocumentsRepository {
  List<DocumentItem> items = const [];

  @override
  Future<List<DocumentItem>> fetchDocuments() async => items;
}

void main() {
  test('loads documents and reflects a later status change', () async {
    final repository = FakeDocumentsRepository()
      ..items = const [
        DocumentItem(
          id: 'document-id',
          title: 'Certidão',
          category: 'Fiscal',
          status: DocumentStatus.pending,
          month: 10,
          year: 2026,
        ),
      ];
    final controller = DocumentsController(
      FetchDocuments(repository),
      refreshInterval: null,
    );
    addTearDown(controller.dispose);

    await _waitForData(controller);
    expect(controller.state.valueOrNull?.single.status, DocumentStatus.pending);

    repository.items = const [
      DocumentItem(
        id: 'document-id',
        title: 'Certidão',
        category: 'Fiscal',
        status: DocumentStatus.approved,
        month: 10,
        year: 2026,
      ),
    ];

    await controller.refresh();

    expect(
        controller.state.valueOrNull?.single.status, DocumentStatus.approved);
  });
}

Future<void> _waitForData(DocumentsController controller) async {
  for (var attempt = 0; attempt < 20; attempt++) {
    if (controller.state is AsyncData<List<DocumentItem>>) return;
    await Future<void>.delayed(const Duration(milliseconds: 5));
  }
  fail('DocumentsController did not finish loading.');
}
