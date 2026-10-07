import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/document_item.dart';
import '../../domain/entities/document_type.dart';
import '../providers/documents_providers.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final showRequestFeedback = ref.watch(documentRequestFeedbackProvider);
    if (showRequestFeedback) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(documentRequestFeedbackProvider.notifier).state = false;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Solicitação enviada com sucesso.')),
        );
      });
    }

    final documents = ref.watch(documentsProvider);
    final documentTypes = ref.watch(documentTypesProvider);
    final controller = ref.read(documentsProvider.notifier);

    Future<void> refreshAll({bool showLoading = false}) async {
      ref.invalidate(documentTypesProvider);
      await controller.refresh(showLoading: showLoading);
    }

    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        title: 'Documentos',
        actions: [
          IconButton(
            tooltip: 'Atualizar documentos',
            onPressed: refreshAll,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go(
            _documentRequestRoute(_findOtherType(documentTypes.valueOrNull)),
          ),
          icon: const Icon(Icons.add),
          label: const Text('Nova solicitação'),
        ),
        child: documents.when(
          loading: () => const Stack(
            children: [
              Positioned.fill(child: _DocumentsWatermark()),
              Center(child: CircularProgressIndicator()),
            ],
          ),
          error: (error, _) => Stack(
            children: [
              const Positioned.fill(child: _DocumentsWatermark()),
              _DocumentsLoadError(
                onRetry: () => refreshAll(showLoading: true),
              ),
            ],
          ),
          data: (items) => Stack(
            children: [
              const Positioned.fill(child: _DocumentsWatermark()),
              Column(
                children: [
                  const TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    tabs: [
                      Tab(text: 'Solicitar'),
                      Tab(text: 'Enviados'),
                      Tab(text: 'Recebidos'),
                      Tab(text: 'Pendentes'),
                    ],
                  ),
                  Expanded(
                    child: TabBarView(
                      children: [
                        RefreshIndicator(
                          onRefresh: refreshAll,
                          child: _DocumentRequestTab(
                            documents: items,
                            documentTypes: documentTypes,
                          ),
                        ),
                        RefreshIndicator(
                          onRefresh: refreshAll,
                          child: _DocumentList(documents: items),
                        ),
                        RefreshIndicator(
                          onRefresh: refreshAll,
                          child: _DocumentList(
                            documents: items
                                .where((doc) =>
                                    doc.status == DocumentStatus.approved)
                                .toList(),
                            emptyMessage: 'Nenhum documento recebido ainda.',
                          ),
                        ),
                        RefreshIndicator(
                          onRefresh: refreshAll,
                          child: _DocumentList(
                            documents: items
                                .where((doc) =>
                                    doc.status == DocumentStatus.pending ||
                                    doc.status == DocumentStatus.rejected)
                                .toList(),
                            emptyMessage:
                                'Tudo certo por aqui. Sem pendências.',
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentsLoadError extends StatelessWidget {
  const _DocumentsLoadError({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            title: 'Não foi possível carregar os documentos',
            message: 'Verifique sua conexão e tente novamente.',
            icon: Icons.cloud_off_outlined,
            actionLabel: 'Tentar novamente',
            onAction: onRetry,
          ),
        ),
      );
}

class _DocumentsWatermark extends StatelessWidget {
  const _DocumentsWatermark();

  @override
  Widget build(BuildContext context) => IgnorePointer(
        child: Align(
          alignment: const Alignment(0.72, 0.34),
          child: Opacity(
            opacity: 0.045,
            child: Transform.rotate(
              angle: -0.18,
              child: Image.asset(
                'assets/images/logo.png',
                width: MediaQuery.sizeOf(context).width * 1.08,
                fit: BoxFit.contain,
              ),
            ),
          ),
        ),
      );
}

class _DocumentRequestTab extends StatelessWidget {
  const _DocumentRequestTab({
    required this.documents,
    required this.documentTypes,
  });

  final List<DocumentItem> documents;
  final AsyncValue<List<DocumentType>> documentTypes;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'O que você precisa?',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          documentTypes.when(
            loading: () => const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (_, __) => const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'Não foi possível carregar os tipos de documento.',
                style: TextStyle(color: AppColors.danger),
              ),
            ),
            data: (types) => _DocumentTypeList(types: types),
          ),
          const SizedBox(height: 20),
          const Text(
            'Acompanhamento recente',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          _DocumentList(documents: documents, shrink: true),
        ],
      );
}

class _DocumentTypeList extends StatelessWidget {
  const _DocumentTypeList({required this.types});
  final List<DocumentType> types;

  @override
  Widget build(BuildContext context) => Column(
        children: types
            .map(
              (type) => InkWell(
                onTap: () => context.go(_documentDetailsRoute(
                  type.name,
                  documentTypeId: type.id,
                )),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: AppColors.softPrimary,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.description_outlined,
                          color: AppColors.primary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(type.name,
                                style: const TextStyle(
                                    fontWeight: FontWeight.w900)),
                            const SizedBox(height: 2),
                            Text(
                              '${type.category} • ${type.validityLabel}',
                              style: const TextStyle(
                                  color: AppColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      const Icon(Icons.chevron_right_rounded,
                          color: AppColors.muted),
                    ],
                  ),
                ),
              ),
            )
            .toList(growable: false),
      );
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({
    required this.documents,
    this.emptyMessage = 'Nenhum documento encontrado.',
    this.shrink = false,
  });

  final List<DocumentItem> documents;
  final String emptyMessage;
  final bool shrink;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      final state = EmptyState(
        title: 'Tudo limpo',
        message: emptyMessage,
        icon: Icons.folder_open_outlined,
      );
      if (shrink) {
        return Padding(padding: const EdgeInsets.all(16), child: state);
      }
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [state],
      );
    }

    return ListView.separated(
      shrinkWrap: shrink,
      physics: shrink
          ? const NeverScrollableScrollPhysics()
          : const AlwaysScrollableScrollPhysics(),
      padding:
          shrink ? EdgeInsets.zero : const EdgeInsets.symmetric(horizontal: 16),
      itemCount: documents.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (_, index) => _DocumentRow(doc: documents[index]),
    );
  }
}

class _DocumentRow extends StatelessWidget {
  const _DocumentRow({required this.doc});
  final DocumentItem doc;

  @override
  Widget build(BuildContext context) {
    final color = _color(doc.status);
    return InkWell(
      onTap: () => context.go(_documentDetailsRoute(
        doc.title,
        id: doc.hasFile ? doc.id : null,
        originalName: doc.originalName,
        possiblyExpired:
            doc.possiblyExpired && doc.status == DocumentStatus.approved,
        expiresAt: doc.expiresAt,
      )),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.description_outlined, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    doc.title,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    '${doc.category} • ${doc.month}/${doc.year}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        const TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  if (doc.possiblyExpired &&
                      doc.status == DocumentStatus.approved) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            size: 15, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            'Possivelmente vencido${doc.expiresAt == null ? '' : ' desde ${_date(doc.expiresAt!)}'}',
                            style: const TextStyle(
                              color: AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (doc.rejectionReason != null) ...[
                    const SizedBox(height: 5),
                    Text(doc.rejectionReason!,
                        style: const TextStyle(
                            color: AppColors.danger, fontSize: 11)),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                StatusBadge(_label(doc.status), color: color),
                const SizedBox(height: 7),
                const Icon(Icons.chevron_right_rounded,
                    color: AppColors.muted, size: 20),
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String _label(DocumentStatus status) => switch (status) {
        DocumentStatus.pending => 'Pendente',
        DocumentStatus.sent => 'Enviado',
        DocumentStatus.review => 'Em análise',
        DocumentStatus.approved => 'Disponível',
        DocumentStatus.rejected => 'Ajustar',
      };

  static Color _color(DocumentStatus status) => switch (status) {
        DocumentStatus.pending => AppColors.warning,
        DocumentStatus.sent => AppColors.primary,
        DocumentStatus.review => AppColors.info,
        DocumentStatus.approved => AppColors.success,
        DocumentStatus.rejected => AppColors.danger,
      };
}

String _documentDetailsRoute(
  String documentTitle, {
  String? id,
  String? originalName,
  String? documentTypeId,
  bool possiblyExpired = false,
  DateTime? expiresAt,
}) =>
    Uri(
      path: RouteNames.documentDetails,
      queryParameters: {
        'document': documentTitle,
        if (id != null) 'id': id,
        if (originalName != null) 'name': originalName,
        if (documentTypeId != null) 'type': documentTypeId,
        if (possiblyExpired) 'expired': 'true',
        if (expiresAt != null) 'expiresAt': expiresAt.toIso8601String(),
      },
    ).toString();

String _documentRequestRoute(DocumentType? type) => Uri(
      path: RouteNames.documentRequest,
      queryParameters: {
        'document': type?.name ?? 'Outro documento',
        if (type != null) 'type': type.id,
      },
    ).toString();

DocumentType? _findOtherType(List<DocumentType>? types) {
  if (types == null) return null;
  for (final type in types) {
    if (type.key == 'outro-documento') return type;
  }
  return null;
}

String _date(DateTime value) =>
    '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year}';
