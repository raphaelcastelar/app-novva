import 'package:dio/dio.dart';

import '../domain/notification_item.dart';

class NotificationsRemoteDataSource {
  const NotificationsRemoteDataSource(this._dio);

  final Dio _dio;

  Future<List<NotificationItem>> fetch() async {
    final response = await _dio.get<Map<String, dynamic>>(
      'notifications',
      queryParameters: {'page': 1, 'limit': 50},
    );
    final items = response.data?['items'] as List<dynamic>? ?? const [];
    return items
        .map((item) => NotificationItem.fromJson(item as Map<String, dynamic>))
        .where((item) => item.kind == 'document_available')
        .toList(growable: false);
  }

  Future<void> markAsRead(String id) async {
    await _dio.patch<void>('notifications/$id/read');
  }
}
