import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:novva_app/app/theme/app_theme.dart';
import 'package:novva_app/features/documents/domain/entities/document_item.dart';
import 'package:novva_app/features/documents/domain/entities/document_type.dart';
import 'package:novva_app/features/documents/domain/repositories/documents_repository.dart';
import 'package:novva_app/features/documents/domain/usecases/fetch_documents.dart';
import 'package:novva_app/features/documents/presentation/pages/documents_page.dart';
import 'package:novva_app/features/documents/presentation/providers/documents_providers.dart';

class _DocumentsRepository implements DocumentsRepository {
  @override
  Future<List<int>> downloadDocument(String id) async => const [];

  @override
  Future<List<DocumentItem>> fetchDocuments() async => [
        DocumentItem(
          id: 'document-id',
          title: 'Certidão de regularidade',
          category: 'Fiscal',
          status: DocumentStatus.approved,
          month: 1,
          year: 2026,
          hasFile: true,
          originalName: 'certidao.pdf',
          documentTypeId: 'type-id',
          fileUploadedAt: DateTime(2026, 1, 10),
          expiresAt: DateTime(2026, 7, 10),
          validityMonths: 6,
          possiblyExpired: true,
        ),
        const DocumentItem(
          id: 'pending-document-id',
          title: 'Contrato social',
          category: 'Societário',
          status: DocumentStatus.pending,
          month: 10,
          year: 2026,
          documentTypeId: 'pending-type-id',
        ),
      ];

  @override
  Future<List<DocumentType>> fetchDocumentTypes() async => const [
        DocumentType(
          id: 'type-id',
          key: 'certidao-regularidade',
          name: 'Certidão de regularidade',
          category: 'Fiscal',
          validityMonths: 6,
        ),
        DocumentType(
          id: 'pending-type-id',
          key: 'contrato-social',
          name: 'Contrato social',
          category: 'Societário',
        ),
      ];
}

void main() {
  testWidgets('expands a document and shows expired actions on an iPhone',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DocumentsRepository();
    final router = GoRouter(
      routes: [
        GoRoute(path: '/', builder: (_, __) => const DocumentsPage()),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsProvider.overrideWith(
            (ref) => DocumentsController(
              FetchDocuments(repository),
              refreshInterval: null,
            ),
          ),
          documentTypesProvider.overrideWith(
            (ref) => repository.fetchDocumentTypes(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Seu arquivo contábil'), findsOneWidget);
    expect(find.text('Escolha um documento'), findsOneWidget);
    expect(find.text('Vencido'), findsOneWidget);
    await tester.tap(find.text('Certidão de regularidade').first);
    await tester.pumpAndSettle();

    expect(find.text('Documento possivelmente vencido'), findsOneWidget);
    expect(find.text('Solicitar atualização'), findsOneWidget);
    expect(find.text('Baixar documento'), findsOneWidget);

    await tester.tap(find.text('Enviados'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Certidão de regularidade'));
    await tester.pumpAndSettle();

    expect(find.text('Documento possivelmente vencido'), findsOneWidget);
    expect(find.text('Solicitar atualização'), findsOneWidget);
    expect(find.text('Baixar documento'), findsOneWidget);

    await tester.tap(find.text('Recebidos'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Certidão de regularidade'));
    await tester.pumpAndSettle();

    expect(find.text('Documento possivelmente vencido'), findsOneWidget);
    expect(find.text('Solicitar atualização'), findsOneWidget);
    expect(find.text('Baixar documento'), findsOneWidget);

    await tester.tap(find.text('Pendentes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Contrato social'));
    await tester.pumpAndSettle();

    expect(find.text('Solicitação em andamento'), findsOneWidget);
    expect(find.text('Solicitar documento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('opens the notified document in the received tab',
      (tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final repository = _DocumentsRepository();
    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (_, __) =>
              const DocumentsPage(initialDocumentId: 'document-id'),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          documentsProvider.overrideWith(
            (ref) => DocumentsController(
              FetchDocuments(repository),
              refreshInterval: null,
            ),
          ),
          documentTypesProvider.overrideWith(
            (ref) => repository.fetchDocumentTypes(),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light,
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Escolha um documento'), findsNothing);
    expect(find.text('Certidão de regularidade'), findsOneWidget);
    expect(find.text('Baixar documento'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
