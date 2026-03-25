import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';

class FaceAnalyzer {
  /// Analiza una sola cara (para usar con el empleado identificado).
  FaceAnalysisResult analyzeSingle(Face face) {
    return _analyzeOneFace(face);
  }

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
    return _analyzeOneFace(face);
  }

  FaceAnalysisResult _analyzeOneFace(Face face) {
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

    // Detect closed eyes (probability < 0.3 means likely closed)
    bool eyesClosed = false;
    if (face.leftEyeOpenProbability != null &&
        face.rightEyeOpenProbability != null) {
      if (face.leftEyeOpenProbability! < 0.3 &&
          face.rightEyeOpenProbability! < 0.3) {
        eyesClosed = true;
      }
    }

    return FaceAnalysisResult(
      faceDetected: true,
      yaw: yaw,
      pitch: pitch,
      roll: roll,
      faceConfidence: confidence,
      eyesClosed: eyesClosed,
    );
  }
}
