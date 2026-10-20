import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/status_badge.dart';
import '../../domain/entities/obligation.dart';
import '../providers/obligations_providers.dart';

class ObligationsPage extends ConsumerWidget {
  const ObligationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final obligations = ref.watch(obligationListProvider);
    return AppScaffold(
      title: 'Guias',
      child: obligations.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => ErrorState(
          message: 'Não foi possível carregar suas guias.',
          onRetry: () => ref.invalidate(obligationListProvider),
        ),
        data: (items) => _GuidesTimeline(
          items: items,
          onRefresh: () => ref.refresh(obligationListProvider.future),
        ),
      ),
    );
  }
}

class _GuidesTimeline extends StatefulWidget {
  const _GuidesTimeline({required this.items, required this.onRefresh});

  final List<Obligation> items;
  final Future<void> Function() onRefresh;

  @override
  State<_GuidesTimeline> createState() => _GuidesTimelineState();
}

class _GuidesTimelineState extends State<_GuidesTimeline>
    with WidgetsBindingObserver {
  late int _selectedYear;
  late int _currentCalendarYear;

  @override
  void initState() {
    super.initState();
    _currentCalendarYear = DateTime.now().year;
    _selectedYear = _currentCalendarYear;
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state != AppLifecycleState.resumed) return;
    final yearNow = DateTime.now().year;
    if (yearNow == _currentCalendarYear) return;
    setState(() {
      _currentCalendarYear = yearNow;
      _selectedYear = yearNow;
    });
  }

  List<int> get _availableYears {
    final currentYear = DateTime.now().year;
    final years = widget.items.map((item) => item.referenceYear).toSet()
      ..addAll(List.generate(5, (index) => currentYear - index));
    return years.toList()..sort((a, b) => b.compareTo(a));
  }

  List<int> get _orderedMonths {
    final now = DateTime.now();
    if (_selectedYear != now.year) {
      return List.generate(12, (index) => 12 - index);
    }
    return [
      for (var month = now.month; month >= 1; month--) month,
      for (var month = now.month + 1; month <= 12; month++) month,
    ];
  }

  @override
  Widget build(BuildContext context) {
    final yearItems = widget.items
        .where((item) => item.referenceYear == _selectedYear)
        .toList()
      ..sort((a, b) => b.dueDate.compareTo(a.dueDate));
    final availableMonths =
        yearItems.map((item) => item.referenceMonth).toSet();
    final monthsWithFile = yearItems
        .where((item) => item.hasFile)
        .map((item) => item.referenceMonth)
        .toSet();
    final now = DateTime.now();
    final showsCurrentMonth = _selectedYear == now.year;
    final otherMonths = _orderedMonths
        .where((month) => !showsCurrentMonth || month != now.month)
        .toList();

    List<Obligation> itemsForMonth(int month) => yearItems
        .where((item) => item.referenceMonth == month)
        .toList(growable: false);

    return RefreshIndicator(
      onRefresh: widget.onRefresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 132),
        children: [
          _GuidesHero(
            year: _selectedYear,
            years: _availableYears,
            registeredCount: availableMonths.length,
            downloadCount: monthsWithFile.length,
            onYearSelected: (year) => setState(() => _selectedYear = year),
          ),
          const SizedBox(height: 24),
          if (showsCurrentMonth) ...[
            const _GuidesSectionHeading(
              eyebrow: 'AGORA',
              title: 'Mês atual',
              description: 'Acompanhe vencimentos e acesse suas guias.',
            ),
            const SizedBox(height: 12),
            _MonthGuideCard(
              key: ValueKey('$_selectedYear-${now.month}'),
              month: now.month,
              year: _selectedYear,
              items: itemsForMonth(now.month),
            ),
            const SizedBox(height: 26),
          ],
          _GuidesSectionHeading(
            eyebrow: showsCurrentMonth ? 'HISTÓRICO' : 'ANO SELECIONADO',
            title: showsCurrentMonth
                ? 'Outras competências'
                : 'Competências de $_selectedYear',
            description: 'Toque em um mês para ver detalhes e ações.',
          ),
          const SizedBox(height: 12),
          DecoratedBox(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                for (var index = 0; index < otherMonths.length; index++) ...[
                  _MonthGuideCard(
                    key: ValueKey('$_selectedYear-${otherMonths[index]}'),
                    month: otherMonths[index],
                    year: _selectedYear,
                    items: itemsForMonth(otherMonths[index]),
                    grouped: true,
                  ),
                  if (index < otherMonths.length - 1)
                    const Divider(height: 1, indent: 64),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _GuidesSectionHeading extends StatelessWidget {
  const _GuidesSectionHeading({
    required this.eyebrow,
    required this.title,
    required this.description,
  });

  final String eyebrow;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            eyebrow,
            style: TextStyle(
              color: AppColors.accent,
              fontSize: 10,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.15,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            title,
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 3),
          Text(description, style: TextStyle(color: AppColors.muted)),
        ],
      );
}

class _GuidesHero extends StatelessWidget {
  const _GuidesHero({
    required this.year,
    required this.years,
    required this.registeredCount,
    required this.downloadCount,
    required this.onYearSelected,
  });

  final int year;
  final List<int> years;
  final int registeredCount;
  final int downloadCount;
  final ValueChanged<int> onYearSelected;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          children: [
            Row(
              children: [
                const _GuidesHeroIcon(),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Central de guias',
                        style: TextStyle(
                          color: AppColors.text,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      SizedBox(height: 2),
                      Text(
                        'Resumo das competências do ano',
                        style: TextStyle(
                          color: AppColors.muted,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton<int>(
                  initialValue: year,
                  tooltip: 'Selecionar ano',
                  onSelected: onYearSelected,
                  itemBuilder: (_) => [
                    for (final option in years)
                      PopupMenuItem(value: option, child: Text('$option')),
                  ],
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.softPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '$year',
                          style: TextStyle(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.primary,
                          size: 18,
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 15),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _YearSummary(
                      value: '$downloadCount',
                      label: 'geradas',
                      icon: Icons.file_download_done_rounded,
                      color: AppColors.success,
                    ),
                  ),
                  Container(width: 1, height: 32, color: AppColors.border),
                  Expanded(
                    child: _YearSummary(
                      value: '$registeredCount',
                      label: 'competências',
                      icon: Icons.calendar_month_rounded,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
}

class _GuidesHeroIcon extends StatelessWidget {
  const _GuidesHeroIcon();

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          gradient: AppColors.premiumGradient,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          Icons.receipt_long_rounded,
          color: Colors.white,
          size: 22,
        ),
      );
}

class _YearSummary extends StatelessWidget {
  const _YearSummary({
    required this.value,
    required this.label,
    required this.icon,
    required this.color,
  });

  final String value;
  final String label;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: TextStyle(
                    color: AppColors.text,
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 10,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
}

class _MonthGuideCard extends ConsumerStatefulWidget {
  const _MonthGuideCard({
    required this.month,
    required this.year,
    required this.items,
    this.grouped = false,
    super.key,
  });

  final int month;
  final int year;
  final List<Obligation> items;
  final bool grouped;

  @override
  ConsumerState<_MonthGuideCard> createState() => _MonthGuideCardState();
}

class _MonthGuideCardState extends ConsumerState<_MonthGuideCard> {
  bool _downloading = false;
  bool _generating = false;
  bool _recalculating = false;
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = _isCurrentMonth;
  }

  List<Obligation> get _downloadable =>
      widget.items.where((item) => item.hasFile).toList();

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return now.year == widget.year && now.month == widget.month;
  }

  bool get _isOpen => _isCurrentMonth || _expanded;

  @override
  Widget build(BuildContext context) {
    final presentation = _monthPresentation(widget.items);
    final total = widget.items.fold<double>(
      0,
      (sum, item) => sum + item.amount,
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        color:
            widget.grouped && !_isOpen ? Colors.transparent : AppColors.surface,
        borderRadius: BorderRadius.circular(widget.grouped ? 18 : 24),
        border: Border.all(
          color: _isCurrentMonth
              ? AppColors.accent
              : widget.grouped && !_isOpen
                  ? Colors.transparent
                  : presentation.color.withValues(alpha: 0.24),
          width: _isCurrentMonth ? 1.5 : 1,
        ),
        boxShadow: _isCurrentMonth
            ? [
                BoxShadow(
                  color: AppColors.shadow,
                  blurRadius: 22,
                  offset: Offset(0, 10),
                ),
              ]
            : null,
      ),
      child: AnimatedSize(
        duration: const Duration(milliseconds: 240),
        curve: Curves.easeOutCubic,
        alignment: Alignment.topCenter,
        child: Padding(
          padding: EdgeInsets.all(_isOpen ? 16 : 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: _isCurrentMonth
                    ? null
                    : () => setState(() => _expanded = !_expanded),
                child: Row(
                  crossAxisAlignment: _isOpen
                      ? CrossAxisAlignment.start
                      : CrossAxisAlignment.center,
                  children: [
                    _MonthBadge(
                      month: widget.month,
                      color: presentation.color,
                      compact: !_isOpen,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  _monthLabel(widget.month),
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                              ),
                              if (_isCurrentMonth) ...[
                                const SizedBox(width: 7),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 7,
                                    vertical: 3,
                                  ),
                                  decoration: BoxDecoration(
                                    color: AppColors.softAccent,
                                    borderRadius: BorderRadius.circular(999),
                                  ),
                                  child: Text(
                                    'MÊS ATUAL',
                                    style: TextStyle(
                                      color: AppColors.accent,
                                      fontSize: 9,
                                      fontWeight: FontWeight.w900,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          if (_isOpen) ...[
                            const SizedBox(height: 5),
                            Text(
                              presentation.description,
                              style: TextStyle(
                                color: AppColors.muted,
                                height: 1.3,
                              ),
                            ),
                          ] else ...[
                            const SizedBox(height: 3),
                            Text(
                              widget.items.isEmpty
                                  ? 'Nenhuma guia disponível'
                                  : '${widget.items.length} ${widget.items.length == 1 ? 'guia' : 'guias'} • ${AppFormatters.money(total)}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: AppColors.muted,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    StatusBadge(presentation.label, color: presentation.color),
                    if (!_isCurrentMonth) ...[
                      const SizedBox(width: 2),
                      AnimatedRotation(
                        turns: _expanded ? 0.5 : 0,
                        duration: const Duration(milliseconds: 220),
                        child: Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColors.muted,
                          size: 21,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              if (_isOpen) ...[
                const SizedBox(height: 14),
                if (widget.items.isEmpty)
                  const _WaitingGuidePanel()
                else ...[
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 11,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.background,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.account_balance_wallet_outlined,
                          color: AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            total > 0
                                ? 'Total da competência'
                                : 'Valor disponível na guia',
                            style: TextStyle(
                              color: AppColors.muted,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                        if (total > 0)
                          Text(
                            AppFormatters.money(total),
                            style: TextStyle(fontWeight: FontWeight.w900),
                          )
                        else
                          Icon(
                            Icons.picture_as_pdf_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                  for (var index = 0; index < widget.items.length; index++) ...[
                    _GuideEntry(widget.items[index]),
                    if (index < widget.items.length - 1)
                      const Divider(height: 22),
                  ],
                ],
                const SizedBox(height: 16),
                LayoutBuilder(
                  builder: (context, constraints) {
                    final buttonWidth = (constraints.maxWidth - 8) / 2;
                    return Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        SizedBox(
                          width: buttonWidth,
                          child: FilledButton.icon(
                            onPressed:
                                _generating || _downloading || _recalculating
                                    ? null
                                    : _downloadable.isEmpty
                                        ? _generateGuide
                                        : _downloadGuide,
                            icon: _generating || _downloading
                                ? const SizedBox.square(
                                    dimension: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(
                                    _downloadable.isEmpty
                                        ? Icons.receipt_long_rounded
                                        : Icons.download_rounded,
                                    size: 19,
                                  ),
                            label: Text(
                              _generating
                                  ? 'Gerando...'
                                  : _downloading
                                      ? 'Baixando...'
                                      : _downloadable.isEmpty
                                          ? 'Gerar guia'
                                          : 'Baixar guia',
                              maxLines: 1,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: buttonWidth,
                          child: OutlinedButton.icon(
                            onPressed: _downloadable.isEmpty ||
                                    _generating ||
                                    _downloading ||
                                    _recalculating
                                ? null
                                : _recalculateGuide,
                            icon: _recalculating
                                ? const SizedBox.square(
                                    dimension: 17,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Icon(Icons.refresh_rounded, size: 19),
                            label: Text(
                              'Recalcular guia',
                              maxLines: 1,
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
                if (_downloadable.isEmpty) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Icon(
                        Icons.info_outline_rounded,
                        size: 15,
                        color: AppColors.muted,
                      ),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Gere a guia para liberar o download e o recálculo.',
                          style: TextStyle(
                            color: AppColors.muted,
                            fontSize: 11,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _downloadGuide() async {
    final selected = await _selectGuideToDownload();
    if (selected == null || !mounted) return;
    setState(() => _downloading = true);
    try {
      final bytes = await ref.read(downloadObligationProvider)(selected.id);
      final directory = await getTemporaryDirectory();
      final safeName = selected.name
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_')
          .replaceAll(RegExp(r'_+'), '_');
      final month = widget.month.toString().padLeft(2, '0');
      final file = File(
        '${directory.path}/${safeName}_$month-${widget.year}.pdf',
      );
      await file.writeAsBytes(bytes, flush: true);
      final result = await OpenFilex.open(file.path);
      if (result.type != ResultType.done && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result.message)),
        );
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Não foi possível baixar a guia.')),
        );
      }
    } finally {
      if (mounted) setState(() => _downloading = false);
    }
  }

  Future<void> _generateGuide() async {
    setState(() => _generating = true);
    try {
      await ref.read(generateObligationProvider)(
        month: widget.month,
        year: widget.year,
      );
      if (!mounted) return;
      await ref.read(obligationListProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guia de ${_monthLabel(widget.month).toLowerCase()} gerada com sucesso.',
          ),
        ),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(
                _apiErrorMessage(error, 'Não foi possível gerar a guia.'))),
      );
    } finally {
      if (mounted) setState(() => _generating = false);
    }
  }

  Future<Obligation?> _selectGuideToDownload() async {
    if (_downloadable.length == 1) return _downloadable.first;
    return showModalBottomSheet<Obligation>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Qual guia deseja baixar?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              for (final item in _downloadable)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.softPrimary,
                    child: Icon(
                      Icons.picture_as_pdf_outlined,
                      color: AppColors.primary,
                    ),
                  ),
                  title: Text(item.name),
                  subtitle: Text(AppFormatters.money(item.amount)),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, item),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _recalculateGuide() async {
    final selected = await _selectGuideToRecalculate();
    if (selected == null || !mounted) return;
    final confirmed = await showModalBottomSheet<bool>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(22, 4, 22, 26),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 46,
                    height: 46,
                    decoration: BoxDecoration(
                      color: AppColors.softAccent,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Icon(
                      Icons.refresh_rounded,
                      color: AppColors.accent,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recalcular guia',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        Text(
                          '${_monthLabel(widget.month)} de ${widget.year}',
                          style: TextStyle(color: AppColors.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                'A guia será emitida novamente pelo Integra Contador. O PDF atual será substituído pela nova versão.',
                style: TextStyle(height: 1.45),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _recalculating = true);
    try {
      await ref.read(recalculateObligationProvider)(selected.id);
      if (!mounted) return;
      await ref.read(obligationListProvider.future);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Guia de ${_monthLabel(widget.month).toLowerCase()} recalculada com sucesso.',
          ),
        ),
      );
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
                _apiErrorMessage(error, 'Não foi possível recalcular a guia.')),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _recalculating = false);
    }
  }

  Future<Obligation?> _selectGuideToRecalculate() async {
    if (_downloadable.length == 1) return _downloadable.first;
    return showModalBottomSheet<Obligation>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Qual guia deseja recalcular?',
                style: TextStyle(fontSize: 19, fontWeight: FontWeight.w900),
              ),
              const SizedBox(height: 10),
              for (final item in _downloadable)
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: AppColors.softAccent,
                    child: Icon(Icons.refresh_rounded, color: AppColors.accent),
                  ),
                  title: Text(item.name),
                  trailing: Icon(Icons.chevron_right_rounded),
                  onTap: () => Navigator.pop(context, item),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

class _MonthBadge extends StatelessWidget {
  const _MonthBadge({
    required this.month,
    required this.color,
    this.compact = false,
  });

  final int month;
  final Color color;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: compact ? 42 : 48,
      height: compact ? 42 : 52,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(compact ? 13 : 16),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            month.toString().padLeft(2, '0'),
            style: TextStyle(
              color: color,
              fontSize: compact ? 16 : 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          if (!compact)
            Text(
              _monthShortLabel(month),
              style: TextStyle(
                color: color,
                fontSize: 9,
                fontWeight: FontWeight.w900,
              ),
            ),
        ],
      ),
    );
  }
}

class _WaitingGuidePanel extends StatelessWidget {
  const _WaitingGuidePanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(Icons.schedule_rounded, color: AppColors.muted, size: 21),
          SizedBox(width: 10),
          Expanded(
            child: Text(
              'Nenhuma guia foi gerada para este mês.',
              style: TextStyle(color: AppColors.muted),
            ),
          ),
        ],
      ),
    );
  }
}

class _GuideEntry extends ConsumerStatefulWidget {
  const _GuideEntry(this.item);

  final Obligation item;

  @override
  ConsumerState<_GuideEntry> createState() => _GuideEntryState();
}

class _GuideEntryState extends ConsumerState<_GuideEntry> {
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final color = _statusColor(item.status);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                item.name,
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
            const SizedBox(width: 8),
            StatusBadge(_statusLabel(item.status), color: color),
          ],
        ),
        const SizedBox(height: 5),
        Text(
          item.amount > 0
              ? 'Vencimento ${AppFormatters.date(item.dueDate)} • ${AppFormatters.money(item.amount)}'
              : 'Consulte o vencimento e o valor no PDF',
          style: TextStyle(color: AppColors.muted, fontSize: 12),
        ),
        if (!item.hasFile) ...[
          const SizedBox(height: 6),
          Text(
            'Guia ainda não gerada',
            style: TextStyle(
              color: AppColors.warning,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
        if (item.paymentCode != null ||
            (item.status != ObligationStatus.paid &&
                item.status != ObligationStatus.canceled)) ...[
          const SizedBox(height: 7),
          Wrap(
            spacing: 4,
            runSpacing: 4,
            children: [
              if (item.paymentCode case final code?)
                TextButton.icon(
                  onPressed: () => _copyCode(code),
                  icon: Icon(Icons.copy_outlined, size: 17),
                  label: Text('Copiar código'),
                ),
              if (item.status != ObligationStatus.paid &&
                  item.status != ObligationStatus.canceled)
                TextButton.icon(
                  onPressed: _saving ? null : _markAsPaid,
                  icon: _saving
                      ? const SizedBox.square(
                          dimension: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Icon(Icons.check_circle_outline, size: 17),
                  label: Text('Informar pagamento'),
                ),
            ],
          ),
        ],
      ],
    );
  }

  Future<void> _copyCode(String code) async {
    await Clipboard.setData(ClipboardData(text: code));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('Código copiado.')));
  }

  Future<void> _markAsPaid() async {
    setState(() => _saving = true);
    try {
      await ref.read(markObligationPaidProvider)(widget.item.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pagamento informado com sucesso.')),
      );
    } catch (_) {
      if (!mounted) return;
      setState(() => _saving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Não foi possível informar o pagamento.')),
      );
    }
  }
}

class _MonthPresentation {
  _MonthPresentation({
    required this.label,
    required this.description,
    required this.color,
  });

  final String label;
  final String description;
  final Color color;
}

_MonthPresentation _monthPresentation(List<Obligation> items) {
  if (items.isEmpty) {
    return _MonthPresentation(
      label: 'Aguardando',
      description: 'A guia ainda não foi gerada.',
      color: AppColors.muted,
    );
  }
  if (items.every((item) => item.status == ObligationStatus.paid)) {
    return _MonthPresentation(
      label: 'Concluído',
      description: 'Todas as guias desta competência estão pagas.',
      color: AppColors.success,
    );
  }
  if (items.any((item) => item.status == ObligationStatus.overdue)) {
    return _MonthPresentation(
      label: 'Atenção',
      description: 'Existe uma guia vencida nesta competência.',
      color: AppColors.danger,
    );
  }
  if (!items.any((item) => item.hasFile)) {
    return _MonthPresentation(
      label: 'Preparando',
      description: 'A guia ainda não possui um PDF.',
      color: AppColors.warning,
    );
  }
  return _MonthPresentation(
    label: 'Disponível',
    description: 'Sua guia está pronta para download.',
    color: AppColors.primary,
  );
}

String _monthLabel(int month) => const [
      'Janeiro',
      'Fevereiro',
      'Março',
      'Abril',
      'Maio',
      'Junho',
      'Julho',
      'Agosto',
      'Setembro',
      'Outubro',
      'Novembro',
      'Dezembro',
    ][month - 1];

String _monthShortLabel(int month) => const [
      'JAN',
      'FEV',
      'MAR',
      'ABR',
      'MAI',
      'JUN',
      'JUL',
      'AGO',
      'SET',
      'OUT',
      'NOV',
      'DEZ',
    ][month - 1];

String _apiErrorMessage(Object error, String fallback) {
  if (error is DioException) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message is String && message.trim().isNotEmpty) return message;
      if (message is List && message.isNotEmpty) {
        return message.first.toString();
      }
    }
  }
  return fallback;
}

String _statusLabel(ObligationStatus status) => switch (status) {
      ObligationStatus.open => 'Em aberto',
      ObligationStatus.dueSoon => 'A vencer',
      ObligationStatus.overdue => 'Vencida',
      ObligationStatus.paid => 'Paga',
      ObligationStatus.canceled => 'Cancelada',
    };

Color _statusColor(ObligationStatus status) => switch (status) {
      ObligationStatus.paid => AppColors.success,
      ObligationStatus.overdue => AppColors.danger,
      ObligationStatus.dueSoon => AppColors.warning,
      ObligationStatus.canceled => AppColors.muted,
      ObligationStatus.open => AppColors.primary,
    };
