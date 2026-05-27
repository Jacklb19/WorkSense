import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';

/// Clasifica el estado de actividad del empleado basándose exclusivamente
/// en señales del rostro detectadas por MLKit Face Detection.
///
/// Estados posibles y sus señales:
/// ─────────────────────────────────────────────────────────────────────────
/// [ActivityState.ausente]        → No se detecta ni rostro ni cuerpo.
/// [ActivityState.noIdentificado] → Se detecta cuerpo pero no hay rostro.
/// [ActivityState.fatiga]         → Ojos cerrados + cabeza caída (pitch bajo)
///                                  o inclinada lateralmente (roll alto).
/// [ActivityState.inactivo]       → Ojos cerrados sin señales de fatiga
///                                  (descanso visual momentáneo).
/// [ActivityState.trabajando]     → Mirando abajo con ojos abiertos
///                                  (lectura, trabajo manual) O rostro
///                                  al frente con ojos abiertos (default).
/// [ActivityState.distraido]      → Cabeza girada significativamente
///                                  (yaw > umbral).
/// ─────────────────────────────────────────────────────────────────────────
///
/// La clasificación pasa por un suavizado EMA para evitar parpadeos de estado.
class ActivityClassifier {
  static const double _alpha = 0.3;
  final Map<ActivityState, double> _stateEma = {};

  /// Devuelve el estado de actividad clasificado con suavizado temporal.
  AiResult classify({
    required PoseAnalysisResult pose,
    required FaceAnalysisResult face,
  }) {
    final rawResult = _applyDecisionTable(pose: pose, face: face);

    // Inicializar o actualizar el EMA por estado
    if (_stateEma.isEmpty) {
      for (final state in ActivityState.values) {
        _stateEma[state] = state == rawResult.state ? 1.0 : 0.0;
      }
    } else {
      for (final state in ActivityState.values) {
        final double target = state == rawResult.state ? 1.0 : 0.0;
        _stateEma[state] =
            (_alpha * target) + ((1 - _alpha) * _stateEma[state]!);
      }
    }

    // Estado suavizado = el que tiene mayor EMA
    ActivityState smoothedState = rawResult.state;
    double maxEma = -1.0;
    _stateEma.forEach((state, ema) {
      if (ema > maxEma) {
        maxEma = ema;
        smoothedState = state;
      }
    });

    return AiResult(
      state: smoothedState,
      confidence: rawResult.confidence,
    );
  }

  /// Tabla de decisión basada en señales faciales.
  /// Orden: de mayor a menor especificidad/gravedad.
  AiResult _applyDecisionTable({
    required PoseAnalysisResult pose,
    required FaceAnalysisResult face,
  }) {
    final alguienPresente = face.faceDetected || pose.personDetected;

    // 1. Nadie en frame
    if (!alguienPresente) {
      return const AiResult(state: ActivityState.ausente, confidence: 0.85);
    }

    // 2. Hay cuerpo pero sin rostro (de espaldas, fuera de cuadro)
    if (!face.faceDetected) {
      return const AiResult(
          state: ActivityState.noIdentificado, confidence: 0.50);
    }

    final yawAbsolute = face.yaw.abs();
    final isLookingDown = face.pitch < AiThresholds.minPitchAngle;

    // 3. FATIGA: ojos cerrados + cabeza caída o inclinada lateralmente
    if (face.eyesClosed &&
        (isLookingDown || face.roll.abs() > AiThresholds.maxRollAngle)) {
      return const AiResult(state: ActivityState.fatiga, confidence: 0.85);
    }

    // 4. INACTIVO: solo ojos cerrados (sin señales de fatiga)
    //    → descanso visual momentáneo, pestañeo prolongado
    if (face.eyesClosed) {
      return const AiResult(state: ActivityState.inactivo, confidence: 0.70);
    }

    // 5. TRABAJANDO: mirando hacia abajo con ojos abiertos
    //    → lectura de documentos, trabajo manual cerca del escritorio
    if (isLookingDown) {
      return const AiResult(state: ActivityState.trabajando, confidence: 0.80);
    }

    // 6. DISTRAÍDO EXTREMO: cabeza muy girada lateralmente
    if (yawAbsolute > AiThresholds.maxYawAngle + 15.0) {
      return const AiResult(
          state: ActivityState.distraido, confidence: 0.75);
    }

    // 7. DISTRAÍDO MODERADO: mirando a un lado por encima del umbral normal
    if (yawAbsolute > AiThresholds.maxYawAngle) {
      return const AiResult(
          state: ActivityState.distraido, confidence: 0.65);
    }

    // 8. DEFAULT: rostro al frente, ojos abiertos → TRABAJANDO
    return const AiResult(state: ActivityState.trabajando, confidence: 0.90);
  }

  /// Reinicia el buffer de suavizado (llamar al reiniciar la sesión).
  void reset() {
    _stateEma.clear();
  }
}
