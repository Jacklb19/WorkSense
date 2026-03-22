import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';

class FaceAnalyzer {
  FaceAnalysisResult analyze(List<Face> faces) {
    if (faces.isEmpty) {
      return FaceAnalysisResult.empty;
    }

    // Use the largest face (by bounding box area) as primary
    final face = faces.reduce((a, b) {
      final aArea = a.boundingBox.width * a.boundingBox.height;
      final bArea = b.boundingBox.width * b.boundingBox.height;
      return aArea >= bArea ? a : b;
    });

    // ML Kit provides head rotation angles:
    // headEulerAngleY = yaw  (left/right rotation)
    // headEulerAngleX = pitch (up/down tilt)
    // headEulerAngleZ = roll  (sideways tilt)
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;

    // Confidence estimate — ML Kit Face Detection doesn't expose a raw
    // confidence value, so we derive one from the landmark availability.
    double confidence = 0.8;
    if (face.landmarks.isNotEmpty) {
      confidence = 0.9;
    }
    if (face.headEulerAngleY == null) {
      confidence *= 0.7;
    }

    return FaceAnalysisResult(
      faceDetected: true,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      faceConfidence: confidence,
    );
  }
}
