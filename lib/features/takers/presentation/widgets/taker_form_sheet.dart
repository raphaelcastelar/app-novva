import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/utils/validators.dart';
import '../../../../core/widgets/app_button.dart';
import '../../../../core/widgets/app_text_field.dart';
import '../../domain/entities/taker.dart';
import '../providers/takers_providers.dart';

Future<Taker?> showTakerFormSheet(
  BuildContext context, {
  Taker? taker,
}) {
  return showModalBottomSheet<Taker>(
    context: context,
    useRootNavigator: true,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    builder: (_) => TakerFormSheet(taker: taker),
  );
}

class TakerFormSheet extends ConsumerStatefulWidget {
  const TakerFormSheet({this.taker, super.key});

  final Taker? taker;

  @override
  ConsumerState<TakerFormSheet> createState() => _TakerFormSheetState();
}

class _TakerFormSheetState extends ConsumerState<TakerFormSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _cnpj;
  late final TextEditingController _municipality;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.taker?.name ?? '');
    _cnpj = TextEditingController(
      text: widget.taker == null ? '' : AppFormatters.cnpj(widget.taker!.cnpj),
    );
    _municipality =
        TextEditingController(text: widget.taker?.municipality ?? '');
  }

  @override
  void dispose() {
    _name.dispose();
    _cnpj.dispose();
    _municipality.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final keyboard = MediaQuery.viewInsetsOf(context).bottom;
    final mediaQuery = MediaQuery.of(context);
    final availableHeight =
        mediaQuery.size.height - keyboard - mediaQuery.padding.top;
    return AnimatedPadding(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOutCubic,
      padding: EdgeInsets.only(bottom: keyboard),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: availableHeight.clamp(280.0, 680.0),
        ),
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.taker == null ? 'Cadastrar tomador' : 'Editar tomador',
                  style: const TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 6),
                const Text(
                  'Esses dados poderão ser reutilizados nas próximas notas.',
                ),
                const SizedBox(height: 20),
                AppTextField(
                  label: 'Nome do hospital, clínica ou empresa',
                  controller: _name,
                  validator: _required,
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'CNPJ',
                  controller: _cnpj,
                  keyboardType: TextInputType.number,
                  validator: (value) => Validators.isValidCnpj(value ?? '')
                      ? null
                      : 'Informe um CNPJ válido',
                ),
                const SizedBox(height: 12),
                AppTextField(
                  label: 'Município do serviço',
                  controller: _municipality,
                  validator: _required,
                ),
                const SizedBox(height: 20),
                AppButton(
                  label: widget.taker == null ? 'Cadastrar e usar' : 'Salvar',
                  icon: Icons.check_rounded,
                  loading: _saving,
                  onPressed: _save,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String? _required(String? value) =>
      value == null || value.trim().length < 2 ? 'Campo obrigatório' : null;

  Future<void> _save() async {
    if (!(_formKey.currentState?.validate() ?? false) || _saving) return;
    setState(() => _saving = true);
    try {
      final saved = await ref.read(takersProvider.notifier).save(
            existing: widget.taker,
            name: _name.text,
            cnpj: _cnpj.text,
            municipality: _municipality.text,
          );
      if (mounted) Navigator.of(context).pop(saved);
    } catch (error) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.userMessage(error))),
      );
    }
  }
}
