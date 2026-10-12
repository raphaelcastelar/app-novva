import '../entities/notice_item.dart';

abstract interface class NoticesRepository {
  Future<List<NoticeItem>> fetchNotices();
  Future<void> markRead(String id);
  Future<List<int>> downloadAttachment(String id);
}
