import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';

class PoseAnalyzer {
  // Tracks previous wrist positions (normalized) to detect movement
  double? _prevLeftWristX;
  double? _prevLeftWristY;
  double? _prevRightWristX;
  double? _prevRightWristY;

  /// Analiza una sola pose (para usar con el empleado identificado).
  PoseAnalysisResult analyzeSingle(Pose? pose) {
    if (pose == null) {
      _clearPreviousPositions();
      return PoseAnalysisResult.empty;
    }
    return _analyzeOnePose(pose);
  }

  PoseAnalysisResult analyze(List<Pose> poses) {
    if (poses.isEmpty) {
      _clearPreviousPositions();
      return PoseAnalysisResult.empty;
    }

    final pose = poses.first;
    return _analyzeOnePose(pose);
  }

  PoseAnalysisResult _analyzeOnePose(Pose pose) {
    final landmarks = pose.landmarks;

    // Check pose confidence via landmark presence scores
    final nose = landmarks[PoseLandmarkType.nose];
    final leftShoulder = landmarks[PoseLandmarkType.leftShoulder];
    final rightShoulder = landmarks[PoseLandmarkType.rightShoulder];
    final leftWrist = landmarks[PoseLandmarkType.leftWrist];
    final rightWrist = landmarks[PoseLandmarkType.rightWrist];

    if (nose == null || leftShoulder == null || rightShoulder == null) {
      _clearPreviousPositions();
      return PoseAnalysisResult.empty;
    }

    // Calculate average confidence from key landmarks
    final keyLandmarks = [
      nose,
      leftShoulder,
      rightShoulder,
      if (leftWrist != null) leftWrist,
      if (rightWrist != null) rightWrist,
    ];

    final avgConfidence = keyLandmarks
            .map((l) => l.likelihood)
            .reduce((a, b) => a + b) /
        keyLandmarks.length;

    if (avgConfidence < AiThresholds.minPoseConfidence) {
      _clearPreviousPositions();
      return PoseAnalysisResult.empty;
    }

    // Calculate shoulder angle (tilt)
    final shoulderAngle = _calculateShoulderAngle(leftShoulder, rightShoulder);

    // Normalize landmark positions by image dimensions (use raw x/y as proxy)
    final noseX = nose.x;
    final noseY = nose.y;

    // Check wrist movement
    bool handsMoving = false;
    if (leftWrist != null && rightWrist != null) {
      handsMoving = _detectWristMovement(leftWrist, rightWrist);
      // Update stored positions
      _prevLeftWristX = leftWrist.x;
      _prevLeftWristY = leftWrist.y;
      _prevRightWristX = rightWrist.x;
      _prevRightWristY = rightWrist.y;
    } else {
      _prevLeftWristX = null;
      _prevLeftWristY = null;
      _prevRightWristX = null;
      _prevRightWristY = null;
    }

    // Check hand near face
    bool handNearFace = false;
    if (leftWrist != null || rightWrist != null) {
      handNearFace = _isHandNearFace(
        noseX: noseX,
        noseY: noseY,
        leftWrist: leftWrist,
        rightWrist: rightWrist,
        leftShoulder: leftShoulder,
        rightShoulder: rightShoulder,
      );
    }

    return PoseAnalysisResult(
      personDetected: true,
      handsMoving: handsMoving,
      handNearFace: handNearFace,
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

  bool _detectWristMovement(
      PoseLandmark leftWrist, PoseLandmark rightWrist) {
    if (_prevLeftWristX == null ||
        _prevLeftWristY == null ||
        _prevRightWristX == null ||
        _prevRightWristY == null) {
      return false;
    }

    // Use a reference scale — distance between previous and current wrist
    // We use a simple pixel-delta threshold divided by a rough body scale
    final leftDx = (leftWrist.x - _prevLeftWristX!).abs();
    final leftDy = (leftWrist.y - _prevLeftWristY!).abs();
    final rightDx = (rightWrist.x - _prevRightWristX!).abs();
    final rightDy = (rightWrist.y - _prevRightWristY!).abs();

    final leftMovement = math.sqrt(leftDx * leftDx + leftDy * leftDy);
    final rightMovement = math.sqrt(rightDx * rightDx + rightDy * rightDy);

    // Normalize by a typical image width assumption of 640px
    const imageWidthEstimate = 640.0;
    final normalizedLeft = leftMovement / imageWidthEstimate;
    final normalizedRight = rightMovement / imageWidthEstimate;

    return normalizedLeft > AiThresholds.minWristMovement ||
        normalizedRight > AiThresholds.minWristMovement;
  }

  bool _isHandNearFace({
    required double noseX,
    required double noseY,
    required PoseLandmark? leftWrist,
    required PoseLandmark? rightWrist,
    required PoseLandmark leftShoulder,
    required PoseLandmark rightShoulder,
  }) {
    // Use shoulder width as a normalizing reference
    final shoulderWidth =
        (rightShoulder.x - leftShoulder.x).abs().clamp(1.0, double.infinity);

    bool checkWrist(PoseLandmark? wrist) {
      if (wrist == null) return false;
      final dx = (wrist.x - noseX) / shoulderWidth;
      final dy = (wrist.y - noseY) / shoulderWidth;
      final dist = math.sqrt(dx * dx + dy * dy);
      return dist < AiThresholds.maxHandToFaceDistance * 2;
    }

    return checkWrist(leftWrist) || checkWrist(rightWrist);
  }

  void _clearPreviousPositions() {
    _prevLeftWristX = null;
    _prevLeftWristY = null;
    _prevRightWristX = null;
    _prevRightWristY = null;
  }

  /// Reset stored wrist positions (call when analysis is paused)
  void reset() {
    _clearPreviousPositions();
  }
}
