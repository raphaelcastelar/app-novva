class NoticeItem {
  const NoticeItem(
      {required this.id,
      required this.title,
      required this.description,
      required this.createdAt,
      required this.isRead,
      required this.hasAttachment,
      this.attachmentOriginalName});
  final String id, title, description;
  final DateTime createdAt;
  final bool isRead, hasAttachment;
  final String? attachmentOriginalName;
}
