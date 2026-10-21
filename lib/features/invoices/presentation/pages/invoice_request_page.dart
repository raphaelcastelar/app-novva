import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/config/app_constants.dart';
import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../../../core/widgets/premium_components.dart';
import '../../../service_requests/domain/entities/service_request_drafts.dart';
import '../../../service_requests/presentation/providers/service_request_providers.dart';
import '../../../takers/domain/entities/taker.dart';
import '../../../takers/presentation/providers/takers_providers.dart';
import '../../../takers/presentation/widgets/taker_form_sheet.dart';

class InvoiceRequestPage extends ConsumerStatefulWidget {
  const InvoiceRequestPage({super.key});

  @override
  ConsumerState<InvoiceRequestPage> createState() => _InvoiceRequestPageState();
}

class _InvoiceRequestPageState extends ConsumerState<InvoiceRequestPage> {
  final _formKey = GlobalKey<FormState>();
  final _municipality = TextEditingController();
  final _takerName = TextEditingController();
  final _takerCnpj = TextEditingController();
  late final TextEditingController _date;
  late DateTime _selectedDate;
  final _amount = TextEditingController();
  final _service = TextEditingController(text: 'Serviços médicos');
  String? _selectedTakerId;
  bool _restoredDraft = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateUtils.dateOnly(DateTime.now());
    _date = TextEditingController(text: _formatDate(_selectedDate));
    WidgetsBinding.instance.addPostFrameCallback((_) => _restoreDraft());
  }

  @override
  void dispose() {
    for (final controller in [
      _municipality,
      _takerName,
      _takerCnpj,
      _date,
      _amount,
      _service
    ]) {
      controller.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final takers = ref.watch(takersProvider);
    return AppScaffold(
      title: 'Nova NFS-e',
      child: Stack(
        children: [
          const Positioned.fill(child: _InvoicesWatermark()),
          ListView(
            padding: const EdgeInsets.all(16),
            children: [
              const _StepHeader(current: 1),
              if (_restoredDraft) ...[
                const SizedBox(height: 14),
                const AppCard(
                  child: Row(
                    children: [
                      Icon(Icons.drafts_outlined),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'Seu último rascunho foi restaurado.',
                          style: TextStyle(fontWeight: FontWeight.w800),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 14),
              AppCard(
                child: Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      _TakerSelector(
                        state: takers,
                        selectedId: _selectedTakerId,
                        onSelected: _selectTaker,
                        onAdd: _addTaker,
                        onRetry: () => ref.read(takersProvider.notifier).load(),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Município do serviço',
                        controller: _municipality,
                        validator: _required,
                        suffixIcon: _TipButton(
                          tooltip: 'Dica sobre o município',
                          onPressed: () => _showFieldTip(
                            title: 'Qual município informar?',
                            message:
                                'O município salvo no tomador já foi preenchido. Altere somente se o serviço desta nota ocorreu em outro município.',
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Data do serviço',
                        controller: _date,
                        validator: _required,
                        readOnly: true,
                        onTap: _selectDate,
                        suffixIcon: IconButton(
                          tooltip: 'Selecionar data',
                          onPressed: _selectDate,
                          icon: Icon(Icons.calendar_today_outlined),
                        ),
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                          label: 'Valor',
                          controller: _amount,
                          keyboardType: const TextInputType.numberWithOptions(
                              decimal: true),
                          validator: _required),
                      const SizedBox(height: 12),
                      const AppTextField(
                        label: 'Código de tributação',
                        initialValue: AppConstants.defaultTaxCode,
                        readOnly: true,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                          label: 'Serviço prestado',
                          controller: _service,
                          validator: _required),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              const InsightCard(
                title: 'Dica Novva',
                description:
                    'Use o nome do hospital ou clínica no tomador para facilitar seus relatórios de faturamento.',
                icon: Icons.lightbulb_outline,
              ),
              const SizedBox(height: 18),
              AppButton(
                label: 'Continuar para descrição',
                icon: Icons.arrow_forward,
                onPressed: _continue,
              ),
            ],
          ),
        ],
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().isEmpty ? 'Campo obrigatório' : null;

  void _selectTaker(Taker? taker) {
    if (taker == null) return;
    setState(() {
      _selectedTakerId = taker.id;
      _takerName.text = taker.name;
      _takerCnpj.text = taker.cnpj;
      _municipality.text = taker.municipality;
    });
  }

  Future<void> _addTaker() async {
    final taker = await showTakerFormSheet(context);
    if (taker != null && mounted) _selectTaker(taker);
  }

  Future<void> _restoreDraft() async {
    try {
      final draft = ref.read(pendingInvoiceDraftProvider) ??
          await ref.read(serviceRequestRepositoryProvider).fetchInvoiceDraft();
      if (draft == null || !mounted) return;
      await ref.read(takersProvider.notifier).load();
      if (!mounted) return;
      final takers = ref.read(takersProvider).valueOrNull ?? const <Taker>[];
      Taker? selected;
      for (final taker in takers) {
        if (taker.cnpj == draft.takerCnpj) {
          selected = taker;
          break;
        }
      }
      setState(() {
        _restoredDraft = true;
        _selectedTakerId = selected?.id;
        _takerName.text = draft.takerName;
        _takerCnpj.text = draft.takerCnpj;
        _municipality.text = draft.municipality;
        _selectedDate = DateUtils.dateOnly(draft.serviceDate);
        _date.text = _formatDate(_selectedDate);
        _amount.text = draft.amount.toStringAsFixed(2).replaceAll('.', ',');
        _service.text = draft.description;
      });
      ref.read(pendingInvoiceDraftProvider.notifier).state = draft;
    } catch (_) {
      // The invoice form remains available even if there is no saved draft.
    }
  }

  String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }

  Future<void> _selectDate() async {
    final selected = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(DateTime.now().year + 2, 12, 31),
      helpText: 'Selecione a data do serviço',
      cancelText: 'Cancelar',
      confirmText: 'Selecionar',
    );
    if (selected == null || !mounted) return;
    setState(() {
      _selectedDate = DateUtils.dateOnly(selected);
      _date.text = _formatDate(_selectedDate);
    });
  }

  Future<void> _showFieldTip({
    required String title,
    required String message,
  }) {
    return showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 4, 24, 28),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.lightbulb_outline, color: AppColors.warning),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Text(message, style: TextStyle(height: 1.5)),
            ],
          ),
        ),
      ),
    );
  }

  void _continue() {
    if (_selectedTakerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Selecione ou cadastre um tomador.')),
      );
      return;
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;
    final amount =
        double.tryParse(_amount.text.replaceAll('.', '').replaceAll(',', '.'));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Confira a data e o valor informados.')),
      );
      return;
    }
    ref.read(pendingInvoiceDraftProvider.notifier).state = InvoiceRequestDraft(
      takerCnpj: _takerCnpj.text,
      takerName: _takerName.text.trim(),
      municipality: _municipality.text.trim(),
      serviceDate: _selectedDate,
      amount: amount,
      taxationCode: AppConstants.defaultTaxCode,
      description: _service.text.trim(),
    );
    context.go(RouteNames.invoiceDescription);
  }
}

class _TakerSelector extends StatelessWidget {
  const _TakerSelector({
    required this.state,
    required this.selectedId,
    required this.onSelected,
    required this.onAdd,
    required this.onRetry,
  });

  final AsyncValue<List<Taker>> state;
  final String? selectedId;
  final ValueChanged<Taker?> onSelected;
  final VoidCallback onAdd;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => state.when(
        loading: () => const Padding(
          padding: EdgeInsets.symmetric(vertical: 20),
          child: Center(child: CircularProgressIndicator()),
        ),
        error: (error, _) => Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.softAccent,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            children: [
              Text(
                ErrorHandler.userMessage(error),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
        data: (items) {
          if (items.isEmpty) {
            return _EmptyTakerPrompt(onAdd: onAdd);
          }

          final validSelection =
              items.any((item) => item.id == selectedId) ? selectedId : null;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                key: ValueKey(validSelection),
                initialValue: validSelection,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Tomador'),
                hint: const Text('Selecione o tomador da nota'),
                validator: (value) =>
                    value == null ? 'Selecione um tomador' : null,
                items: [
                  for (final item in items)
                    DropdownMenuItem(
                      value: item.id,
                      child: Text(
                        '${item.name} · ${AppFormatters.cnpj(item.cnpj)}',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                onChanged: (id) => onSelected(
                  items.where((item) => item.id == id).firstOrNull,
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton.icon(
                  onPressed: onAdd,
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Novo tomador'),
                ),
              ),
            ],
          );
        },
      );
}

class _EmptyTakerPrompt extends StatelessWidget {
  const _EmptyTakerPrompt({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
        builder: (context, constraints) {
          final veryNarrow = constraints.maxWidth < 280;
          final message = Column(
            crossAxisAlignment: veryNarrow
                ? CrossAxisAlignment.center
                : CrossAxisAlignment.start,
            children: [
              const Text(
                'Nenhum tomador cadastrado',
                textAlign: TextAlign.start,
                style: TextStyle(fontWeight: FontWeight.w900, height: 1.2),
              ),
              const SizedBox(height: 4),
              Text(
                'Cadastre agora e reutilize nas próximas notas.',
                textAlign: veryNarrow ? TextAlign.center : TextAlign.start,
                style: TextStyle(
                  color: AppColors.muted,
                  fontSize: 13,
                  height: 1.35,
                ),
              ),
            ],
          );

          return Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.softPrimary,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (veryNarrow) ...[
                  Align(
                    child: _TakerPromptIcon(),
                  ),
                  const SizedBox(height: 10),
                  message,
                ] else
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const _TakerPromptIcon(),
                      const SizedBox(width: 12),
                      Expanded(child: message),
                    ],
                  ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_rounded, size: 19),
                    label: const Text(
                      'Cadastrar tomador',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      );
}

class _TakerPromptIcon extends StatelessWidget {
  const _TakerPromptIcon();

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(13),
        ),
        child: Icon(
          Icons.business_outlined,
          color: AppColors.primary,
          size: 23,
        ),
      );
}

class _TipButton extends StatelessWidget {
  const _TipButton({required this.tooltip, required this.onPressed});

  final String tooltip;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: tooltip,
      onPressed: onPressed,
      color: AppColors.warning,
      icon: Icon(Icons.lightbulb_outline),
    );
  }
}

class _InvoicesWatermark extends StatelessWidget {
  const _InvoicesWatermark();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Align(
        alignment: const Alignment(-0.68, 0.38),
        child: Opacity(
          opacity: 0.045,
          child: Transform.rotate(
            angle: 0.16,
            child: Image.asset(
              'assets/images/logo.png',
              width: MediaQuery.sizeOf(context).width * 1.1,
              fit: BoxFit.contain,
            ),
          ),
        ),
      ),
    );
  }
}

class _StepHeader extends StatelessWidget {
  const _StepHeader({required this.current});

  final int current;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Etapa 1 de 4',
            style:
                TextStyle(color: AppColors.muted, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Dados da nota',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 14),
          TimelineStatus(
            steps: const ['Dados', 'Descrição', 'Revisão', 'Status'],
            currentStep: current - 1,
          ),
        ],
      ),
    );
  }
}
