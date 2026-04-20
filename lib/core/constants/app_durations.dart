/// Duraciones centralizadas de WorkSense.
/// Animaciones, timeouts y delays.
abstract final class AppDurations {
  AppDurations._();

  // ─────────────────────────────────────────────────────────
  // SCAN
  // ─────────────────────────────────────────────────────────

  /// Delay después de una captura exitosa antes de reanudar feedback.
  static const Duration scanBlockDelay = Duration(milliseconds: 1500);

  /// Delay después de un error de captura antes de reanudar feedback.
  static const Duration scanErrorDelay = Duration(milliseconds: 2000);

  /// Delay antes de navegar tras completar el escaneo.
  static const Duration scanCompleteDelay = Duration(milliseconds: 800);

  // ─────────────────────────────────────────────────────────
  // ALERTS
  // ─────────────────────────────────────────────────────────

  /// Duración del snackbar de alerta en modo kiosco.
  static const Duration alertSnackBarDuration = Duration(seconds: 5);

  /// Intervalo de verificación de umbrales de alerta.
  static const Duration alertCheckInterval = Duration(seconds: 1);

  /// Segundos de ausencia antes de disparar alerta visual.
  static const int absenceAlertSeconds = 60;

  /// Segundos de distracción antes de disparar alerta visual.
  static const int distractionAlertSeconds = 45;
}
