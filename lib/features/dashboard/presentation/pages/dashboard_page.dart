import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/novva_brand_mark.dart';
import '../../../../core/widgets/profile_avatar.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../../notices/domain/entities/notice_item.dart';
import '../../../notices/presentation/providers/notices_providers.dart';
import '../providers/dashboard_providers.dart';

class DashboardPage extends ConsumerWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(dashboardSummaryProvider);
    final user = ref.watch(authControllerProvider).valueOrNull;
    final fullName = user?.name.trim() ?? '';
    final firstName =
        fullName.isEmpty ? null : fullName.split(RegExp(r'\s+')).first;

    return AppScaffold(
      title: '',
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
            child: _Header(firstName: firstName),
          ),
          Expanded(
            child: summary.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (_, __) => _DashboardLoadError(
                onRetry: () {
                  ref.invalidate(dashboardSummaryProvider);
                  ref.invalidate(noticesProvider);
                },
              ),
              data: (data) => RefreshIndicator(
                onRefresh: () async {
                  await Future.wait([
                    ref.refresh(dashboardSummaryProvider.future),
                    ref.refresh(noticesProvider.future)
                  ]);
                },
                child: ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 132),
                  children: [
                    _RevenueHero(summary: data),
                    const SizedBox(height: 24),
                    KeyedSubtree(
                      key: const ValueKey('account-overview-section'),
                      child: _AccountOverview(summary: data),
                    ),
                    const SizedBox(height: 26),
                    const KeyedSubtree(
                      key: ValueKey('notice-board-section'),
                      child: _NoticeBoard(),
                    ),
                    const SizedBox(height: 26),
                    const _QuickActions(),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const _Header({required this.firstName});

  final String? firstName;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          const ProfileAvatar(
            radius: 23,
            backgroundColor: AppColors.softAccent,
            foregroundColor: AppColors.primary,
          ),
          const SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  firstName == null ? 'Olá' : 'Olá, $firstName',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w900,
                        letterSpacing: -0.35,
                      ),
                ),
                Text(
                  _todayLabel(DateTime.now()),
                  style: const TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Notificações',
            onPressed: () => context.go(RouteNames.notifications),
            style: IconButton.styleFrom(
              foregroundColor: AppColors.primary,
              backgroundColor: AppColors.softPrimary,
            ),
            icon: const Icon(Icons.notifications_outlined),
          ),
          const SizedBox(width: 6),
          const NovvaBrandMark(size: 36),
        ],
      );
}

class _DashboardLoadError extends StatelessWidget {
  const _DashboardLoadError({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: EmptyState(
            title: 'Não foi possível carregar o início',
            message: 'Verifique sua conexão e tente novamente.',
            icon: Icons.cloud_off_outlined,
            actionLabel: 'Tentar novamente',
            onAction: onRetry,
          ),
        ),
      );
}

class _RevenueHero extends StatelessWidget {
  const _RevenueHero({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) {
    final month = _monthLabel(DateTime.now().month).toLowerCase();
    final invoiceLabel = summary.orders == 1
        ? '1 nota emitida em $month'
        : '${summary.orders} notas emitidas em $month';

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.primaryDark,
        borderRadius: BorderRadius.circular(28),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.14),
                  ),
                ),
                child: const Icon(
                  Icons.receipt_long_rounded,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Text(
                  'Faturamento de $month',
                  style: const TextStyle(
                    color: Color(0xD9FFFFFF),
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Text(
                '${summary.orders}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 5),
              const Icon(
                Icons.description_outlined,
                color: Color(0xBFFFFFFF),
                size: 18,
              ),
            ],
          ),
          const SizedBox(height: 22),
          Text(
            AppFormatters.money(summary.monthRevenue),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 34,
              fontWeight: FontWeight.w900,
              letterSpacing: -0.8,
              height: 1.08,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            invoiceLabel,
            style: const TextStyle(color: Color(0xBFFFFFFF), fontSize: 12),
          ),
          const SizedBox(height: 22),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  onPressed: () => context.go(RouteNames.invoices),
                  icon: const Icon(Icons.add_rounded, size: 18),
                  label: const Text('Emitir nota'),
                ),
              ),
              const SizedBox(width: 10),
              IconButton.filled(
                tooltip: 'Ver notas fiscais',
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.1),
                  foregroundColor: Colors.white,
                ),
                onPressed: () => context.go(RouteNames.invoices),
                icon: const Icon(Icons.arrow_forward_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _NoticeBoard extends ConsumerWidget {
  const _NoticeBoard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notices = ref.watch(noticesProvider);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Quadro de avisos',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 4),
        const Text(
          'Comunicados importantes aparecerão aqui.',
          style: TextStyle(color: AppColors.muted),
        ),
        const SizedBox(height: 13),
        notices.when(
            loading: () => const SizedBox(
                height: 108, child: Center(child: CircularProgressIndicator())),
            error: (_, __) => _NoticeMessage(
                title: 'Não foi possível carregar os avisos',
                message: 'Puxe a tela para baixo para tentar novamente.',
                icon: Icons.cloud_off_outlined),
            data: (items) => items.isEmpty
                ? const _NoticeMessage(
                    title: 'Nenhum aviso publicado',
                    message:
                        'A equipe Novva poderá usar este espaço para manter você informado.',
                    icon: Icons.campaign_outlined)
                : _NoticeCarousel(items: items)),
      ],
    );
  }
}

class _NoticeCarousel extends StatefulWidget {
  const _NoticeCarousel({required this.items});

  final List<NoticeItem> items;

  @override
  State<_NoticeCarousel> createState() => _NoticeCarouselState();
}

class _NoticeCarouselState extends State<_NoticeCarousel> {
  static const _rotationInterval = Duration(seconds: 5);
  final PageController _controller = PageController();
  Timer? _timer;
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _startRotation();
  }

  @override
  void didUpdateWidget(covariant _NoticeCarousel oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.items.length != widget.items.length) {
      _currentPage = 0;
      if (_controller.hasClients) {
        _controller.jumpToPage(0);
      }
      _startRotation();
    }
  }

  void _startRotation() {
    _timer?.cancel();
    if (widget.items.length < 2) return;
    _timer = Timer.periodic(_rotationInterval, (_) {
      if (!mounted || !_controller.hasClients) return;
      final nextPage = (_currentPage + 1) % widget.items.length;
      _controller.animateToPage(
        nextPage,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
        children: [
          SizedBox(
            height: 118,
            child: PageView.builder(
              key: const ValueKey('notice-carousel'),
              controller: _controller,
              itemCount: widget.items.length,
              onPageChanged: (page) => setState(() => _currentPage = page),
              itemBuilder: (context, index) => Material(
                color: AppColors.surface,
                clipBehavior: Clip.antiAlias,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                  side: const BorderSide(color: AppColors.border),
                ),
                child: _NoticeRow(notice: widget.items[index]),
              ),
            ),
          ),
          if (widget.items.length > 1) ...[
            const SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                widget.items.length,
                (index) => AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  width: index == _currentPage ? 18 : 7,
                  height: 7,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: index == _currentPage
                        ? AppColors.primary
                        : AppColors.border,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ),
          ],
        ],
      );
}

class _NoticeMessage extends StatelessWidget {
  const _NoticeMessage(
      {required this.title, required this.message, required this.icon});
  final String title, message;
  final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        constraints: const BoxConstraints(minHeight: 108),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: AppColors.softPrimary,
            borderRadius: BorderRadius.circular(22),
            border:
                Border.all(color: AppColors.primary.withValues(alpha: .12))),
        child: Row(children: [
          _NoticeBoardIcon(icon: icon),
          const SizedBox(width: 13),
          Expanded(
              child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w900)),
                const SizedBox(height: 4),
                Text(message,
                    style: const TextStyle(
                        color: AppColors.muted, fontSize: 12, height: 1.35))
              ]))
        ]),
      );
}

class _NoticeRow extends ConsumerWidget {
  const _NoticeRow({required this.notice});
  final NoticeItem notice;
  @override
  Widget build(BuildContext context, WidgetRef ref) => Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (!notice.isRead) {
            await ref.read(noticesRepositoryProvider).markRead(notice.id);
            ref.invalidate(noticesProvider);
          }
          if (context.mounted) {
            showModalBottomSheet(
                context: context,
                useRootNavigator: true,
                useSafeArea: true,
                isScrollControlled: true,
                constraints: BoxConstraints.tightFor(
                    width: MediaQuery.sizeOf(context).width),
                showDragHandle: true,
                builder: (_) => _NoticeDetails(notice: notice));
          }
        },
        child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Stack(children: [
                const _NoticeBoardIcon(),
                if (!notice.isRead)
                  Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                          width: 10,
                          height: 10,
                          decoration: BoxDecoration(
                              color: AppColors.warning,
                              borderRadius: BorderRadius.circular(5),
                              border:
                                  Border.all(color: Colors.white, width: 2))))
              ]),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(notice.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w900)),
                    const SizedBox(height: 4),
                    Text(notice.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: AppColors.muted,
                            fontSize: 12,
                            height: 1.35)),
                    const SizedBox(height: 7),
                    Row(children: [
                      Text(AppFormatters.date(notice.createdAt),
                          style: const TextStyle(
                              color: AppColors.muted, fontSize: 10)),
                      if (notice.hasAttachment) ...[
                        const SizedBox(width: 8),
                        const Icon(Icons.attach_file_rounded,
                            size: 13, color: AppColors.primary),
                        const Text(' Anexo',
                            style: TextStyle(
                                color: AppColors.primary,
                                fontSize: 10,
                                fontWeight: FontWeight.w700))
                      ]
                    ])
                  ])),
              const Icon(Icons.chevron_right_rounded, color: AppColors.muted),
            ])),
      ));
}

class _NoticeDetails extends ConsumerStatefulWidget {
  const _NoticeDetails({required this.notice});
  final NoticeItem notice;
  @override
  ConsumerState<_NoticeDetails> createState() => _NoticeDetailsState();
}

class _NoticeDetailsState extends ConsumerState<_NoticeDetails> {
  bool downloading = false;
  Future<void> download() async {
    setState(() => downloading = true);
    try {
      final bytes = await ref
          .read(noticesRepositoryProvider)
          .downloadAttachment(widget.notice.id);
      final dir = await getTemporaryDirectory();
      final name = (widget.notice.attachmentOriginalName ?? 'anexo')
          .replaceAll(RegExp(r'[^a-zA-Z0-9._-]'), '_');
      final file = File('${dir.path}/$name');
      await file.writeAsBytes(bytes, flush: true);
      await OpenFilex.open(file.path);
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Não foi possível baixar o anexo.')));
      }
    } finally {
      if (mounted) setState(() => downloading = false);
    }
  }

  @override
  Widget build(BuildContext context) => SafeArea(
      top: false,
      child: SizedBox(
          width: double.infinity,
          child: SingleChildScrollView(
            padding: EdgeInsets.fromLTRB(
                22, 8, 22, 22 + MediaQuery.viewInsetsOf(context).bottom),
            child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const _NoticeBoardIcon(),
                    const Spacer(),
                    IconButton(
                      tooltip: 'Fechar aviso',
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close_rounded),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  Text(widget.notice.title,
                      style: const TextStyle(
                          fontSize: 22, fontWeight: FontWeight.w900)),
                  const SizedBox(height: 6),
                  Text(AppFormatters.date(widget.notice.createdAt),
                      style: const TextStyle(
                          color: AppColors.muted, fontSize: 11)),
                  const SizedBox(height: 18),
                  Text(widget.notice.description,
                      style: const TextStyle(fontSize: 14, height: 1.55)),
                  if (widget.notice.hasAttachment) ...[
                    const SizedBox(height: 20),
                    SizedBox(
                        width: double.infinity,
                        child: FilledButton.icon(
                            onPressed: downloading ? null : download,
                            icon: downloading
                                ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2))
                                : const Icon(Icons.download_rounded),
                            label: Text(
                                downloading ? 'Baixando...' : 'Baixar anexo'))),
                    const SizedBox(height: 8),
                    Text(widget.notice.attachmentOriginalName ?? 'Anexo',
                        style: const TextStyle(
                            color: AppColors.muted, fontSize: 12)),
                  ],
                ]),
          )));
}

class _NoticeBoardIcon extends StatelessWidget {
  const _NoticeBoardIcon({this.icon = Icons.campaign_outlined});
  final IconData icon;

  @override
  Widget build(BuildContext context) => Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: AppColors.primary,
          size: 22,
        ),
      );
}

class _AccountOverview extends StatelessWidget {
  const _AccountOverview({required this.summary});

  final DashboardSummary summary;

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Acompanhamento',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Veja rapidamente o que está em andamento.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 13),
          Container(
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: AppColors.border),
            ),
            child: Column(
              children: [
                if (summary.nextObligation case final obligation?) ...[
                  _DeadlineRow(obligation: obligation),
                  const Divider(height: 1, indent: 62),
                ],
                _OverviewRow(
                  icon: Icons.folder_copy_outlined,
                  title: 'Documentos',
                  detail: _pendingLabel(
                    summary.pendingDocuments,
                    singular: 'solicitação pendente',
                    plural: 'solicitações pendentes',
                    empty: 'Nenhuma solicitação pendente',
                  ),
                  value: summary.pendingDocuments,
                  onTap: () => context.go(RouteNames.documents),
                ),
                const Divider(height: 1, indent: 62),
                _OverviewRow(
                  icon: Icons.receipt_long_outlined,
                  title: 'Guias',
                  detail: _pendingLabel(
                    summary.dueObligations,
                    singular: 'guia para acompanhar',
                    plural: 'guias para acompanhar',
                    empty: 'Nenhuma guia pendente',
                  ),
                  value: summary.dueObligations,
                  onTap: () => context.go(RouteNames.obligations),
                ),
              ],
            ),
          ),
        ],
      );
}

class _DeadlineRow extends StatelessWidget {
  const _DeadlineRow({required this.obligation});

  final DashboardObligation obligation;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(RouteNames.obligations),
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.warning.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: const Icon(
                    Icons.event_outlined,
                    color: AppColors.warning,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        obligation.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Vence em ${AppFormatters.date(obligation.dueDate)} • ${AppFormatters.money(obligation.amount)}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      );
}

class _OverviewRow extends StatelessWidget {
  const _OverviewRow({
    required this.icon,
    required this.title,
    required this.detail,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String detail;
  final int value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: AppColors.softPrimary,
                    borderRadius: BorderRadius.circular(13),
                  ),
                  child: Icon(icon, color: AppColors.primary, size: 20),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(fontWeight: FontWeight.w800),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        detail,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppColors.muted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                if (value > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(minWidth: 27),
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.softAccent,
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      '$value',
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: AppColors.primary,
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
                const SizedBox(width: 5),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: AppColors.muted,
                ),
              ],
            ),
          ),
        ),
      );
}

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Precisa resolver algo?',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 4),
          const Text(
            'Comece pelos pedidos mais usados.',
            style: TextStyle(color: AppColors.muted),
          ),
          const SizedBox(height: 13),
          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () => context.go(RouteNames.invoices),
              icon: const Icon(Icons.edit_note_rounded),
              label: const Text('Solicitar emissão de nota fiscal'),
            ),
          ),
          const SizedBox(height: 9),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(RouteNames.documents),
                  icon: const Icon(Icons.post_add_rounded, size: 18),
                  label: const Text('Pedir documento'),
                ),
              ),
              const SizedBox(width: 9),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => context.go(RouteNames.chat),
                  icon: const Icon(
                    Icons.chat_bubble_outline_rounded,
                    size: 18,
                  ),
                  label: const Text('Falar com a Novva'),
                ),
              ),
            ],
          ),
        ],
      );
}

String _pendingLabel(
  int value, {
  required String singular,
  required String plural,
  required String empty,
}) {
  if (value == 0) return empty;
  return '$value ${value == 1 ? singular : plural}';
}

String _todayLabel(DateTime date) =>
    'Hoje, ${date.day} de ${_monthLabel(date.month).toLowerCase()}';

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
