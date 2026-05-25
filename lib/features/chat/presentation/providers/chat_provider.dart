import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:worksense_app/features/chat/data/chat_repository.dart';
import 'package:worksense_app/features/chat/domain/entities/chat_message.dart';
import 'package:worksense_app/features/notifications/data/notification_repository.dart';
import 'package:worksense_app/features/notifications/presentation/providers/notifications_provider.dart';
import 'package:worksense_app/shared/providers/current_user_provider.dart';

// ── Conversación entre dos usuarios ──────────────────────────────────────────

final conversationProvider = AsyncNotifierProviderFamily<
    ConversationNotifier, List<ChatMessage>, String>(
  ConversationNotifier.new,
);

class ConversationNotifier
    extends FamilyAsyncNotifier<List<ChatMessage>, String> {
  Timer? _timer;

  @override
  Future<List<ChatMessage>> build(String otherId) async {
    final myId = ref.read(currentUserProvider).valueOrNull?.user?.id;
    if (myId == null) return [];

    // Auto-refresh cada 10 s cuando la conversación está abierta
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 10), (_) => _load());
    ref.onDispose(() => _timer?.cancel());

    return _fetchAndMark(myId, otherId);
  }

  Future<List<ChatMessage>> _fetchAndMark(String myId, String otherId) async {
    final msgs = await ChatRepository.instance.fetchConversation(
      userA: myId,
      userB: otherId,
    );
    // Marca como leídos los mensajes recibidos
    await ChatRepository.instance.markConversationRead(
      myId: myId,
      otherId: otherId,
    );
    // Actualiza conteo de mensajes no leídos
    ref.read(unreadMessagesCountProvider.notifier).refresh();
    return msgs;
  }

  Future<void> _load() async {
    final myId = ref.read(currentUserProvider).valueOrNull?.user?.id;
    if (myId == null) return;
    state = AsyncData(await _fetchAndMark(myId, arg));
  }

  Future<void> sendMessage({
    required String companyId,
    required String senderId,
    required String senderName,
  }) async {
    // No-op: content is passed when calling the public method
  }

  Future<void> send({
    required String content,
    required String companyId,
    required String senderId,
    required String senderName,
  }) async {
    if (content.trim().isEmpty) return;

    await ChatRepository.instance.sendMessage(
      companyId: companyId,
      senderId: senderId,
      recipientId: arg,
      content: content.trim(),
    );

    // Enviar notificación al destinatario
    await NotificationRepository.instance.pushToUser(
      recipientId: arg,
      companyId: companyId,
      type: 'message',
      title: '💬 Mensaje de $senderName',
      body: content.trim().length > 80
          ? '${content.trim().substring(0, 80)}…'
          : content.trim(),
      senderId: senderId,
      route: '/chat-list',
    );

    await _load();
  }
}

// ── Lista de conversaciones del admin ─────────────────────────────────────────

final chatPartnersProvider = FutureProvider<List<String>>((ref) async {
  final myId = ref.watch(currentUserProvider).valueOrNull?.user?.id;
  if (myId == null) return [];
  return ChatRepository.instance.fetchConversationPartners(myId);
});
