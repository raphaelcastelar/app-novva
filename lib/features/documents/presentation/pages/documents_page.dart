import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/document_item.dart';
import '../providers/documents_providers.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsProvider);
    return AppScaffold(
      title: 'Documentos',
      actions: [
        IconButton(
            onPressed: () => context.go(RouteNames.documentUpload),
            icon: const Icon(Icons.upload_file_outlined))
      ],
      child: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: documents.length + 1,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (_, index) {
          if (index == 0) {
            return Wrap(
              spacing: 8,
              runSpacing: 8,
              children: const [
                FilterChip(label: Text('Maio/2026'), onSelected: null),
                FilterChip(label: Text('Notas fiscais'), onSelected: null),
                FilterChip(label: Text('Pendentes'), onSelected: null),
              ],
            );
          }
          final doc = documents[index - 1];
          return AppCard(
            onTap: () => context.go(RouteNames.documentDetails),
            child: Row(
              children: [
                const Icon(Icons.description_outlined,
                    color: AppColors.primary),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(doc.title,
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text('${doc.category} - ${doc.month}/${doc.year}',
                          style: const TextStyle(color: AppColors.muted)),
                    ],
                  ),
                ),
                StatusBadge(_label(doc.status), color: _color(doc.status)),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _label(DocumentStatus status) => switch (status) {
        DocumentStatus.pending => 'Pendente',
        DocumentStatus.sent => 'Enviado',
        DocumentStatus.review => 'Em análise',
        DocumentStatus.approved => 'Aprovado',
        DocumentStatus.rejected => 'Rejeitado',
      };

  static Color _color(DocumentStatus status) => switch (status) {
        DocumentStatus.pending => AppColors.warning,
        DocumentStatus.sent => AppColors.primary,
        DocumentStatus.review => AppColors.primary,
        DocumentStatus.approved => AppColors.success,
        DocumentStatus.rejected => AppColors.danger,
      };
}
