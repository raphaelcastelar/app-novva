import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/document_item.dart';

final documentsProvider = Provider<List<DocumentItem>>(
  (_) => const [
    DocumentItem(
        id: '1',
        title: 'Extrato bancário',
        category: 'Extratos bancários',
        status: DocumentStatus.pending,
        month: 5,
        year: 2026),
    DocumentItem(
        id: '2',
        title: 'Contrato social',
        category: 'Contratos',
        status: DocumentStatus.approved,
        month: 4,
        year: 2026),
    DocumentItem(
        id: '3',
        title: 'Comprovante hospital',
        category: 'Comprovantes',
        status: DocumentStatus.rejected,
        month: 5,
        year: 2026,
        rejectionReason:
            'Arquivo ilegível. Envie uma foto com melhor iluminação.'),
    DocumentItem(
        id: '4',
        title: 'Notas fiscais',
        category: 'Notas fiscais',
        status: DocumentStatus.review,
        month: 5,
        year: 2026),
  ],
);
