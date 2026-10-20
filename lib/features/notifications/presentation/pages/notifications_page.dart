import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../../../app/routes/route_names.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../core/widgets/app_card.dart';
import '../../../../core/widgets/app_scaffold.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../domain/notification_item.dart';
import '../providers/notifications_providers.dart';

class NotificationsPage extends ConsumerWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(notificationsProvider);
    return AppScaffold(
      title: 'Notificações',
      child: RefreshIndicator(
        onRefresh: () => ref.refresh(notificationsProvider.future),
        child: notifications.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (_, __) => ListView(
            physics: const AlwaysScrollableScrollPhysics(),
            children: [
              SizedBox(
                height: MediaQuery.sizeOf(context).height * .62,
                child: EmptyState(
                  title: 'Não foi possível carregar as notificações',
                  message: 'Puxe a tela para baixo e tente novamente.',
                  icon: Icons.cloud_off_outlined,
                  actionLabel: 'Tentar novamente',
                  onAction: () => ref.invalidate(notificationsProvider),
                ),
              ),
            ],
          ),
          data: (items) => items.isEmpty
              ? ListView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  children: const [
                    SizedBox(
                      height: 520,
                      child: EmptyState(
                        title: 'Nenhum documento novo',
                        message:
                            'Quando um documento estiver pronto, o aviso aparecerá aqui.',
                        icon: Icons.notifications_none_rounded,
                      ),
                    ),
                  ],
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 130),
                  itemCount: items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (context, index) => _NotificationCard(
                    item: items[index],
                    onTap: () async {
                      if (!items[index].isRead) {
                        await ref
                            .read(notificationsRemoteDataSourceProvider)
                            .markAsRead(items[index].id);
                        ref.invalidate(notificationsProvider);
                      }
                      if (context.mounted) context.go(RouteNames.documents);
                    },
                  ),
                ),
        ),
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({required this.item, required this.onTap});

  final NotificationItem item;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return AppCard(
      onTap: onTap,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          CircleAvatar(
            backgroundColor:
                item.isRead ? AppColors.background : AppColors.softPrimary,
            child: Icon(
              Icons.description_outlined,
              color: item.isRead ? AppColors.muted : AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: TextStyle(
                    fontWeight: item.isRead ? FontWeight.w600 : FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(item.body),
                const SizedBox(height: 8),
                Text(
                  DateFormat("dd/MM/yyyy 'às' HH:mm", 'pt_BR')
                      .format(item.createdAt),
                  style: TextStyle(
                    color: AppColors.muted,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          if (!item.isRead)
            Padding(
              padding: EdgeInsets.only(left: 8, top: 4),
              child:
                  CircleAvatar(radius: 4, backgroundColor: AppColors.primary),
            ),
        ],
      ),
    );
  }
}
