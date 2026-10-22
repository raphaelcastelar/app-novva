class NotificationItem {
  const NotificationItem({
    required this.id,
    required this.title,
    required this.body,
    required this.kind,
    required this.createdAt,
    required this.isRead,
    this.entityId,
  });

  final String id;
  final String title;
  final String body;
  final String kind;
  final DateTime createdAt;
  final bool isRead;
  final String? entityId;

  factory NotificationItem.fromJson(Map<String, dynamic> json) {
    return NotificationItem(
      id: json['id'] as String,
      title: json['title'] as String,
      body: json['body'] as String,
      kind: json['kind'] as String? ?? 'general',
      createdAt: DateTime.parse(json['createdAt'] as String).toLocal(),
      isRead: json['readAt'] != null,
      entityId: json['entityId'] as String?,
    );
  }
}
