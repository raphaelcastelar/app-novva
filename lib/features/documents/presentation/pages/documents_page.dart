import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/document_item.dart';
import '../../domain/entities/document_type.dart';
import '../providers/documents_providers.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({this.initialDocumentId, super.key});

  final String? initialDocumentId;

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
      initialIndex: initialDocumentId == null ? 0 : 2,
      child: AppScaffold(
        title: 'Documentos',
        actions: [
          IconButton(
            tooltip: 'Atualizar documentos',
            onPressed: refreshAll,
            icon: Icon(Icons.refresh_rounded),
          ),
        ],
        floatingActionButton: FloatingActionButton.extended(
          shape: const StadiumBorder(),
          onPressed: () => context.go(
            _documentRequestRoute(_findOtherType(documentTypes.valueOrNull)),
          ),
          icon: Icon(Icons.add),
          label: Text('Nova solicitação'),
        ),
        child: documents.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _DocumentsLoadError(
            onRetry: () => refreshAll(showLoading: true),
          ),
          data: (items) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                child: _DocumentArchiveHeader(documents: items),
              ),
              const SizedBox(height: 13),
              const _DocumentTabs(),
              const SizedBox(height: 4),
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
                      child: _DocumentList(
                        documents: items,
                        documentTypes: documentTypes.valueOrNull,
                      ),
                    ),
                    RefreshIndicator(
                      onRefresh: refreshAll,
                      child: _DocumentList(
                        documents: items
                            .where(
                                (doc) => doc.status == DocumentStatus.approved)
                            .toList(),
                        documentTypes: documentTypes.valueOrNull,
                        emptyMessage: 'Nenhum documento recebido ainda.',
                        initialExpandedDocumentId: initialDocumentId,
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
                        documentTypes: documentTypes.valueOrNull,
                        emptyMessage: 'Tudo certo por aqui. Sem pendências.',
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DocumentArchiveHeader extends StatelessWidget {
  const _DocumentArchiveHeader({required this.documents});

  final List<DocumentItem> documents;

  @override
  Widget build(BuildContext context) {
    final available = documents
        .where((document) =>
            document.status == DocumentStatus.approved &&
            document.hasFile &&
            !document.possiblyExpired)
        .length;
    final inProgress = documents
        .where((document) =>
            document.status == DocumentStatus.pending ||
            document.status == DocumentStatus.sent ||
            document.status == DocumentStatus.review)
        .length;
    final expired = documents
        .where((document) =>
            document.status == DocumentStatus.approved &&
            document.possiblyExpired)
        .length;

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 18),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(17, 18, 17, 16),
          decoration: BoxDecoration(
            color: AppColors.softPrimary,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(24),
              bottomLeft: Radius.circular(24),
              bottomRight: Radius.circular(24),
              topLeft: Radius.circular(8),
            ),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.14),
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.folder_copy_outlined,
                    color: AppColors.primary,
                    size: 22,
                  ),
                  SizedBox(width: 9),
                  Expanded(
                    child: Text(
                      'Seu arquivo contábil',
                      style: TextStyle(
                        color: AppColors.primaryDark,
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Documentos da sua empresa, organizados para consultar ou solicitar.',
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
              const SizedBox(height: 13),
              Wrap(
                spacing: 15,
                runSpacing: 7,
                children: [
                  _ArchiveCount(
                    value: available,
                    label: 'disponíveis',
                    color: AppColors.success,
                  ),
                  _ArchiveCount(
                    value: inProgress,
                    label: 'em andamento',
                    color: AppColors.info,
                  ),
                  if (expired > 0)
                    _ArchiveCount(
                      value: expired,
                      label: 'para revisar',
                      color: AppColors.warning,
                    ),
                ],
              ),
            ],
          ),
        ),
        Positioned(
          left: 0,
          top: 0,
          child: Container(
            height: 28,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.softPrimary,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(13),
                topRight: Radius.circular(13),
              ),
              border: Border.all(
                color: AppColors.primary.withValues(alpha: 0.14),
              ),
            ),
            child: Text(
              'Arquivo Novva',
              style: TextStyle(
                color: AppColors.primary,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _ArchiveCount extends StatelessWidget {
  const _ArchiveCount({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            '$value $label',
            style: TextStyle(
              color: AppColors.text,
              fontSize: 11,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      );
}

class _DocumentTabs extends StatelessWidget {
  const _DocumentTabs();

  @override
  Widget build(BuildContext context) => Container(
        height: 46,
        margin: const EdgeInsets.symmetric(horizontal: 16),
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.border),
        ),
        child: TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          dividerColor: Colors.transparent,
          indicatorSize: TabBarIndicatorSize.tab,
          indicator: BoxDecoration(
            color: AppColors.primaryDark,
            borderRadius: BorderRadius.circular(12),
          ),
          labelColor: Colors.white,
          unselectedLabelColor: AppColors.muted,
          labelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w800,
          ),
          unselectedLabelStyle: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w700,
          ),
          labelPadding: const EdgeInsets.symmetric(horizontal: 13),
          tabs: const [
            Tab(text: 'Solicitar'),
            Tab(text: 'Enviados'),
            Tab(text: 'Recebidos'),
            Tab(text: 'Pendentes'),
          ],
        ),
      );
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
          Text(
            'Escolha um documento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(
            'Abra um item para baixar o arquivo ou fazer um pedido.',
            style: TextStyle(color: AppColors.muted, fontSize: 12),
          ),
          const SizedBox(height: 13),
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
            data: (types) => _DocumentTypeList(
              types: types,
              documents: documents,
            ),
          ),
        ],
      );
}

class _DocumentTypeList extends StatelessWidget {
  const _DocumentTypeList({
    required this.types,
    required this.documents,
  });
  final List<DocumentType> types;
  final List<DocumentItem> documents;

  @override
  Widget build(BuildContext context) => _DocumentIndexSurface(
        children: types
            .map(
              (type) => _ExpandableDocumentType(
                type: type,
                documents: documents,
              ),
            )
            .toList(growable: false),
      );
}

class _DocumentIndexSurface extends StatelessWidget {
  const _DocumentIndexSurface({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            for (var index = 0; index < children.length; index++) ...[
              children[index],
              if (index < children.length - 1)
                const Divider(height: 1, indent: 68),
            ],
          ],
        ),
      );
}

class _ExpandableDocumentType extends ConsumerStatefulWidget {
  const _ExpandableDocumentType({
    required this.type,
    required this.documents,
    this.initialExpandedDocumentId,
  });

  final DocumentType type;
  final List<DocumentItem> documents;
  final String? initialExpandedDocumentId;

  @override
  ConsumerState<_ExpandableDocumentType> createState() =>
      _ExpandableDocumentTypeState();
}

class _ExpandableDocumentTypeState
    extends ConsumerState<_ExpandableDocumentType> {
  late bool _expanded;
  bool _downloading = false;

  @override
  void initState() {
    super.initState();
    _expanded = _containsInitialDocument;
  }

  @override
  void didUpdateWidget(covariant _ExpandableDocumentType oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.initialExpandedDocumentId !=
            widget.initialExpandedDocumentId &&
        _containsInitialDocument) {
      _expanded = true;
    }
  }

  bool get _containsInitialDocument {
    final id = widget.initialExpandedDocumentId;
    return id != null && widget.documents.any((document) => document.id == id);
  }

  List<DocumentItem> get _matchingDocuments => widget.documents
      .where((document) =>
          document.documentTypeId == widget.type.id ||
          document.title.toLowerCase() == widget.type.name.toLowerCase())
      .toList();

  DocumentItem? get _availableDocument {
    final available = _matchingDocuments
        .where((document) =>
            document.status == DocumentStatus.approved && document.hasFile)
        .toList()
      ..sort((a, b) => (b.fileUploadedAt ?? DateTime(1970))
          .compareTo(a.fileUploadedAt ?? DateTime(1970)));
    return available.isEmpty ? null : available.first;
  }

  DocumentItem? get _latestRequest =>
      _matchingDocuments.isEmpty ? null : _matchingDocuments.first;

  @override
  Widget build(BuildContext context) {
    final available = _availableDocument;
    final latest = _latestRequest;
    final expired = available?.possiblyExpired ?? false;
    final presentation = _documentTypePresentation(
      available: available,
      latest: latest,
      expired: expired,
    );

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
      decoration: BoxDecoration(
        color: _expanded
            ? presentation.color.withValues(alpha: 0.035)
            : Colors.transparent,
      ),
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            InkWell(
              onTap: () => setState(() => _expanded = !_expanded),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 15,
                ),
                child: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: presentation.color.withValues(alpha: 0.10),
                        borderRadius: BorderRadius.circular(13),
                      ),
                      child: Icon(
                        expired
                            ? Icons.warning_amber_rounded
                            : Icons.description_outlined,
                        color: presentation.color,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.type.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            presentation.summary,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(presentation.label, color: presentation.color),
                    const SizedBox(width: 3),
                    AnimatedRotation(
                      turns: _expanded ? 0.5 : 0,
                      duration: const Duration(milliseconds: 220),
                      child: Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColors.muted,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            AnimatedCrossFade(
              duration: const Duration(milliseconds: 240),
              crossFadeState: _expanded
                  ? CrossFadeState.showSecond
                  : CrossFadeState.showFirst,
              firstChild: const SizedBox(width: double.infinity),
              secondChild: Padding(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: 13),
                    _DocumentAvailabilityPanel(
                      type: widget.type,
                      available: available,
                      latest: latest,
                      expired: expired,
                    ),
                    const SizedBox(height: 13),
                    _actions(available, expired),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _actions(DocumentItem? available, bool expired) {
    final requestButton = OutlinedButton.icon(
      onPressed: () => context.go(_documentRequestRoute(widget.type)),
      icon: Icon(Icons.post_add_rounded, size: 18),
      label: Text(
          available == null ? 'Solicitar documento' : 'Solicitar atualização'),
    );

    if (available == null) {
      return SizedBox(width: double.infinity, child: requestButton);
    }

    final downloadButton = FilledButton.icon(
      onPressed: _downloading ? null : () => _download(available),
      icon: _downloading
          ? const SizedBox.square(
              dimension: 17,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(Icons.download_rounded, size: 18),
      label: Text(_downloading ? 'Baixando...' : 'Baixar documento'),
    );

    return LayoutBuilder(builder: (context, constraints) {
      final width = (constraints.maxWidth - 8) / 2;
      return Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          SizedBox(
            width: width,
            child: expired ? requestButton : downloadButton,
          ),
          SizedBox(
            width: width,
            child: expired ? downloadButton : requestButton,
          ),
        ],
      );
    });
  }

  Future<void> _download(DocumentItem document) async {
    if (_downloading) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref
          .read(documentsRepositoryProvider)
          .downloadDocument(document.id);
      final directory = await getTemporaryDirectory();
      final safeName = (document.originalName ?? '${document.title}.pdf')
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final file = File('${directory.path}/$safeName');
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(result.message)));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível baixar o documento.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }
}

class _DocumentAvailabilityPanel extends StatelessWidget {
  const _DocumentAvailabilityPanel({
    required this.type,
    required this.available,
    required this.latest,
    required this.expired,
  });

  final DocumentType type;
  final DocumentItem? available;
  final DocumentItem? latest;
  final bool expired;

  @override
  Widget build(BuildContext context) {
    final color = expired
        ? AppColors.warning
        : available != null
            ? AppColors.success
            : AppColors.muted;
    final title = expired
        ? 'Documento possivelmente vencido'
        : available != null
            ? 'Documento disponível'
            : latest == null
                ? 'Ainda não disponível'
                : 'Solicitação em andamento';
    final description = expired
        ? 'A validade terminou${available?.expiresAt == null ? '' : ' em ${_date(available!.expiresAt!)}'}. Você ainda pode baixar o arquivo ou pedir uma versão atualizada.'
        : available != null
            ? 'Anexado${available?.fileUploadedAt == null ? '' : ' em ${_date(available!.fileUploadedAt!)}'} • ${type.validityLabel}.'
            : latest?.status == DocumentStatus.rejected
                ? latest?.rejectionReason ??
                    'A solicitação precisa de um ajuste antes de continuar.'
                : latest == null
                    ? 'Faça a solicitação para a equipe Novva disponibilizar este documento.'
                    : 'A equipe Novva está preparando este documento para você.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            expired
                ? Icons.warning_amber_rounded
                : available != null
                    ? Icons.check_circle_outline_rounded
                    : Icons.schedule_rounded,
            color: color,
            size: 21,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 3),
                Text(description,
                    style: TextStyle(
                        color: AppColors.muted, height: 1.35, fontSize: 12)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

_DocumentTypePresentation _documentTypePresentation({
  required DocumentItem? available,
  required DocumentItem? latest,
  required bool expired,
}) {
  if (expired) {
    return _DocumentTypePresentation(
      label: 'Vencido',
      summary: 'Solicite uma versão atualizada',
      color: AppColors.warning,
    );
  }
  if (available != null) {
    return _DocumentTypePresentation(
      label: 'Disponível',
      summary: 'Pronto para baixar',
      color: AppColors.success,
    );
  }
  if (latest == null) {
    return _DocumentTypePresentation(
      label: 'Pedir',
      summary: 'Ainda não solicitado',
      color: AppColors.muted,
    );
  }
  return switch (latest.status) {
    DocumentStatus.pending => _DocumentTypePresentation(
        label: 'Solicitado',
        summary: 'Aguardando atendimento',
        color: AppColors.warning,
      ),
    DocumentStatus.sent || DocumentStatus.review => _DocumentTypePresentation(
        label: 'Em análise',
        summary: 'Documento sendo preparado',
        color: AppColors.info,
      ),
    DocumentStatus.rejected => _DocumentTypePresentation(
        label: 'Ajustar',
        summary: 'Confira a orientação da equipe',
        color: AppColors.danger,
      ),
    DocumentStatus.approved => _DocumentTypePresentation(
        label: 'Pedir',
        summary: 'Arquivo ainda não anexado',
        color: AppColors.muted,
      ),
  };
}

class _DocumentTypePresentation {
  _DocumentTypePresentation({
    required this.label,
    required this.summary,
    required this.color,
  });

  final String label;
  final String summary;
  final Color color;
}

class _DocumentList extends StatelessWidget {
  const _DocumentList({
    required this.documents,
    required this.documentTypes,
    this.emptyMessage = 'Nenhum documento encontrado.',
    this.initialExpandedDocumentId,
  });

  final List<DocumentItem> documents;
  final List<DocumentType>? documentTypes;
  final String emptyMessage;
  final String? initialExpandedDocumentId;

  @override
  Widget build(BuildContext context) {
    if (documents.isEmpty) {
      final state = EmptyState(
        title: 'Tudo limpo',
        message: emptyMessage,
        icon: Icons.folder_open_outlined,
      );
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        children: [state],
      );
    }

    final entries = [
      for (final document in documents)
        _ExpandableDocumentType(
          type: _typeForDocument(document, documentTypes),
          documents: [document],
          initialExpandedDocumentId: initialExpandedDocumentId,
        ),
    ];

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      children: [_DocumentIndexSurface(children: entries)],
    );
  }
}

DocumentType _typeForDocument(
  DocumentItem document,
  List<DocumentType>? types,
) {
  if (types != null) {
    for (final type in types) {
      if (type.id == document.documentTypeId ||
          type.name.toLowerCase() == document.title.toLowerCase()) {
        return type;
      }
    }
  }

  return DocumentType(
    id: document.documentTypeId ?? document.id,
    key: document.title.toLowerCase().replaceAll(' ', '-'),
    name: document.title,
    category: document.category,
    validityMonths: document.validityMonths,
  );
}

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
