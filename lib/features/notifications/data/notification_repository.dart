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

    try {
      // 2. Push real via FCM Edge Function (si el usuario no tiene la app abierta)
      await _client.functions.invoke(
        'send-push',
        body: {
          'recipient_id': recipientId,
          'company_id': companyId,
          'title': title,
          'body': body,
          'data': {'route': route ?? '', 'type': type},
        },
      );
    } catch (_) {
      // No interrumpimos el flujo si el push falla
    }
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

    try {
      // 2. Push real a todos los admins de la empresa
      await _client.functions.invoke(
        'send-push',
        body: {
          'to_role': 'ADMIN',
          'company_id': companyId,
          'title': title,
          'body': body,
          'data': {'route': route ?? '', 'type': type},
        },
      );
    } catch (_) {}
  }

  // ── Leer ───────────────────────────────────────────────────────────────────

  /// Obtiene las notificaciones del usuario actual (últimas 50).
  Future<List<AppNotification>> fetchMine() async {
    try {
      final rows = await _client
          .from(_table)
          .select()
          .order('created_at', ascending: false)
          .limit(50);
      return (rows as List)
          .map((r) => AppNotification.fromMap(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Cuenta las notificaciones no leídas del usuario actual.
  Future<int> countUnread() async {
    try {
      final rows = await _client
          .from(_table)
          .select('id')
          .eq('is_read', false);
      return (rows as List).length;
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

  Future<void> markAllRead(String companyId) async {
    try {
      await _client
          .from(_table)
          .update({'is_read': true})
          .eq('company_id', companyId)
          .eq('is_read', false);
    } catch (_) {}
  }
}
