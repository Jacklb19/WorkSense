import 'dart:math' as math;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:image/image.dart' as img;
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
  FaceAnalysisResult analyzeSingle(Face face) {
    return _analyzeOneFace(face);
  }

  FaceAnalysisResult analyze(List<Face> faces) {
    if (faces.isEmpty) {
      return FaceAnalysisResult.empty;
    }

    final face = faces.reduce((a, b) {
      final aArea = a.boundingBox.width * a.boundingBox.height;
      final bArea = b.boundingBox.width * b.boundingBox.height;
      return aArea >= bArea ? a : b;
    });

    return _analyzeOneFace(face);
  }

  FaceAnalysisResult _analyzeOneFace(Face face) {
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;
    final roll = face.headEulerAngleZ ?? 0.0;

    double confidence = 0.8;
    if (face.landmarks.isNotEmpty) {
      confidence = 0.9;
    }
    if (face.headEulerAngleY == null) {
      confidence *= 0.7;
    }

    var eyesClosed = false;
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

  Future<img.Image?> cropFaceFromCameraImageAsync(
    CameraImage cameraImage,
    Face face,
  ) async {
    final image = await _convertCameraImageAsync(cameraImage);
    if (image == null) return null;
    return cropFaceFromImage(image, face);
  }

  img.Image? cropFaceFromCameraImage(CameraImage cameraImage, Face face) {
    throw UnsupportedError('Use cropFaceFromCameraImageAsync instead');
  }

  img.Image? cropFaceFromImage(img.Image originalImage, Face face) {
    final rect = face.boundingBox;
    final hasEyeLandmarks = _hasEyeLandmarks(face);
    final paddingFactor = AiThresholds.facePaddingFactor +
        (hasEyeLandmarks ? 0.10 : 0.0);

    final side = math.max(
      1,
      (math.max(rect.width, rect.height) * (1 + (paddingFactor * 2))).round(),
    );
    final safeSide = math.min(
      side,
      math.min(originalImage.width, originalImage.height),
    );
    if (safeSide <= 0) return null;

    final centerX = rect.left + (rect.width / 2);
    final centerY = rect.top + (rect.height / 2);
    final x = _clampCropStart(
      (centerX - (safeSide / 2)).round(),
      safeSide,
      originalImage.width,
    );
    final y = _clampCropStart(
      (centerY - (safeSide / 2)).round(),
      safeSide,
      originalImage.height,
    );

    final croppedFace = img.copyCrop(
      originalImage,
      x: x,
      y: y,
      width: safeSide,
      height: safeSide,
    );

    return _alignFaceCrop(croppedFace, face);
  }

  Future<FaceCropQuality> assessCropQuality(img.Image croppedFace) async {
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

    final data = {
      'width': croppedFace.width,
      'height': croppedFace.height,
      'bytes': croppedFace.getBytes(),
    };

    return compute(_computeCropQualityTask, data);
  }

  static FaceCropQuality _computeCropQualityTask(Map<String, dynamic> data) {
    final int width = data['width'];
    final int height = data['height'];
    final Uint8List bytes = data['bytes'];
    
    final croppedFace = img.Image.fromBytes(width: width, height: height, bytes: bytes.buffer);

    var sum = 0.0;
    var sumSq = 0.0;
    var edgeSum = 0.0;
    var edgeCount = 0;

    final luminance = List<double>.filled(width * height, 0.0);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
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

    for (var y = 0; y < height - 1; y++) {
      for (var x = 0; x < width - 1; x++) {
        final current = luminance[y * width + x];
        final right = luminance[y * width + x + 1];
        final bottom = luminance[(y + 1) * width + x];
        edgeSum += (current - right).abs() + (current - bottom).abs();
        edgeCount += 2;
      }
    }

    final sharpness =
        edgeCount == 0 ? 0.0 : (edgeSum / edgeCount).clamp(0.0, 1.0);

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

  bool _hasEyeLandmarks(Face face) {
    return face.landmarks[FaceLandmarkType.leftEye] != null &&
        face.landmarks[FaceLandmarkType.rightEye] != null;
  }

  int _clampCropStart(int start, int size, int maxExtent) {
    if (size >= maxExtent) return 0;
    if (start < 0) return 0;
    final maxStart = maxExtent - size;
    if (start > maxStart) return maxStart;
    return start;
  }

  img.Image _alignFaceCrop(img.Image croppedFace, Face face) {
    final leftEye = face.landmarks[FaceLandmarkType.leftEye];
    final rightEye = face.landmarks[FaceLandmarkType.rightEye];
    if (leftEye == null || rightEye == null) {
      return croppedFace;
    }

    final deltaX = rightEye.position.x - leftEye.position.x;
    final deltaY = rightEye.position.y - leftEye.position.y;
    if (deltaX.abs() < 0.001) {
      return croppedFace;
    }

    final rotationDegrees = math.atan2(deltaY, deltaX) * 180 / math.pi;
    if (rotationDegrees.abs() < 1.0 ||
        rotationDegrees.abs() > AiThresholds.maxRollAngle) {
      return croppedFace;
    }

    final rotated = img.copyRotate(croppedFace, angle: -rotationDegrees);
    final safeSide = math.min(
      croppedFace.width,
      math.min(rotated.width, rotated.height),
    );
    final startX = _clampCropStart(
      ((rotated.width - safeSide) / 2).round(),
      safeSide,
      rotated.width,
    );
    final startY = _clampCropStart(
      ((rotated.height - safeSide) / 2).round(),
      safeSide,
      rotated.height,
    );

    return img.copyCrop(
      rotated,
      x: startX,
      y: startY,
      width: safeSide,
      height: safeSide,
    );
  }

  Future<img.Image?> _convertCameraImageAsync(CameraImage image) async {
    try {
      final data = <String, dynamic>{
        'format': image.format.group.name,
        'width': image.width,
        'height': image.height,
        'planes': image.planes
            .map(
              (p) => {
                'bytes': p.bytes,
                'bytesPerRow': p.bytesPerRow,
                'bytesPerPixel': p.bytesPerPixel,
              },
            )
            .toList(),
      };
      return await compute(_convertCameraImageTask, data);
    } catch (e) {
      debugPrint('[FaceAnalyzer] Error preparando CameraImage para isolate: $e');
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
      }
      if (format == 'nv21') {
        return _convertNV21(width, height, planes);
      }
      if (format == 'yuv420') {
        return _convertYUV420(width, height, planes);
      }
      return null;
    } catch (e) {
      debugPrint('[FaceAnalyzer] Error en _convertCameraImageTask: $e');
      return null;
    }
  }

  static img.Image _convertNV21(int width, int height, List<dynamic> planes) {
    final yPlane = planes[0]['bytes'] as Uint8List;

    Uint8List vuPlane;
    int yRowStride;
    int vuRowStride;
    var vuOffset = 0;

    if (planes.length >= 2) {
      vuPlane = planes[1]['bytes'] as Uint8List;
      yRowStride = planes[0]['bytesPerRow'] as int;
      vuRowStride = planes[1]['bytesPerRow'] as int;
    } else {
      vuPlane = yPlane;
      yRowStride = width;
      vuRowStride = width;
      vuOffset = width * height;
    }

    final result = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final uvIndex = vuOffset + (y ~/ 2) * vuRowStride + (x ~/ 2) * 2;
        final yIndex = y * yRowStride + x;

        final yp = yPlane[yIndex];
        final vp = vuPlane[uvIndex];
        final up = vuPlane[uvIndex + 1];

        final r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        final g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        final b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

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

    final result = img.Image(width: width, height: height);

    for (var y = 0; y < height; y++) {
      for (var x = 0; x < width; x++) {
        final uvIndex = uvPixelStride * (x ~/ 2) + uvRowStride * (y ~/ 2);
        final yIndex = y * yRowStride + x;

        final yp = yPlane[yIndex];
        final up = uPlane[uvIndex];
        final vp = vPlane[uvIndex];

        final r = (yp + vp * 1436 / 1024 - 179).round().clamp(0, 255);
        final g = (yp - up * 46549 / 131072 + 44 - vp * 93604 / 131072 + 91)
            .round()
            .clamp(0, 255);
        final b = (yp + up * 1814 / 1024 - 227).round().clamp(0, 255);

        result.setPixelRgb(x, y, r, g, b);
      }
    }
    return result;
  }
}
