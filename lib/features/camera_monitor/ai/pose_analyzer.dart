import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';

/// Analiza la pose corporal detectada por MLKit.
///
/// Responsabilidad: determinar si hay una persona presente y calcular
/// el ángulo de hombros (postura del torso).
/// La clasificación de actividad se delega completamente a [ActivityClassifier]
/// usando señales del rostro — los estados ya no dependen de movimiento de manos.
class PoseAnalyzer {
  PoseAnalysisResult analyzeSingle(Pose? pose, double imageWidth) {
    if (pose == null) return PoseAnalysisResult.empty;
    return _analyzeOnePose(pose, imageWidth);
  }

  PoseAnalysisResult analyze(List<Pose> poses, double imageWidth) {
    if (poses.isEmpty) return PoseAnalysisResult.empty;
    return _analyzeOnePose(poses.first, imageWidth);
  }

  PoseAnalysisResult _analyzeOnePose(Pose pose, double imageWidth) {
    final landmarks = pose.landmarks;

    // Los tres landmarks mínimos requeridos para confirmar presencia corporal
    final nose = _getLandmarkIfReliable(landmarks, PoseLandmarkType.nose);
    final leftShoulder =
        _getLandmarkIfReliable(landmarks, PoseLandmarkType.leftShoulder);
    final rightShoulder =
        _getLandmarkIfReliable(landmarks, PoseLandmarkType.rightShoulder);

    if (nose == null || leftShoulder == null || rightShoulder == null) {
      return PoseAnalysisResult.empty;
    }

    // Confianza promedio de los landmarks clave
    final keyLandmarks = [nose, leftShoulder, rightShoulder];
    final avgConfidence = keyLandmarks
            .map((l) => l.likelihood)
            .reduce((a, b) => a + b) /
        keyLandmarks.length;

    if (avgConfidence < AiThresholds.minPoseConfidence) {
      return PoseAnalysisResult.empty;
    }

    // Ángulo de inclinación del torso (hombros)
    final shoulderAngle =
        _calculateShoulderAngle(leftShoulder, rightShoulder);

    return PoseAnalysisResult(
      personDetected: true,
      shoulderAngle: shoulderAngle,
      poseConfidence: avgConfidence,
    );
  }

  double _calculateShoulderAngle(
      PoseLandmark leftShoulder, PoseLandmark rightShoulder) {
    final dx = rightShoulder.x - leftShoulder.x;
    final dy = rightShoulder.y - leftShoulder.y;
    return math.atan2(dy, dx) * (180 / math.pi);
  }

  /// Devuelve el landmark solo si existe y su likelihood >= 0.6.
  PoseLandmark? _getLandmarkIfReliable(
      Map<PoseLandmarkType, PoseLandmark> landmarks, PoseLandmarkType type) {
    final landmark = landmarks[type];
    if (landmark == null || landmark.likelihood < 0.6) return null;
    return landmark;
  }

  /// No-op: ya no hay estado previo que limpiar.
  void reset() {}
}
