import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/features/chat/domain/entities/chat_message.dart';

class ChatRepository {
  ChatRepository._();
  static final ChatRepository instance = ChatRepository._();

  final _client = Supabase.instance.client;
  static const _table = 'messages';

  // ── Mensajes de una conversación ───────────────────────────────────────────

  Future<List<ChatMessage>> fetchConversation({
    required String userA,
    required String userB,
    int limit = 80,
  }) async {
    // Do NOT swallow errors here — let the provider catch them and surface an
    // error state so the user sees a meaningful message instead of an empty
    // chat.  Supabase RLS issues (e.g. missing SELECT policy) would otherwise
    // silently return [] and make old messages appear "gone".
    try {
      final rows = await _client
          .from(_table)
          .select()
          .or(
            'and(sender_id.eq.$userA,recipient_id.eq.$userB),'
            'and(sender_id.eq.$userB,recipient_id.eq.$userA)',
          )
          .order('created_at', ascending: true)
          .limit(limit);
      return (rows as List)
          .map((r) => ChatMessage.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[Chat] fetchConversation error: $e');
      rethrow; // propagate so the provider enters AsyncError state
    }
  }

  // ── Enviar ─────────────────────────────────────────────────────────────────

  Future<void> sendMessage({
    required String companyId,
    required String senderId,
    required String recipientId,
    required String content,
  }) async {
    await _client.from(_table).insert({
      'id': const Uuid().v4(),
      'company_id': companyId,
      'sender_id': senderId,
      'recipient_id': recipientId,
      'content': content,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    });
  }

  // ── Marcar leídos ──────────────────────────────────────────────────────────

  Future<void> markConversationRead({
    required String myId,
    required String otherId,
  }) async {
    try {
      await _client
          .from(_table)
          .update({'is_read': true})
          .eq('recipient_id', myId)
          .eq('sender_id', otherId)
          .eq('is_read', false);
    } catch (_) {}
  }

  // ── Conteo de no leídos ────────────────────────────────────────────────────

  Future<int> countUnread(String myId) async {
    try {
      final rows = await _client
          .from(_table)
          .select('id')
          .eq('recipient_id', myId)
          .eq('is_read', false);
      return (rows as List).length;
    } catch (_) {
      return 0;
    }
  }

  // ── Lista de conversaciones para admin ────────────────────────────────────

  /// Devuelve los IDs de empleados que tienen mensajes con el admin.
  Future<List<String>> fetchConversationPartners(String myId) async {
    try {
      final sent = await _client
          .from(_table)
          .select('recipient_id')
          .eq('sender_id', myId);
      final received = await _client
          .from(_table)
          .select('sender_id')
          .eq('recipient_id', myId);

      final ids = <String>{};
      for (final r in (sent as List)) {
        ids.add(r['recipient_id'] as String);
      }
      for (final r in (received as List)) {
        ids.add(r['sender_id'] as String);
      }
      return ids.toList();
    } catch (_) {
      return [];
    }
  }

  /// Último mensaje entre dos usuarios.
  Future<ChatMessage?> fetchLastMessage(String userA, String userB) async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .or(
            'and(sender_id.eq.$userA,recipient_id.eq.$userB),'
            'and(sender_id.eq.$userB,recipient_id.eq.$userA)',
          )
          .order('created_at', ascending: false)
          .limit(1);
      final list = rows as List;
      if (list.isEmpty) return null;
      return ChatMessage.fromMap(list.first as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  /// Devuelve el ID del primer admin de una empresa.
  Future<String?> fetchAdminId(String companyId) async {
    try {
      final rows = await _client
          .from('employees')
          .select('id')
          .eq('company_id', companyId)
          .eq('role', 'ADMIN')
          .limit(1);
      final list = rows as List;
      if (list.isEmpty) return null;
      return list.first['id'] as String?;
    } catch (_) {
      return null;
    }
  }
}
