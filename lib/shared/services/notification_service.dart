import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter/foundation.dart';

/// Servicio de notificaciones locales para WorkSense.
/// Se inicializa en main.dart una vez al arrancar la app.
class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Expuesto para que PushNotificationService pueda crear canales Android.
  FlutterLocalNotificationsPlugin get plugin => _plugin;

  bool _initialized = false;

  // ── Canales ───────────────────────────────────────────────────────────────

  static const String _channelTaskId = 'worksense_tasks';
  static const String _channelLeaveId = 'worksense_leaves';
  static const String _channelAlertId = 'worksense_alerts';
  static const String _channelAnnouncementId = 'worksense_announcements';

  // ── Inicialización ────────────────────────────────────────────────────────

  Future<void> initialize() async {
    if (_initialized) return;

    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosInit = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    const settings = InitializationSettings(
      android: androidInit,
      iOS: iosInit,
    );

    await _plugin.initialize(settings);
    _initialized = true;
    debugPrint('[NotificationService] Initialized.');
  }

  Future<void> requestPermissions() async {
    final android = _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    await android?.requestNotificationsPermission();
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  NotificationDetails _details({
    required String channelId,
    required String channelName,
    required String channelDesc,
    Importance importance = Importance.high,
    Priority priority = Priority.high,
  }) {
    return NotificationDetails(
      android: AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDesc,
        importance: importance,
        priority: priority,
        showWhen: true,
      ),
      iOS: const DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );
  }

  // ── Disparadores ─────────────────────────────────────────────────────────

  /// Notifica al empleado cuando se le asigna una nueva tarea.
  Future<void> notifyTaskAssigned(String taskTitle) async {
    if (!_initialized) return;
    await _plugin.show(
      1001,
      '📋 Nueva tarea asignada',
      taskTitle,
      _details(
        channelId: _channelTaskId,
        channelName: 'Tareas',
        channelDesc: 'Notificaciones de tareas asignadas',
      ),
    );
  }

  /// Notifica al empleado cuando su solicitud de permiso es revisada.
  Future<void> notifyLeaveReviewed({
    required bool approved,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    if (!_initialized) return;
    final status = approved ? 'aprobada ✅' : 'rechazada ❌';
    await _plugin.show(
      1002,
      'Solicitud de permiso $status',
      approved
          ? 'Tu permiso del ${_fmtDate(startDate)} al ${_fmtDate(endDate)} fue aprobado.'
          : 'Tu solicitud de permiso fue rechazada. Contacta a tu administrador.',
      _details(
        channelId: _channelLeaveId,
        channelName: 'Permisos',
        channelDesc: 'Notificaciones de solicitudes de permiso',
        importance: approved ? Importance.defaultImportance : Importance.high,
      ),
    );
  }

  /// Notifica sobre un nuevo comunicado.
  Future<void> notifyAnnouncement(String title) async {
    if (!_initialized) return;
    await _plugin.show(
      1003,
      '📢 Nuevo comunicado',
      title,
      _details(
        channelId: _channelAnnouncementId,
        channelName: 'Comunicados',
        channelDesc: 'Anuncios y comunicados de la empresa',
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
      ),
    );
  }

  /// Notifica sobre una alerta de monitoreo (opcional, informativa).
  Future<void> notifyAlert(String alertLabel) async {
    if (!_initialized) return;
    await _plugin.show(
      1005,
      '⚠️ Alerta de monitoreo',
      alertLabel,
      _details(
        channelId: _channelAlertId,
        channelName: 'Alertas',
        channelDesc: 'Alertas de ausencia, distracción o fatiga',
        importance: Importance.max,
      ),
    );
  }

  /// Notifica al admin cuando se envía una solicitud de permiso.
  Future<void> notifyLeaveRequest(String employeeName) async {
    if (!_initialized) return;
    await _plugin.show(
      1004,
      '📩 Nueva solicitud de permiso',
      '$employeeName solicitó un permiso. Revísala en la app.',
      _details(
        channelId: _channelLeaveId,
        channelName: 'Permisos',
        channelDesc: 'Notificaciones de solicitudes de permiso',
      ),
    );
  }

  /// Muestra una notificación local recibida desde FCM (app en foreground).
  Future<void> showPush({
    required String title,
    required String body,
    String? payload,
  }) async {
    if (!_initialized) return;
    await _plugin.show(
      title.hashCode & 0x7FFFFFFF, // ID determinístico basado en el título
      title,
      body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'worksense_push',
          'WorkSense',
          channelDescription: 'Notificaciones push de WorkSense',
          importance: Importance.high,
          priority: Priority.high,
          showWhen: true,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
      payload: payload,
    );
  }

  String _fmtDate(DateTime d) => '${d.day}/${d.month}/${d.year}';
}
