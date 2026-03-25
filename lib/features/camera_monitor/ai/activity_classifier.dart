import 'package:worksense_app/core/constants/aithresholds.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';

class ActivityClassifier {
  // Smoothing buffer — stores last N results for majority vote
  static const int _bufferSize = 3;
  final List<ActivityState> _recentStates = [];

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

    // Add raw result to smoothing buffer
    _recentStates.add(rawResult.state);
    if (_recentStates.length > _bufferSize) {
      _recentStates.removeAt(0);
    }

    // Return the mode (most frequent state) of the buffer
    final smoothedState = _mode(_recentStates);

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
    // Priority 1: No signals detected (neither face nor pose)
    final alguienPresente = face.faceDetected || pose.personDetected;
    if (!alguienPresente) {
      return const AiResult(
        state: ActivityState.ausente,
        confidence: 0.85,
      );
    }

    // Priority 2: Person detected but face not visible
    // (could be looking down at work — assume working)
    if (!face.faceDetected) {
      return const AiResult(
        state: ActivityState.trabajando,
        confidence: 0.55,
      );
    }

    // Priority 3: Head turned significantly or hand near face → distracted
    final yawAbsolute = face.yaw.abs();
    if (yawAbsolute > AiThresholds.maxYawAngle || pose.handNearFace) {
      return const AiResult(
        state: ActivityState.distraido,
        confidence: 0.75,
      );
    }

    // Priority 4: Head drooping (pitch below threshold) or tilted (roll) → fatigue
    if (face.pitch < AiThresholds.minPitchAngle ||
        face.roll.abs() > AiThresholds.maxRollAngle) {
      return const AiResult(
        state: ActivityState.fatiga,
        confidence: 0.75,
      );
    }

    // Priority 5: Person present but not moving hands → inactive
    if (isInactive && !pose.handsMoving) {
      return const AiResult(
        state: ActivityState.inactivo,
        confidence: 0.80,
      );
    }

    // Priority 6: Default — person present, face forward, hands moving
    return const AiResult(
      state: ActivityState.trabajando,
      confidence: 0.90,
    );
  }

  ActivityState _mode(List<ActivityState> states) {
    if (states.isEmpty) return ActivityState.ausente;

    final counts = <ActivityState, int>{};
    for (final s in states) {
      counts[s] = (counts[s] ?? 0) + 1;
    }

    return counts.entries
        .reduce((a, b) => a.value >= b.value ? a : b)
        .key;
  }

  /// Reset smoothing buffer (call when monitoring session restarts)
  void reset() {
    _recentStates.clear();
  }
}
