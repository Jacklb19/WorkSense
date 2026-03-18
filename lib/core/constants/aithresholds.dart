/// Umbrales y constantes del AI Pipeline de WorkSense.
///
/// REGLA: Ningún valor numérico del clasificador va hardcodeado en el código.
/// Todo pasa por esta clase. Los valores pueden sobreescribirse desde Settings
/// (el ADMIN los ajusta por tipo de puesto).
abstract final class AiThresholds {
  // ─────────────────────────────────────────────────────────
  // CONFIANZA MÍNIMA
  // ─────────────────────────────────────────────────────────

  /// Confianza mínima promedio de landmarks para considerar
  /// que hay una persona detectada. Por debajo → AUSENTE.
  static const double minPoseConfidence = 0.70;

  /// Confianza mínima del resultado final del clasificador
  /// para generar un evento. Por debajo → se descarta.
  static const double minClassificationConfidence = 0.65;

  // ─────────────────────────────────────────────────────────
  // FACE ANALYZER — ángulos de cabeza (grados)
  // ─────────────────────────────────────────────────────────

  /// Yaw (rotación horizontal). Superar este valor → DISTRAÍDO.
  /// Positivo = derecha, negativo = izquierda.
  static const double maxYawAngle = 30.0;

  /// Pitch (rotación vertical hacia abajo). Caer por debajo → FATIGA.
  /// Negativo = cabeza caída hacia adelante.
  static const double minPitchAngle = -20.0;

  /// Roll (inclinación lateral). Superar este valor → FATIGA.
  static const double maxRollAngle = 25.0;

  /// Rango normal de trabajo (referencia, no dispara alertas).
  static const double normalYawRange = 15.0;
  static const double normalPitchRange = 10.0;
  static const double normalRollRange = 15.0;

  // ─────────────────────────────────────────────────────────
  // POSE ANALYZER — landmarks (índices ML Kit)
  // ─────────────────────────────────────────────────────────

  /// Índice del landmark nariz (referencia para distancia manos-rostro).
  static const int landmarkNose = 0;

  /// Índices de muñecas para detectar actividad de manos.
  static const int landmarkLeftWrist = 15;
  static const int landmarkRightWrist = 16;

  /// Índices de hombros para calcular inclinación del torso.
  static const int landmarkLeftShoulder = 11;
  static const int landmarkRightShoulder = 12;

  /// Desplazamiento mínimo de muñeca entre frames (normalizado 0–1)
  /// para considerar que las manos están activas.
  static const double minWristMovement = 0.02;

  /// Distancia máxima mano–nariz (normalizada) para detectar
  /// uso de teléfono o gesto cerca del rostro → DISTRAÍDO.
  static const double maxHandToFaceDistance = 0.15;

  /// Ángulo máximo de inclinación del torso (hombros) en grados
  /// antes de considerar postura de fatiga.
  static const double maxTorsoTiltAngle = 20.0;

  // ─────────────────────────────────────────────────────────
  // ACTIVITY CLASSIFIER — tiempos
  // ─────────────────────────────────────────────────────────

  /// Segundos sin movimiento de manos para clasificar como INACTIVO.
  static const int inactivityThresholdSeconds = 60;

  /// Segundos en estado AUSENTE antes de generar alerta.
  static const int absenceAlertThresholdSeconds = 300; // 5 min

  /// Segundos en estado INACTIVO antes de generar alerta.
  static const int inactivityAlertThresholdSeconds = 600; // 10 min

  /// Número de veces que DISTRAÍDO debe aparecer en 1 hora
  /// para generar alerta de distracción repetida.
  static const int distractionCountThreshold = 5;

  // ─────────────────────────────────────────────────────────
  // INTERVALO DE ANÁLISIS
  // ─────────────────────────────────────────────────────────

  /// Intervalo por defecto entre análisis de frames (segundos).
  static const int defaultAnalysisIntervalSeconds = 30;

  /// Intervalo mínimo permitido (no bajar de esto para no saturar CPU).
  static const int minAnalysisIntervalSeconds = 10;

  /// Intervalo máximo permitido.
  static const int maxAnalysisIntervalSeconds = 120;

  // ─────────────────────────────────────────────────────────
  // EMBEDDING / RECONOCIMIENTO FACIAL
  // ─────────────────────────────────────────────────────────

  /// Similitud coseno mínima para considerar un match de empleado.
  /// Por debajo → "empleado no identificado".
  static const double minEmbeddingMatchScore = 0.75;

  /// Número de fotos requeridas para registrar un empleado.
  static const int requiredFacePhotos = 5;

  /// Dimensión del vector de embedding facial.
  static const int embeddingDimension = 128;

  // ─────────────────────────────────────────────────────────
  // OVERLAY DE IA (Kiosk Mode)
  // ─────────────────────────────────────────────────────────

  /// Milisegundos sin nuevo resultado del pipeline antes de
  /// hacer fade-out del overlay.
  static const int overlayFadeOutMs = 2000;

  /// Grosor del rectángulo facial en el overlay (lógico px).
  static const double overlayFaceRectStroke = 2.5;

  /// Grosor de las líneas del stick figure de pose.
  static const double overlaySkeletonStroke = 2.0;

  AiThresholds._();
}