class AppNotification {
  final String id;
  final String companyId;
  final String? recipientId;
  final String? toRole;
  final String? senderId;
  final String type;
  final String title;
  final String body;
  final bool isRead;
  final String? route;
  final DateTime createdAt;

  const AppNotification({
    required this.id,
    required this.companyId,
    this.recipientId,
    this.toRole,
    this.senderId,
    required this.type,
    required this.title,
    required this.body,
    required this.isRead,
    this.route,
    required this.createdAt,
  });

  factory AppNotification.fromMap(Map<String, dynamic> m) => AppNotification(
        id: m['id'] as String,
        companyId: m['company_id'] as String,
        recipientId: m['recipient_id'] as String?,
        toRole: m['to_role'] as String?,
        senderId: m['sender_id'] as String?,
        type: (m['type'] as String?) ?? 'general',
        title: (m['title'] as String?) ?? '',
        body: (m['body'] as String?) ?? '',
        isRead: (m['is_read'] as bool?) ?? false,
        route: m['route'] as String?,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'recipient_id': recipientId,
        'to_role': toRole,
        'sender_id': senderId,
        'type': type,
        'title': title,
        'body': body,
        'is_read': isRead,
        'route': route,
        'created_at': createdAt.toIso8601String(),
      };
}
