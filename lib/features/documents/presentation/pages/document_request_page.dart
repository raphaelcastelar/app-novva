import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../service_requests/domain/entities/service_request_drafts.dart';
import '../../../service_requests/presentation/providers/service_request_providers.dart';
import '../providers/documents_providers.dart';

class DocumentRequestPage extends ConsumerStatefulWidget {
  const DocumentRequestPage({
    required this.documentTitle,
    super.key,
  });

  final String documentTitle;

  @override
  ConsumerState<DocumentRequestPage> createState() =>
      _DocumentRequestPageState();
}

class _DocumentRequestPageState extends ConsumerState<DocumentRequestPage> {
  final _observationController = TextEditingController();

  @override
  void dispose() {
    _observationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final submission = ref.watch(requestSubmissionProvider);
    return AppScaffold(
      title: 'Solicitar documento',
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 18, 16, 132),
        children: [
          AppCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.softAccent,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Icon(
                    Icons.post_add_rounded,
                    color: AppColors.accent,
                    size: 30,
                  ),
                ),
                const SizedBox(height: 18),
                const Text(
                  'Nova solicitação',
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 20,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Confira o documento e adicione uma observação, se precisar.',
                  style: TextStyle(color: AppColors.muted, height: 1.35),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          AppTextField(
            label: 'Documento solicitado',
            initialValue: widget.documentTitle,
            readOnly: true,
            suffixIcon: const Icon(Icons.lock_outline),
          ),
          const SizedBox(height: 12),
          AppTextField(
            label: 'Observação',
            controller: _observationController,
            maxLines: 5,
          ),
          const SizedBox(height: 18),
          AppButton(
            label: 'Enviar solicitação',
            icon: Icons.send_outlined,
            loading: submission.isLoading,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  Future<void> _submit() async {
    final state = ref.read(requestSubmissionProvider.notifier);
    state.state = const AsyncLoading();
    try {
      final created = await ref.read(submitDocumentRequestProvider)(
        DocumentRequestDraft(
          doctor: localDoctor,
          title: widget.documentTitle,
          category: 'Documentos solicitados',
          description: _observationController.text.trim(),
        ),
      );
      state.state = AsyncData(created);
      ref.read(documentRequestFeedbackProvider.notifier).state = true;
      if (mounted) context.go(RouteNames.documents);
    } catch (error, stackTrace) {
      state.state = AsyncError(error, stackTrace);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Não foi possível enviar: $error')),
        );
      }
    }
  }
}
