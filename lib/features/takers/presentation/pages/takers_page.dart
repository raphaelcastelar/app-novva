import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/errors/error_handler.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../domain/entities/taker.dart';
import '../providers/takers_providers.dart';
import '../widgets/taker_form_sheet.dart';

class TakersPage extends ConsumerWidget {
  const TakersPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(takersProvider);
    return AppScaffold(
      title: 'Tomadores',
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => showTakerFormSheet(context),
        icon: const Icon(Icons.add_business_outlined),
        label: const Text('Cadastrar'),
      ),
      child: state.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _LoadError(
          message: ErrorHandler.userMessage(error),
          onRetry: () => ref.read(takersProvider.notifier).load(),
        ),
        data: (items) => RefreshIndicator(
          onRefresh: () => ref.read(takersProvider.notifier).load(),
          child: items.isEmpty
              ? _EmptyTakers(onAdd: () => showTakerFormSheet(context))
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 150),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _TakerCard(
                    taker: items[index],
                    onEdit: () =>
                        showTakerFormSheet(context, taker: items[index]),
                    onDelete: () => _confirmDelete(context, ref, items[index]),
                  ),
                ),
        ),
      ),
    );
  }

  Future<void> _confirmDelete(
    BuildContext context,
    WidgetRef ref,
    Taker taker,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir tomador?'),
        content: Text(
          '${taker.name} deixará de aparecer na seleção de novas notas.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      await ref.read(takersProvider.notifier).remove(taker.id);
    } catch (error) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(ErrorHandler.userMessage(error))),
      );
    }
  }
}

class _TakerCard extends StatelessWidget {
  const _TakerCard({
    required this.taker,
    required this.onEdit,
    required this.onDelete,
  });

  final Taker taker;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) => AppCard(
        onTap: onEdit,
        child: ListTile(
          contentPadding: EdgeInsets.zero,
          leading: CircleAvatar(
            backgroundColor: AppColors.softPrimary,
            child: Icon(Icons.business_outlined, color: AppColors.primary),
          ),
          title: Text(
            taker.name,
            style: const TextStyle(fontWeight: FontWeight.w900),
          ),
          subtitle: Text(
            '${AppFormatters.cnpj(taker.cnpj)}\n${taker.municipality}',
          ),
          isThreeLine: true,
          trailing: PopupMenuButton<String>(
            onSelected: (value) => value == 'edit' ? onEdit() : onDelete(),
            itemBuilder: (_) => const [
              PopupMenuItem(value: 'edit', child: Text('Editar')),
              PopupMenuItem(value: 'delete', child: Text('Excluir')),
            ],
          ),
        ),
      );
}

class _EmptyTakers extends StatelessWidget {
  const _EmptyTakers({required this.onAdd});

  final VoidCallback onAdd;

  @override
  Widget build(BuildContext context) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 70),
          Icon(Icons.business_outlined, size: 58, color: AppColors.primary),
          const SizedBox(height: 16),
          const Text(
            'Nenhum tomador cadastrado',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),
          const Text(
            'Cadastre hospitais, clínicas e empresas para preencher suas notas mais rápido.',
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 20),
          FilledButton.icon(
            onPressed: onAdd,
            icon: const Icon(Icons.add_rounded),
            label: const Text('Cadastrar primeiro tomador'),
          ),
        ],
      );
}

class _LoadError extends StatelessWidget {
  const _LoadError({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton(
                onPressed: onRetry,
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
}
