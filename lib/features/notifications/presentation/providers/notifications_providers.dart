import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/providers/auth_providers.dart';
import '../../data/notifications_remote_data_source.dart';
import '../../domain/notification_item.dart';

final notificationsRemoteDataSourceProvider = Provider(
  (ref) => NotificationsRemoteDataSource(
    DioClient(ref.watch(tokenManagerProvider)).dio,
  ),
);

final notificationsProvider =
    FutureProvider.autoDispose<List<NotificationItem>>(
  (ref) => ref.watch(notificationsRemoteDataSourceProvider).fetch(),
);
