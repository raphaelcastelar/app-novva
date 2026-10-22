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

    test('maps validity and possibly expired metadata', () {
      final item = DocumentItemModel.fromJson({
        'id': 'document-id',
        'title': 'Certidão de regularidade',
        'category': 'Fiscal',
        'status': 'APPROVED',
        'month': 1,
        'year': 2026,
        'hasFile': true,
        'fileUploadedAt': '2026-01-10T12:00:00.000Z',
        'expiresAt': '2026-07-10T12:00:00.000Z',
        'validityMonths': 6,
        'possiblyExpired': true,
        'documentTypeId': 'type-id',
        'adminNote': 'Confira a validade antes de utilizar.',
      });

      expect(item.validityMonths, 6);
      expect(item.fileUploadedAt, DateTime.utc(2026, 1, 10, 12));
      expect(item.expiresAt, DateTime.utc(2026, 7, 10, 12));
      expect(item.possiblyExpired, isTrue);
      expect(item.documentTypeId, 'type-id');
      expect(item.adminNote, 'Confira a validade antes de utilizar.');
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
