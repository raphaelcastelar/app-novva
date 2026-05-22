import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/document_item.dart';
import '../providers/documents_providers.dart';

class DocumentsPage extends ConsumerWidget {
  const DocumentsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final documents = ref.watch(documentsProvider);

    return DefaultTabController(
      length: 4,
      child: AppScaffold(
        title: 'Documentos',
        actions: [
          IconButton(
            tooltip: 'Enviar documento',
            onPressed: () => context.go(RouteNames.documentUpload),
            icon: const Icon(Icons.upload_file_outlined),
          ),
        ],
        floatingActionButton: FloatingActionButton.extended(
          onPressed: () => context.go(RouteNames.documentUpload),
          icon: const Icon(Icons.add),
          label: const Text('Nova solicitação'),
        ),
        child: Stack(
          children: [
            const Positioned.fill(child: _DocumentsWatermark()),
            Column(
              children: [
                const Padding(
                  padding: EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: _DocumentSummary(),
                ),
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
                      _DocumentRequestTab(documents: documents),
                      _DocumentList(documents: documents),
                      _DocumentList(
                        documents: documents
                            .where(
                                (doc) => doc.status == DocumentStatus.approved)
                            .toList(),
                        emptyMessage: 'Nenhum documento recebido ainda.',
                      ),
                      _DocumentList(
                        documents: documents
                            .where((doc) =>
                                doc.status == DocumentStatus.pending ||
                                doc.status == DocumentStatus.rejected)
                            .toList(),
                        emptyMessage: 'Tudo certo por aqui. Sem pendências.',
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DocumentsWatermark extends StatelessWidget {
  const _DocumentsWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
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
}

class _DocumentSummary extends StatelessWidget {
  const _DocumentSummary();

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          Text(
            'Central de documentos',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          SizedBox(height: 4),
          Text(
            'Solicite, envie e acompanhe documentos sem perder o histórico.',
            style: TextStyle(color: AppColors.muted, height: 1.35),
          ),
          SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _FilterChip(label: 'Maio/2026'),
              _FilterChip(label: 'Pendentes'),
              _FilterChip(label: 'Imposto de renda'),
              _FilterChip(label: 'Guias pagas'),
            ],
          ),
        ],
      ),
    );
  }
}

class _DocumentRequestTab extends StatelessWidget {
  const _DocumentRequestTab({required this.documents});

  final List<DocumentItem> documents;

  @override
  Widget build(BuildContext context) {
    const categories = [
      ('Cópia do CNPJ', 'CNPJ', Icons.business_outlined),
      ('Certidão de regularidade', 'Fiscal', Icons.verified_outlined),
      ('Contrato social', 'Empresa', Icons.article_outlined),
      ('Alteração contratual', 'Empresa', Icons.edit_document),
      ('Declaração de Imposto de Renda', 'IRPF', Icons.assignment_ind_outlined),
      ('Comprovante de endereço', 'Cadastro', Icons.home_work_outlined),
      (
        'Registro na Junta Comercial',
        'Empresa',
        Icons.account_balance_outlined
      ),
      ('Alvará de funcionamento', 'Clínica', Icons.local_hospital_outlined),
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final columns = constraints.maxWidth >= 720 ? 3 : 2;
            return GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: categories.length,
              gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: columns,
                mainAxisSpacing: 10,
                crossAxisSpacing: 10,
                childAspectRatio: columns == 3 ? 1.4 : 1.05,
              ),
              itemBuilder: (_, index) {
                final item = categories[index];
                return ActionTile(
                  title: item.$1,
                  subtitle: item.$2,
                  icon: item.$3,
                  onTap: () => context.go(RouteNames.documentDetails),
                );
              },
            );
          },
        ),
        const SizedBox(height: 18),
        const Text(
          'Acompanhamento recente',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 10),
        _DocumentList(documents: documents, shrink: true),
      ],
    );
  }
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
      return EmptyState(
        title: 'Tudo limpo',
        message: emptyMessage,
        icon: Icons.folder_open_outlined,
      );
    }

    return ListView.separated(
      shrinkWrap: shrink,
      physics: shrink ? const NeverScrollableScrollPhysics() : null,
      padding: shrink ? EdgeInsets.zero : const EdgeInsets.all(16),
      itemCount: documents.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (_, index) {
        final doc = documents[index];
        return _DocumentCard(doc: doc);
      },
    );
  }
}

class _DocumentCard extends StatelessWidget {
  const _DocumentCard({required this.doc});

  final DocumentItem doc;

  @override
  Widget build(BuildContext context) {
    final color = _color(doc.status);
    return AppCard(
      onTap: () => context.go(RouteNames.documentDetails),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.11),
                  borderRadius: BorderRadius.circular(15),
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
                    const SizedBox(height: 2),
                    Text(
                      '${doc.category} • ${doc.month}/${doc.year}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: AppColors.muted),
                    ),
                  ],
                ),
              ),
              StatusBadge(_label(doc.status), color: color),
            ],
          ),
          const SizedBox(height: 14),
          TimelineStatus(
            steps: const ['Solicitado', 'Em análise', 'Disponível'],
            currentStep: _timelineStep(doc.status),
          ),
          if (doc.rejectionReason != null) ...[
            const SizedBox(height: 12),
            Text(
              doc.rejectionReason!,
              style: const TextStyle(color: AppColors.danger, height: 1.35),
            ),
          ],
        ],
      ),
    );
  }

  static int _timelineStep(DocumentStatus status) => switch (status) {
        DocumentStatus.pending => 0,
        DocumentStatus.sent || DocumentStatus.review => 1,
        DocumentStatus.approved => 2,
        DocumentStatus.rejected => 1,
      };

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

class _FilterChip extends StatelessWidget {
  const _FilterChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      backgroundColor: AppColors.softPrimary,
      side: BorderSide.none,
      labelStyle: const TextStyle(
        color: AppColors.primary,
        fontWeight: FontWeight.w700,
      ),
    );
  }
}
