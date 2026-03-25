import 'package:worksense_app/domain/entities/activity_state.dart';

class AiResult {
  final ActivityState state;
  final double confidence;

  const AiResult({
    required this.state,
    required this.confidence,
  });

  @override
  String toString() =>
      'AiResult(state: ${state.label}, confidence: ${confidence.toStringAsFixed(2)})';
}

class PoseAnalysisResult {
  final bool personDetected;
  final bool handsMoving;
  final bool handNearFace;
  final double shoulderAngle;
  final double poseConfidence;

  const PoseAnalysisResult({
    required this.personDetected,
    required this.handsMoving,
    required this.handNearFace,
    required this.shoulderAngle,
    required this.poseConfidence,
  });

  static const PoseAnalysisResult empty = PoseAnalysisResult(
    personDetected: false,
    handsMoving: false,
    handNearFace: false,
    shoulderAngle: 0.0,
    poseConfidence: 0.0,
  );
}

class FaceAnalysisResult {
  final bool faceDetected;
  final double yaw;
  final double pitch;
  final double roll;
  final double faceConfidence;
  final bool eyesClosed;

  const FaceAnalysisResult({
    required this.faceDetected,
    required this.yaw,
    required this.pitch,
    required this.roll,
    required this.faceConfidence,
    this.eyesClosed = false,
  });

  static const FaceAnalysisResult empty = FaceAnalysisResult(
    faceDetected: false,
    yaw: 0.0,
    pitch: 0.0,
    roll: 0.0,
    faceConfidence: 0.0,
    eyesClosed: false,
  );
}
