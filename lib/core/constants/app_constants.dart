/// Constantes generales de la aplicación WorkSense.
abstract final class AppConstants {
  AppConstants._();

  // ─────────────────────────────────────────────────────────
  // APP
  // ─────────────────────────────────────────────────────────
  static const String appName = 'WorkSense';
  static const String appVersion = '1.0.0';

  // ─────────────────────────────────────────────────────────
  // DEFAULT IDS
  // ─────────────────────────────────────────────────────────
  static const String defaultCompanyId = 'default';

  // ─────────────────────────────────────────────────────────
  // ROLES DE USUARIO
  // ─────────────────────────────────────────────────────────
  static const String roleSuperAdmin = 'SUPER_ADMIN';
  static const String roleAdmin = 'ADMIN';
  static const String roleEmployee = 'EMPLOYEE';
  static const String roleCameraMonitor = 'CAMERA_MONITOR';

  // ─────────────────────────────────────────────────────────
  // SUPABASE — nombres de tablas
  // ─────────────────────────────────────────────────────────
  static const String tableCompanies = 'companies';
  static const String tableEmployees = 'employees';
  static const String tableWorkstations = 'workstations';
  static const String tableActivityEvents = 'activity_events';
  static const String tableAlerts = 'alerts';
  static const String tableFaceEmbeddings = 'face_embeddings';

  // ─────────────────────────────────────────────────────────
  // SUPABASE — Storage
  // ─────────────────────────────────────────────────────────
  static const String bucketFaceEmbeddings = 'face-embeddings';

  // ─────────────────────────────────────────────────────────
  // SYNC ENGINE
  // ─────────────────────────────────────────────────────────
  static const int syncMaxRetries = 5;

  /// Tiempos de backoff exponencial en segundos por intento.
  static const List<int> syncBackoffSeconds = [0, 30, 120, 300, 600];

  // ─────────────────────────────────────────────────────────
  // GEOVALLA
  // ─────────────────────────────────────────────────────────

  /// Radio de geovalla por defecto en metros.
  static const double defaultGeofenceRadiusMeters = 50.0;

  /// Radio mínimo permitido.
  static const double minGeofenceRadiusMeters = 10.0;

  /// Radio máximo permitido.
  static const double maxGeofenceRadiusMeters = 500.0;

  // ─────────────────────────────────────────────────────────
  // UI
  // ─────────────────────────────────────────────────────────

  /// Duración estándar de animaciones en la app.
  static const Duration animationDuration = Duration(milliseconds: 300);

  /// Duración de snackbars informativas.
  static const Duration snackBarDuration = Duration(seconds: 3);

  /// Máximo de puestos antes de activar paginación en el dashboard.
  static const int dashboardPaginationThreshold = 20;
}