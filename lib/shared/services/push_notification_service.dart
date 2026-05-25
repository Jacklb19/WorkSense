import 'dart:async';
import 'dart:io';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/shared/services/notification_service.dart';

// ── Handler de mensajes en background (debe ser top-level) ───────────────────

/// Llamado por FCM cuando llega un mensaje y la app está cerrada o en background.
/// IMPORTANTE: esta función corre en un isolate separado — no puede acceder a
/// state de la UI. Solo guardamos el mensaje y el sistema lo muestra automáticamente.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Firebase se inicializa automáticamente en Android con google-services.json
  debugPrint('[FCM] Mensaje background: ${message.notification?.title}');
  // FCM muestra la notificación del sistema automáticamente cuando la app está
  // en background/killed. No necesitamos hacer nada aquí para ese caso.
}

// ── Servicio principal ────────────────────────────────────────────────────────

class PushNotificationService {
  PushNotificationService._();
  static final PushNotificationService instance = PushNotificationService._();

  final _messaging = FirebaseMessaging.instance;

  /// Stream de rutas pendientes de navegación (emitido al tocar una notificación).
  final _routeController = StreamController<String>.broadcast();
  Stream<String> get navigationStream => _routeController.stream;

  bool _initialized = false;

  // ── Canal Android para foreground ─────────────────────────────────────────

  static const _channel = AndroidNotificationChannel(
    'worksense_push',          // debe coincidir con AndroidManifest meta-data
    'WorkSense',
    description: 'Notificaciones push de WorkSense',
    importance: Importance.high,
    playSound: true,
  );

  // ── Inicializar ───────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    // 1. Registrar handler de background ANTES de cualquier otra llamada FCM
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // 2. Crear canal Android para que las notificaciones en foreground funcionen
    await _createAndroidChannel();

    // 3. Pedir permisos (Android 13+ los pide explícitamente; iOS también)
    final settings = await _messaging.requestPermission(
      alert: true,
      announcement: false,
      badge: true,
      carPlay: false,
      criticalAlert: false,
      provisional: false,
      sound: true,
    );

    debugPrint('[FCM] Permiso: ${settings.authorizationStatus}');

    // 4. Obtener y guardar el token inicial
    final token = await _messaging.getToken();
    if (token != null) {
      debugPrint('[FCM] Token: $token');
      await _saveToken(token);
    }

    // 5. Escuchar renovaciones de token
    _messaging.onTokenRefresh.listen(_saveToken);

    // 6. Mensajes mientras la app está en FOREGROUND
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // 7. El usuario tocó una notificación con app en BACKGROUND
    FirebaseMessaging.onMessageOpenedApp.listen(_handleTap);

    // 8. App abierta desde KILLED al tocar una notificación
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _handleTap(initial);

    _initialized = true;
    debugPrint('[FCM] PushNotificationService inicializado ✓');
  }

  // ── Foreground: mostrar con flutter_local_notifications ───────────────────

  Future<void> _handleForeground(RemoteMessage message) async {
    debugPrint('[FCM] Foreground: ${message.notification?.title}');
    final n = message.notification;
    if (n == null) return;

    await NotificationService.instance.showPush(
      title: n.title ?? '',
      body: n.body ?? '',
      payload: message.data['route'] ?? '',
    );
  }

  // ── Tap en notificación → navegar ─────────────────────────────────────────

  void _handleTap(RemoteMessage message) {
    final route = message.data['route'] as String?;
    debugPrint('[FCM] Tap → route: $route');
    if (route != null && route.isNotEmpty) {
      _routeController.add(route);
    }
  }

  // ── Guardar token en Supabase ─────────────────────────────────────────────

  Future<void> _saveToken(String token) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) return;

      await Supabase.instance.client.from('fcm_tokens').upsert({
        'user_id': userId,
        'token': token,
        'platform': Platform.isAndroid ? 'android' : 'ios',
        'updated_at': DateTime.now().toIso8601String(),
      });

      debugPrint('[FCM] Token guardado para usuario $userId');
    } catch (e) {
      debugPrint('[FCM] Error guardando token: $e');
    }
  }

  /// Llama esto al hacer login para asegurarte de guardar el token.
  Future<void> refreshTokenForCurrentUser() async {
    final token = await _messaging.getToken();
    if (token != null) await _saveToken(token);
  }

  /// Elimina el token al cerrar sesión para no recibir notificaciones de
  /// usuarios anteriores en el mismo dispositivo.
  Future<void> deleteTokenOnLogout() async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) {
        await Supabase.instance.client
            .from('fcm_tokens')
            .delete()
            .eq('user_id', userId);
      }
      await _messaging.deleteToken();
    } catch (_) {}
  }

  // ── Crear canal Android ───────────────────────────────────────────────────

  Future<void> _createAndroidChannel() async {
    final plugin = NotificationService.instance.plugin;
    await plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(_channel);
  }

  void dispose() {
    _routeController.close();
  }
}
