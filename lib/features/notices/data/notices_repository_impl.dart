import '../domain/entities/notice_item.dart';
import '../domain/repositories/notices_repository.dart';
import 'notices_remote_datasource.dart';

class NoticesRepositoryImpl implements NoticesRepository {
  const NoticesRepositoryImpl(this.remote);
  final NoticesRemoteDataSource remote;
  @override
  Future<List<NoticeItem>> fetchNotices() async => (await remote.list())
      .map((json) => NoticeItem(
            id: json['id'] as String,
            title: json['title'] as String,
            description: json['description'] as String,
            createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
            isRead: json['isRead'] == true,
            hasAttachment: json['hasAttachment'] == true,
            attachmentOriginalName: json['attachmentOriginalName'] as String?,
          ))
      .toList(growable: false);
  @override
  Future<void> markRead(String id) => remote.markRead(id);
  @override
  Future<List<int>> downloadAttachment(String id) => remote.download(id);
}
