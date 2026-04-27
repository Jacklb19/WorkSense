import 'dart:math' as math;
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
import 'package:camera/camera.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';

class FaceCropQuality {
  final double brightness;
  final double contrast;
  final double sharpness;
  final double overallScore;
  final bool passes;
  final String feedback;

  const FaceCropQuality({
    required this.brightness,
    required this.contrast,
    required this.sharpness,
    required this.overallScore,
    required this.passes,
    required this.feedback,
  });
}

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
  /// Convierte eficientemente la trama nativa y realiza el recorte del rostro en background isolate.
  Future<img.Image?> cropFaceFromCameraImageAsync(CameraImage cameraImage, Face face) async {
    final image = await _convertCameraImageAsync(cameraImage);
    if (image == null) return null;
    return cropFaceFromImage(image, face);
  }

  /// (obsoleto, usa la versión Async)
  img.Image? cropFaceFromCameraImage(CameraImage cameraImage, Face face) {
    throw UnsupportedError('Use cropFaceFromCameraImageAsync instead');
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

  FaceCropQuality assessCropQuality(img.Image croppedFace) {
    if (croppedFace.width < 48 || croppedFace.height < 48) {
      return const FaceCropQuality(
        brightness: 0.0,
        contrast: 0.0,
        sharpness: 0.0,
        overallScore: 0.0,
        passes: false,
        feedback: 'Acercate mas a la camara',
      );
    }

    double sum = 0.0;
    double sumSq = 0.0;
    double edgeSum = 0.0;
    int edgeCount = 0;

    final width = croppedFace.width;
    final height = croppedFace.height;
    final luminance = List<double>.filled(width * height, 0.0);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final pixel = croppedFace.getPixel(x, y);
        final value =
            (0.299 * pixel.r + 0.587 * pixel.g + 0.114 * pixel.b) / 255.0;
        final index = y * width + x;
        luminance[index] = value;
        sum += value;
        sumSq += value * value;
      }
    }

    final totalPixels = (width * height).toDouble();
    final brightness = sum / totalPixels;
    final variance = (sumSq / totalPixels) - (brightness * brightness);
    final contrast = variance <= 0 ? 0.0 : math.sqrt(variance);

    for (int y = 0; y < height - 1; y++) {
      for (int x = 0; x < width - 1; x++) {
        final current = luminance[y * width + x];
        final right = luminance[y * width + x + 1];
        final bottom = luminance[(y + 1) * width + x];
        edgeSum += (current - right).abs() + (current - bottom).abs();
        edgeCount += 2;
      }
    }

    final sharpness = edgeCount == 0 ? 0.0 : (edgeSum / edgeCount).clamp(0.0, 1.0);

    final brightnessScore = brightness < AiThresholds.minFaceBrightness
        ? (brightness / AiThresholds.minFaceBrightness).clamp(0.0, 1.0)
        : brightness > AiThresholds.maxFaceBrightness
            ? ((1.0 - brightness) / (1.0 - AiThresholds.maxFaceBrightness))
                .clamp(0.0, 1.0)
            : 1.0;
    final contrastScore =
        (contrast / AiThresholds.minFaceContrast).clamp(0.0, 1.0);
    final sharpnessScore =
        (sharpness / AiThresholds.minFaceSharpness).clamp(0.0, 1.0);

    final overallScore = (brightnessScore * 0.4) +
        (contrastScore * 0.25) +
        (sharpnessScore * 0.35);

    if (brightness < AiThresholds.minFaceBrightness) {
      return FaceCropQuality(
        brightness: brightness,
        contrast: contrast,
        sharpness: sharpness,
        overallScore: overallScore,
        passes: false,
        feedback: 'Mas luz en el rostro',
      );
    }

    if (brightness > AiThresholds.maxFaceBrightness) {
      return FaceCropQuality(
        brightness: brightness,
        contrast: contrast,
        sharpness: sharpness,
        overallScore: overallScore,
        passes: false,
        feedback: 'Hay demasiada luz frontal',
      );
    }

    if (contrast < AiThresholds.minFaceContrast) {
      return FaceCropQuality(
        brightness: brightness,
        contrast: contrast,
        sharpness: sharpness,
        overallScore: overallScore,
        passes: false,
        feedback: 'Mejora la luz o el encuadre',
      );
    }

    if (sharpness < AiThresholds.minFaceSharpness) {
      return FaceCropQuality(
        brightness: brightness,
        contrast: contrast,
        sharpness: sharpness,
        overallScore: overallScore,
        passes: false,
        feedback: 'Quedate quieto un momento',
      );
    }

    return FaceCropQuality(
      brightness: brightness,
      contrast: contrast,
      sharpness: sharpness,
      overallScore: overallScore,
      passes: true,
      feedback: 'Calidad facial correcta',
    );
  }

  // ── Helpers Privados de Conversión ───────────────────────────────────────

  Future<img.Image?> _convertCameraImageAsync(CameraImage image) async {
    try {
      final Map<String, dynamic> data = {
        'format': image.format.group.name,
        'width': image.width,
        'height': image.height,
        'planes': image.planes.map((p) => {
          'bytes': p.bytes,
          'bytesPerRow': p.bytesPerRow,
          'bytesPerPixel': p.bytesPerPixel,
        }).toList(),
      };
      // Run the heavy loop on a background isolate
      return await compute(_convertCameraImageTask, data);
    } catch (e) {
      print('[FaceAnalyzer] Error preparando CameraImage para isolate: $e');
      return null;
    }
  }

  static img.Image? _convertCameraImageTask(Map<String, dynamic> data) {
    try {
      final format = data['format'] as String;
      final width = data['width'] as int;
      final height = data['height'] as int;
      final planes = data['planes'] as List<dynamic>;

      if (format == 'bgra8888') {
        return img.Image.fromBytes(
          width: width,
          height: height,
          bytes: (planes[0]['bytes'] as Uint8List).buffer,
          order: img.ChannelOrder.bgra,
        );
      } else if (format == 'nv21') {
        return _convertNV21(width, height, planes);
      } else if (format == 'yuv420') {
        return _convertYUV420(width, height, planes);
      }
      return null;
    } catch (e) {
      print('[FaceAnalyzer] Error en _convertCameraImageTask: $e');
      return null;
    }
  }

  static img.Image _convertNV21(int width, int height, List<dynamic> planes) {
    final yPlane = planes[0]['bytes'] as Uint8List;
    
    Uint8List vuPlane;
    int yRowStride;
    int vuRowStride;
    int vuOffset = 0;

    if (planes.length >= 2) {
      vuPlane = planes[1]['bytes'] as Uint8List;
      yRowStride = planes[0]['bytesPerRow'] as int;
      vuRowStride = planes[1]['bytesPerRow'] as int;
    } else {
      // Packed in a single plane
      vuPlane = yPlane;
      yRowStride = width;
      vuRowStride = width;
      vuOffset = width * height;
    }

    final img.Image result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = vuOffset + (y ~/ 2) * vuRowStride + (x ~/ 2) * 2;
        final yIndex = y * yRowStride + x;

        final yp = yPlane[yIndex];
        // En NV21 el plano V está intercalado antes que U
        final vp = vuPlane[uvIndex];
        final up = vuPlane[uvIndex + 1];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }

  static img.Image _convertYUV420(int width, int height, List<dynamic> planes) {
    final yPlane = planes[0]['bytes'] as Uint8List;
    final uPlane = planes[1]['bytes'] as Uint8List;
    final vPlane = planes[2]['bytes'] as Uint8List;

    final yRowStride = planes[0]['bytesPerRow'] as int;
    final uvRowStride = planes[1]['bytesPerRow'] as int;
    final uvPixelStride = planes[1]['bytesPerPixel'] as int? ?? 1;

    final img.Image result = img.Image(width: width, height: height);

    for (int y = 0; y < height; y++) {
      for (int x = 0; x < width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final yIndex = y * yRowStride + x;

        final yp = yPlane[yIndex];
        final up = uPlane[uvIndex];
        final vp = vPlane[uvIndex];

        int r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        int g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91).round().clamp(0, 255);
        int b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }
}

