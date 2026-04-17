import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
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

  /// Integración principal desde el ciclo de vida de la cámara en vivo.
  /// Convierte eficientemente la trama nativa y realiza el recorte del rostro.
  img.Image? cropFaceFromCameraImage(CameraImage cameraImage, Face face) {
    final image = _convertCameraImage(cameraImage);
    if (image == null) return null;
    return cropFaceFromImage(image, face);
  }

  /// Recorta el rostro detectado de la imagen original usando su BoundingBox.
  /// Aplica el padding factor global estructurado para mayor fiabilidad biométrica.
  img.Image? cropFaceFromImage(img.Image originalImage, Face face) {
    final rect = face.boundingBox;

    // Uso de constante centralizada en la arquitectura para evitar magic numbers
    final paddingX = (rect.width * AiThresholds.facePaddingFactor).toInt();
    final paddingY = (rect.height * AiThresholds.facePaddingFactor).toInt();

    int x = rect.left.toInt() - paddingX;
    int y = rect.top.toInt() - paddingY;
    int w = rect.width.toInt() + (paddingX * 2);
    int h = rect.height.toInt() + (paddingY * 2);

    x = x < 0 ? 0 : x;
    y = y < 0 ? 0 : y;
    w = (x + w > originalImage.width) ? (originalImage.width - x) : w;
    h = (y + h > originalImage.height) ? (originalImage.height - y) : h;

    if (w <= 0 || h <= 0) return null;

    return img.copyCrop(
      originalImage,
      x: x,
      y: y,
      width: w,
      height: h,
    );
  }

  // ── Helpers Privados de Conversión ───────────────────────────────────────

  /// Convierte la trama nativa (YUV Android o BGRA iOS) a un objeto Image manipulable.
  img.Image? _convertCameraImage(CameraImage image) {
    try {
      if (image.format.group == ImageFormatGroup.yuv420) {
        return _convertYUV420(image);
      } else if (image.format.group == ImageFormatGroup.bgra8888) {
        return _convertBGRA8888(image);
      }
    } catch (e) {
      print('[FaceAnalyzer] Error convirtiendo CameraImage: $e');
    }
    return null;
  }

  img.Image _convertBGRA8888(CameraImage image) {
    return img.Image.fromBytes(
      width: image.width,
      height: image.height,
      bytes: image.planes[0].bytes.buffer,
      order: img.ChannelOrder.bgra,
    );
  }

  img.Image _convertYUV420(CameraImage image) {
    final width = image.width;
    final height = image.height;
    final uvRowStride = image.planes[1].bytesPerRow;
    final uvPixelStride = image.planes[1].bytesPerPixel ?? 1;

    final img.Image result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final yIndex = y * image.planes[0].bytesPerRow + x;

        final yp = image.planes[0].bytes[yIndex];
        final up = image.planes[1].bytes[uvIndex];
        final vp = image.planes[2].bytes[uvIndex];

        // Conversión estándar YUV a RGB
        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }
}
