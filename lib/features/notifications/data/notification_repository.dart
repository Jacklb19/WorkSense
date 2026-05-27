import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/features/notifications/domain/entities/app_notification.dart';

/// Repositorio de notificaciones in-app almacenadas en Supabase.
/// Las notificaciones se envían al destinatario correcto (no al remitente).
class NotificationRepository {
  NotificationRepository._();
  static final NotificationRepository instance = NotificationRepository._();

  final _client = Supabase.instance.client;
  static const _table = 'notifications';

  // ── Crear ──────────────────────────────────────────────────────────────────

  /// Envía una notificación a un usuario específico por su ID.
  /// Escribe en la tabla `notifications` Y dispara un push via FCM Edge Function.
  Future<void> pushToUser({
    required String recipientId,
    required String companyId,
    required String type,
    required String title,
    required String body,
    String? senderId,
    String? route,
  }) async {
    try {
      // 1. Guardar en la tabla in-app (para el panel de notificaciones)
      await _client.from(_table).insert({
        'id': const Uuid().v4(),
        'company_id': companyId,
        'recipient_id': recipientId,
        'to_role': null,
        'sender_id': senderId,
        'type': type,
        'title': title,
        'body': body,
        'is_read': false,
        'route': route,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    // FCM push desactivado (Firebase no configurado)
  }

  /// Envía una notificación a todos los admins de una empresa.
  /// Escribe en la tabla `notifications` Y dispara pushes via FCM Edge Function.
  Future<void> pushToAdmins({
    required String companyId,
    required String type,
    required String title,
    required String body,
    String? senderId,
    String? route,
  }) async {
    try {
      // 1. Guardar en la tabla in-app
      await _client.from(_table).insert({
        'id': const Uuid().v4(),
        'company_id': companyId,
        'recipient_id': null,
        'to_role': 'ADMIN',
        'sender_id': senderId,
        'type': type,
        'title': title,
        'body': body,
        'is_read': false,
        'route': route,
        'created_at': DateTime.now().toIso8601String(),
      });
    } catch (_) {}

    // FCM push desactivado (Firebase no configurado)
  }

  // ── Leer ───────────────────────────────────────────────────────────────────

  /// Fetches notifications for [userId] — both personal (recipient_id = userId)
  /// and role-based (to_role = userRole, company_id = companyId).
  Future<List<AppNotification>> fetchMine({
    required String userId,
    required String userRole,   // e.g. 'ADMIN', 'EMPLOYEE'
    required String companyId,
  }) async {
    try {
      final results = <AppNotification>[];

      // 1) Personal notifications directed to this user
      //    Exclude self-sent: when admin sends a chat message it creates a
      //    notification for the recipient — we must not show it in the
      //    sender's own inbox even if RLS happens to expose the row.
      final personal = await _client
          .from(_table)
          .select()
          .eq('recipient_id', userId)
          .order('created_at', ascending: false)
          .limit(40);
      for (final r in personal as List) {
        final n = AppNotification.fromMap(r as Map<String, dynamic>);
        if (n.senderId != userId) results.add(n); // skip self-sent
      }

      // 2) Role-based notifications (e.g. all admins of a company)
      //    Also exclude self-sent so an admin who submits their own leave
      //    request doesn't see the resulting "new leave request" notification
      //    in their own inbox.
      final roleBased = await _client
          .from(_table)
          .select()
          .eq('to_role', userRole.toUpperCase())
          .eq('company_id', companyId)
          .isFilter('recipient_id', null)
          .order('created_at', ascending: false)
          .limit(40);
      for (final r in roleBased as List) {
        final n = AppNotification.fromMap(r as Map<String, dynamic>);
        if (n.senderId != userId) results.add(n); // skip self-sent
      }

      // Sort merged list by createdAt descending, dedupe by id
      final seen = <String>{};
      results.retainWhere((n) => seen.add(n.id));
      results.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return results.take(50).toList();
    } catch (e) {
      debugPrint('[Notifications] fetchMine error: $e');
      return [];
    }
  }

  /// Cuenta las notificaciones no leídas del usuario:
  ///   • personales  (recipient_id = [userId])
  ///   • por rol     (to_role = [userRole], company_id = [companyId])
  Future<int> countUnread({
    required String userId,
    required String userRole,
    required String companyId,
  }) async {
    try {
      // Personal unread (exclude self-sent to match fetchMine filtering)
      final personal = await _client
          .from(_table)
          .select('id, sender_id')
          .eq('recipient_id', userId)
          .eq('is_read', false);

      // Role-based unread (exclude self-sent)
      final roleBased = await _client
          .from(_table)
          .select('id, sender_id')
          .eq('to_role', userRole.toUpperCase())
          .eq('company_id', companyId)
          .isFilter('recipient_id', null)
          .eq('is_read', false);

      // Dedupe by id; exclude any row the user sent themselves
      final ids = <String>{
        for (final r in personal as List)
          if ((r['sender_id'] as String?) != userId) r['id'] as String,
        for (final r in roleBased as List)
          if ((r['sender_id'] as String?) != userId) r['id'] as String,
      };
      return ids.length;
    } catch (_) {
      return 0;
    }
  }

  // ── Marcar leída ───────────────────────────────────────────────────────────

  Future<void> markRead(String notificationId) async {
    try {
      await _client
          .from(_table)
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (_) {}
  }

  Future<void> markAllRead({
    required String userId,
    required String userRole,
    required String companyId,
  }) async {
    try {
      // Mark personal notifications
      await _client
          .from(_table)
          .update({'is_read': true})
          .eq('recipient_id', userId)
          .eq('is_read', false);

      // Mark role-based notifications
      await _client
          .from(_table)
          .update({'is_read': true})
          .eq('to_role', userRole.toUpperCase())
          .eq('company_id', companyId)
          .isFilter('recipient_id', null)
          .eq('is_read', false);
    } catch (_) {}
  }
}
