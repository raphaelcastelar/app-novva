import 'package:flutter_test/flutter_test.dart';
import 'package:novva_app/features/documents/data/models/document_item_model.dart';
import 'package:novva_app/features/documents/domain/entities/document_item.dart';

void main() {
  group('DocumentItemModel', () {
    test('maps every API status', () {
      const statuses = {
        'PENDING': DocumentStatus.pending,
        'SENT': DocumentStatus.sent,
        'REVIEW': DocumentStatus.review,
        'APPROVED': DocumentStatus.approved,
        'REJECTED': DocumentStatus.rejected,
      };

      for (final entry in statuses.entries) {
        final item = DocumentItemModel.fromJson({
          'id': entry.key,
          'title': 'Documento',
          'category': 'Fiscal',
          'status': entry.key,
          'month': 10,
          'year': 2026,
        });

        expect(item.status, entry.value);
      }
    });

    test('uses creation date when month and year are absent', () {
      final item = DocumentItemModel.fromJson({
        'id': 'document-id',
        'title': 'Documento',
        'category': 'Fiscal',
        'status': 'REVIEW',
        'createdAt': '2026-08-14T12:00:00.000Z',
      });

      expect(item.month, 8);
      expect(item.year, 2026);
    });

    test('rejects an unknown API status', () {
      expect(
        () => DocumentItemModel.fromJson({
          'id': 'document-id',
          'title': 'Documento',
          'category': 'Fiscal',
          'status': 'UNKNOWN',
        }),
        throwsFormatException,
      );
    });
  });
}
