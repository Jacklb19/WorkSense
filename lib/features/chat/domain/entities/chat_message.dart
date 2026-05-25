class ChatMessage {
  final String id;
  final String companyId;
  final String senderId;
  final String recipientId;
  final String content;
  final bool isRead;
  final DateTime createdAt;

  const ChatMessage({
    required this.id,
    required this.companyId,
    required this.senderId,
    required this.recipientId,
    required this.content,
    required this.isRead,
    required this.createdAt,
  });

  factory ChatMessage.fromMap(Map<String, dynamic> m) => ChatMessage(
        id: m['id'] as String,
        companyId: m['company_id'] as String,
        senderId: m['sender_id'] as String,
        recipientId: m['recipient_id'] as String,
        content: (m['content'] as String?) ?? '',
        isRead: (m['is_read'] as bool?) ?? false,
        createdAt: m['created_at'] != null
            ? DateTime.parse(m['created_at'] as String)
            : DateTime.now(),
      );

  Map<String, dynamic> toMap() => {
        'id': id,
        'company_id': companyId,
        'sender_id': senderId,
        'recipient_id': recipientId,
        'content': content,
        'is_read': isRead,
        'created_at': createdAt.toIso8601String(),
      };
}
