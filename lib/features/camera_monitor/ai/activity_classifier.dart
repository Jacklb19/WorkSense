import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';

class ActivityClassifier {
  static const double _alpha = 0.3;
  final Map<ActivityState, double> _stateEma = {};

  AiResult classify({
    required PoseAnalysisResult pose,
    required FaceAnalysisResult face,
    required bool isInactive,
  }) {
    final rawResult = _applyDecisionTable(
      pose: pose,
      face: face,
      isInactive: isInactive,
    );

    if (_stateEma.isEmpty) {
      for (final state in ActivityState.values) {
        _stateEma[state] = state == rawResult.state ? 1.0 : 0.0;
      }
    } else {
      for (final state in ActivityState.values) {
        final double target = state == rawResult.state ? 1.0 : 0.0;
        _stateEma[state] = (_alpha * target) + ((1 - _alpha) * _stateEma[state]!);
      }
    }

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

  AiResult _applyDecisionTable({
    required PoseAnalysisResult pose,
    required FaceAnalysisResult face,
    required bool isInactive,
  }) {
    final alguienPresente = face.faceDetected || pose.personDetected;
    if (!alguienPresente) {
      return const AiResult(state: ActivityState.ausente, confidence: 0.85);
    }

    if (!face.faceDetected) {
      // Se detecta cuerpo pero no rostro. Podría estar de espaldas.
      // Ya no asumimos que está trabajando a ciegas.
      return const AiResult(state: ActivityState.noIdentificado, confidence: 0.50);
    }

    final yawAbsolute = face.yaw.abs();
    final isLookingDown = face.pitch < AiThresholds.minPitchAngle;

    // Fatiga real: Ojos cerrados + cabeza caída
    if (face.eyesClosed && (isLookingDown || face.roll.abs() > AiThresholds.maxRollAngle)) {
      return const AiResult(state: ActivityState.fatiga, confidence: 0.85);
    }

    // Solo ojos cerrados (descanso visual momentáneo)
    if (face.eyesClosed) {
      return const AiResult(state: ActivityState.inactivo, confidence: 0.70);
    }

    // Trabajo manual o lectura: Mirando hacia abajo pero con ojos abiertos
    if (isLookingDown && !face.eyesClosed) {
      return const AiResult(state: ActivityState.trabajando, confidence: 0.80);
    }

    // Distracción extrema: Cabeza completamente girada por mucho tiempo
    if (yawAbsolute > AiThresholds.maxYawAngle + 15.0) {
      return const AiResult(state: ActivityState.distraido, confidence: 0.75);
    }

    // Inactividad: No hay movimiento y la PC reporta inactividad
    if (isInactive && !pose.handsMoving) {
      // Si tiene la mano en la cara, podría estar pensando/leyendo
      if (pose.handNearFace) {
        return const AiResult(state: ActivityState.trabajando, confidence: 0.60);
      }
      return const AiResult(state: ActivityState.inactivo, confidence: 0.80);
    }

    // Distracción leve: Mirando ligeramente a un lado con mano en la cara
    if (yawAbsolute > AiThresholds.maxYawAngle && pose.handNearFace) {
       return const AiResult(state: ActivityState.distraido, confidence: 0.65);
    }

    // Default: Presente, ojos abiertos, mirando al frente
    return const AiResult(state: ActivityState.trabajando, confidence: 0.90);
  }

  /// Reset smoothing buffer (call when monitoring session restarts)
  void reset() {
    _stateEma.clear();
  }
}
