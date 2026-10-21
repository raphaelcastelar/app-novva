import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../../service_requests/domain/entities/service_request_drafts.dart';
import '../../../service_requests/presentation/providers/service_request_providers.dart';

class InvoiceDescriptionPage extends ConsumerStatefulWidget {
  const InvoiceDescriptionPage({super.key});

  @override
  ConsumerState<InvoiceDescriptionPage> createState() =>
      _InvoiceDescriptionPageState();
}

class _InvoiceDescriptionPageState
    extends ConsumerState<InvoiceDescriptionPage> {
  static const _suggestions = [
    'Serviços médicos prestados conforme contrato.',
    'Atendimento médico especializado.',
    'Plantão médico realizado no período informado.',
    'Serviços de saúde prestados à instituição contratante.',
  ];

  late final TextEditingController _description;

  @override
  void initState() {
    super.initState();
    _description = TextEditingController(
      text: ref.read(pendingInvoiceDraftProvider)?.description ?? '',
    );
  }

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final draft = ref.watch(pendingInvoiceDraftProvider);
    final submission = ref.watch(requestSubmissionProvider);
    final savingDraft = ref.watch(invoiceDraftSavingProvider);
    final favorites = ref.watch(invoiceDescriptionFavoritesProvider);
    final favoriteDescriptions =
        favorites.valueOrNull?.map((item) => item.description).toSet() ??
            const <String>{};
    final suggestions = [
      ..._suggestions.where(favoriteDescriptions.contains),
      ..._suggestions.where((item) => !favoriteDescriptions.contains(item)),
    ];

    return AppScaffold(
      title: 'Descrição da NFS-e',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 122),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Etapa 2 de 4',
                  style: TextStyle(
                    color: AppColors.muted,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Descrição do serviço',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                SizedBox(height: 14),
                TimelineStatus(
                  steps: const ['Dados', 'Descrição', 'Revisão', 'Status'],
                  currentStep: 1,
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          AppTextField(
            label: 'Descrição manual',
            controller: _description,
            maxLines: 6,
          ),
          const SizedBox(height: 16),
          Text(
            'Sugestões inteligentes',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final suggestion in suggestions) ...[
            AppCard(
              onTap: () => _useSuggestion(suggestion),
              child: Row(
                children: [
                  Icon(Icons.auto_awesome_outlined, color: AppColors.accent),
                  const SizedBox(width: 12),
                  Expanded(child: Text(suggestion)),
                  IconButton(
                    tooltip: favoriteDescriptions.contains(suggestion)
                        ? 'Remover dos favoritos'
                        : 'Adicionar aos favoritos',
                    onPressed: favorites.isLoading
                        ? null
                        : () => _toggleFavorite(suggestion),
                    icon: Icon(
                      favoriteDescriptions.contains(suggestion)
                          ? Icons.star_rounded
                          : Icons.star_border_rounded,
                      color: favoriteDescriptions.contains(suggestion)
                          ? AppColors.warning
                          : AppColors.muted,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),
          ],
          const SizedBox(height: 4),
          _ReviewCard(draft: draft),
          const SizedBox(height: 18),
          AppButton(
            label: 'Confirmar solicitação',
            icon: Icons.send_outlined,
            loading: submission.isLoading,
            onPressed: draft == null ? null : _submit,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            onPressed:
                draft == null || savingDraft.isLoading ? null : _saveDraft,
            icon: savingDraft.isLoading
                ? const SizedBox.square(
                    dimension: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.drafts_outlined),
            label: Text(
              savingDraft.isLoading ? 'Salvando...' : 'Salvar rascunho',
            ),
          ),
        ],
      ),
    );
  }

  void _useSuggestion(String suggestion) {
    _description
      ..text = suggestion
      ..selection = TextSelection.collapsed(offset: suggestion.length);
  }

  Future<void> _toggleFavorite(String suggestion) async {
    try {
      await ref
          .read(invoiceDescriptionFavoritesProvider.notifier)
          .toggle(suggestion);
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.userMessage(error))),
      );
    }
  }

  Future<void> _saveDraft() async {
    final draft = ref.read(pendingInvoiceDraftProvider);
    if (draft == null) return;
    final saving = ref.read(invoiceDraftSavingProvider.notifier);
    saving.state = const AsyncLoading();
    final updated = draft.copyWith(description: _description.text.trim());
    try {
      await ref
          .read(serviceRequestRepositoryProvider)
          .saveInvoiceDraft(updated);
      ref.read(pendingInvoiceDraftProvider.notifier).state = updated;
      saving.state = const AsyncData(null);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Rascunho salvo com sucesso.')),
      );
    } catch (error, stackTrace) {
      saving.state = AsyncError(error, stackTrace);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.userMessage(error))),
      );
    }
  }

  Future<void> _submit() async {
    final draft = ref.read(pendingInvoiceDraftProvider);
    if (draft == null) return;
    final state = ref.read(requestSubmissionProvider.notifier);
    state.state = const AsyncLoading();
    try {
      final created = await ref.read(submitInvoiceRequestProvider)(
        draft.copyWith(description: _description.text.trim()),
      );
      state.state = AsyncData(created);
      ref.read(pendingInvoiceDraftProvider.notifier).state = null;
      if (mounted) _showSuccess(context, created.id);
    } catch (error, stackTrace) {
      state.state = AsyncError(error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(ErrorHandler.userMessage(error))),
        );
      }
    }
  }

  void _showSuccess(BuildContext context, String protocol) {
    final pageContext = context;
    showModalBottomSheet<void>(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      useSafeArea: true,
      backgroundColor: AppColors.surface,
      builder: (context) {
        return SingleChildScrollView(
          child: Padding(
            padding: EdgeInsets.fromLTRB(
              20,
              8,
              20,
              MediaQuery.paddingOf(context).bottom + 24,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const StatusBadge('Solicitação enviada',
                    color: AppColors.success),
                const SizedBox(height: 12),
                Text(
                  'Sua NFS-e foi enviada para a contabilidade.',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                ),
                const SizedBox(height: 6),
                Text(
                  'Protocolo: $protocol',
                  style: TextStyle(
                    color: AppColors.accent,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Você poderá acompanhar o andamento e baixar a nota quando ela estiver disponível.',
                  style: TextStyle(color: AppColors.muted, height: 1.35),
                ),
                const SizedBox(height: 18),
                const _CompactSuccessTimeline(),
                const SizedBox(height: 18),
                AppButton(
                  label: 'Voltar ao início',
                  onPressed: () {
                    Navigator.of(context).pop();
                    ref.read(pendingInvoiceDraftProvider.notifier).state = null;
                    pageContext.go(RouteNames.dashboard);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

class _CompactSuccessTimeline extends StatelessWidget {
  const _CompactSuccessTimeline();

  static const _steps = ['Solicitada', 'Em análise', 'Emitida', 'Enviada'];

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: LayoutBuilder(
        builder: (context, constraints) {
          final stepWidth = constraints.maxWidth / _steps.length;
          return Stack(
            children: [
              Positioned(
                top: 12,
                left: stepWidth / 2,
                right: stepWidth / 2,
                child: Container(
                  height: 2,
                  color: AppColors.border,
                ),
              ),
              Positioned(
                top: 12,
                left: stepWidth / 2,
                right: constraints.maxWidth - stepWidth / 2,
                child: Container(
                  height: 2,
                  color: AppColors.accent,
                ),
              ),
              Row(
                children: [
                  for (var index = 0; index < _steps.length; index++)
                    SizedBox(
                      width: stepWidth,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              color: index == 0
                                  ? AppColors.accent
                                  : AppColors.border,
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              index == 0 ? Icons.check : Icons.circle,
                              color: Colors.white,
                              size: index == 0 ? 14 : 6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            _steps[index],
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppColors.muted,
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              height: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.draft});

  final InvoiceRequestDraft? draft;

  @override
  Widget build(BuildContext context) {
    final rows = [
      ('Emissor', 'Conta autenticada'),
      ('Município', draft?.municipality ?? '-'),
      ('Tomador', draft?.takerName ?? '-'),
      (
        'Valor',
        'R\$ ${draft?.amount.toStringAsFixed(2).replaceAll('.', ',') ?? '-'}'
      ),
      ('Tributação', draft?.taxationCode ?? '-'),
    ];
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revisão rápida',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 10),
          for (final row in rows) ...[
            Row(
              children: [
                Expanded(
                  child: Text(
                    row.$1,
                    style: TextStyle(color: AppColors.muted),
                  ),
                ),
                Flexible(
                  child: Text(
                    row.$2,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(fontWeight: FontWeight.w800),
                  ),
                ),
              ],
            ),
            if (row != rows.last) const Divider(height: 22),
          ],
        ],
      ),
    );
  }
}
