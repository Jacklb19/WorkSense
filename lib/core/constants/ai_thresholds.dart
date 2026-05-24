/// Umbrales y constantes del AI Pipeline de WorkSense.
///
/// REGLA: Ningun valor numerico del clasificador va hardcodeado en el codigo.
/// Todo pasa por esta clase. Los valores pueden sobreescribirse desde Settings
/// (el ADMIN los ajusta por tipo de puesto).
abstract final class AiThresholds {
  // CONFIANZA MINIMA

  /// Confianza minima promedio de landmarks para considerar
  /// que hay una persona detectada. Por debajo -> AUSENTE.
  static const double minPoseConfidence = 0.45;

  /// Confianza minima del resultado final del clasificador
  /// para generar un evento. Por debajo -> se descarta.
  static const double minClassificationConfidence = 0.40;

  // FACE ANALYZER - angulos de cabeza (grados)

  /// Yaw (rotacion horizontal). Superar este valor -> DISTRAIDO.
  /// Positivo = derecha, negativo = izquierda.
  static const double maxYawAngle = 30.0;

  /// Pitch (rotacion vertical hacia abajo). Caer por debajo -> FATIGA.
  /// Negativo = cabeza caida hacia adelante.
  static const double minPitchAngle = -20.0;

  /// Roll (inclinacion lateral). Superar este valor -> FATIGA.
  static const double maxRollAngle = 25.0;

  /// Rango normal de trabajo (referencia, no dispara alertas).
  static const double normalYawRange = 15.0;
  static const double normalPitchRange = 10.0;
  static const double normalRollRange = 15.0;

  // POSE ANALYZER - landmarks (indices ML Kit)

  /// Indice del landmark nariz (referencia para distancia manos-rostro).
  static const int landmarkNose = 0;

  /// Indices de munecas para detectar actividad de manos.
  static const int landmarkLeftWrist = 15;
  static const int landmarkRightWrist = 16;

  /// Indices de hombros para calcular inclinacion del torso.
  static const int landmarkLeftShoulder = 11;
  static const int landmarkRightShoulder = 12;

  /// Desplazamiento minimo de muneca entre frames (normalizado 0-1)
  /// para considerar que las manos estan activas.
  static const double minWristMovement = 0.02;

  /// Distancia maxima mano-nariz (normalizada) para detectar
  /// uso de telefono o gesto cerca del rostro -> DISTRAIDO.
  static const double maxHandToFaceDistance = 0.15;

  /// Angulo maximo de inclinacion del torso (hombros) en grados
  /// antes de considerar postura de fatiga.
  static const double maxTorsoTiltAngle = 20.0;

  // ACTIVITY CLASSIFIER - tiempos

  /// Segundos sin movimiento de manos para clasificar como INACTIVO.
  static const int inactivityThresholdSeconds = 60;

  /// Segundos en estado AUSENTE antes de generar alerta.
  static const int absenceAlertThresholdSeconds = 300;

  /// Segundos en estado INACTIVO antes de generar alerta.
  static const int inactivityAlertThresholdSeconds = 600;

  /// Numero de veces que DISTRAIDO debe aparecer en 1 hora
  /// para generar alerta de distraccion repetida.
  static const int distractionCountThreshold = 5;

  // INTERVALO DE ANALISIS

  /// Intervalo por defecto entre analisis de frames (segundos).
  static const int defaultAnalysisIntervalSeconds = 30;

  /// Intervalo minimo permitido (no bajar de esto para no saturar CPU).
  static const int minAnalysisIntervalSeconds = 10;

  /// Intervalo maximo permitido.
  static const int maxAnalysisIntervalSeconds = 120;

  // EMBEDDING / RECONOCIMIENTO FACIAL

  /// Similitud coseno minima para considerar un match de empleado.
  /// Por debajo -> "empleado no identificado".
  static const double minEmbeddingMatchScore = 0.75;

  /// Umbral de distancia euclidiana/coseno para el modelo tflite.
  static const double faceMatchThreshold = 0.82;

  /// Tiempo minimo de bloqueo (en minutos) tras multiples fallos biometricos.
  static const int faceMatchLockMin = 5;

  /// Numero de posiciones requeridas para registrar un empleado.
  static const int requiredFacePhotos = 8;

  /// Dimension del vector de embedding facial (MobileFaceNet).
  static const int embeddingDimension = 192;

  /// Intervalo para re-verificar la identidad real (embeddings) en segundos.
  static const int reidIntervalSeconds = 4;

  // MOBILEFACENET Y RECORTE FACIAL

  /// Dimension esperada por MobileFaceNet (112x112).
  static const int faceInputSize = 112;

  /// Factor de padding al recortar la cara original (ej. 0.15 = 15%).
  static const double facePaddingFactor = 0.15;

  /// Iluminacion minima recomendada para aceptar un crop facial.
  static const double minFaceBrightness = 0.15;

  /// Iluminacion maxima antes de considerar el rostro sobreexpuesto.
  static const double maxFaceBrightness = 0.88;

  /// Contraste minimo normalizado del crop facial.
  static const double minFaceContrast = 0.06;

  /// Nitidez minima normalizada del crop facial.
  static const double minFaceSharpness = 0.05;

  /// Numero de tomas rapidas por pose durante el enrolamiento.
  static const int scanBurstFrames = 5;

  /// Separacion entre tomas del burst biometrico.
  static const int scanBurstDelayMs = 80;

  /// Probabilidad minima para considerar que ambos ojos estan abiertos.
  static const double minEyeOpenProbability = 0.55;

  /// Probabilidad maxima para considerar que ambos ojos estan cerrados.
  static const double maxEyeClosedProbability = 0.35;

  /// Frames consecutivos con ojos abiertos antes de armar el blink challenge.
  static const int blinkOpenFramesRequired = 2;

  /// Calidad global minima para aceptar un crop borderline si la cara es fuerte.
  static const double minSoftFaceQualityScore = 0.55;

  /// Calidad minima del crop facial para aceptar una muestra durante enrolamiento.
  /// Valor mas permisivo que el gate de kiosk para reducir friccion.
  static const double enrollMinCropQuality = 0.50;

  /// Confianza facial minima para aplicar soft-accept durante enrolamiento.
  static const double enrollSoftAcceptFaceConf = 0.50;

  /// Frames estables requeridos antes de marcar el scanner como listo.
  static const int liveDetectionStableFrames = 2;

  /// Cobertura minima del rostro en el frame para validar presencia.
  static const double minLiveFaceAreaRatio = 0.10;

  /// Margen minimo para mantener el rostro dentro de la zona central util.
  static const double liveFaceGuideMargin = 0.16;

  /// Media usada para normalizar los canales de color.
  static const double faceColorMean = 127.5;

  /// Desviacion usada para normalizar los canales de color.
  static const double faceColorStd = 128.0;

  // SCANNER DE ENTRADA (Entrance Kiosk)

  /// Similitud coseno minima para aceptar un match en el kiosk de entrada.
  static const double entranceMatchThreshold = 0.78;

  /// Margen por debajo del threshold donde el scanner sigue intentando
  /// en vez de rechazar inmediatamente (zona de "casi match").
  static const double entranceNearMatchMargin = 0.06;

  /// Observaciones positivas (frames con score >= threshold para el mismo
  /// empleado) requeridas dentro de la ventana para confirmar identidad.
  static const int entranceRequiredConfirmations = 2;

  /// Tamano maximo de la ventana de evidencia (frames evaluados tras blink).
  /// Si se agotan sin confirmacion, se declara no-match.
  static const int entranceEvidenceWindowSize = 6;

  /// Ratio minimo de ancho del rostro vs ancho del frame para considerar
  /// que el usuario esta suficientemente cerca.
  static const double entranceMinFaceWidthRatio = 0.22;

  /// Angulo maximo de yaw/pitch permitido para evaluar un frame en entrada.
  static const double entranceMaxHeadAngle = 15.0;

  /// Intervalo minimo entre analisis de frames en el scanner de entrada (ms).
  static const int entranceFrameIntervalMs = 250;

  /// Probabilidad maxima de apertura ocular para considerar un parpadeo valido
  /// en el kiosk de entrada. Ambos ojos deben estar por debajo de este valor.
  static const double entranceBlinkClosedThreshold = 0.45;

  /// Cantidad maxima de extensiones de ventana por near-match antes de declarar
  /// no-match definitivo. Evita loops infinitos de retry.
  static const int entranceMaxNearMatchRetries = 1;

  // OVERLAY DE IA (Kiosk Mode)

  /// Milisegundos sin nuevo resultado del pipeline antes de
  /// hacer fade-out del overlay.
  static const int overlayFadeOutMs = 2000;

  /// Grosor del rectangulo facial en el overlay (logico px).
  static const double overlayFaceRectStroke = 2.5;

  /// Grosor de las lineas del stick figure de pose.
  static const double overlaySkeletonStroke = 2.0;

  // MONITOR DE PUESTO (Workstation Kiosk)

  /// Intervalo de re-identificacion por embeddings durante sesion activa estable
  /// (una sola cara, tracking lockeado). Reduce costo computacional.
  static const int monitorStableReidSeconds = 15;

  /// Intervalo de re-identificacion cuando hay ambiguedad (multiples caras,
  /// tracking perdido, o identidad recien forzada a revalidar).
  static const int monitorAmbiguousReidSeconds = 4;

  /// Frames consecutivos sin encontrar al empleado antes de soltar el tracking lock.
  static const int monitorMaxConsecutiveMisses = 12;

  /// Frames consecutivos con rostro ausente o no reconocido antes de forzar
  /// revalidacion de identidad. Grace period para tolerar micro-ausencias.
  static const int monitorGracePeriodFrames = 4;

  /// Umbral minimo de similitud coseno en modo tracking. Mas bajo que el de
  /// identificacion fresca porque el tracking ID ya provee continuidad.
  static const double monitorTrackingEmbeddingFloor = 0.78;

  /// Retención local para eventos crudos aún no consolidados/sincronizados.
  static const int rawEventsRetentionDays = 5;

  AiThresholds._();
}
