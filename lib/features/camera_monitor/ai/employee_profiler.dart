/*
 * ARCHITECTURAL DECISION NOTE:
 * See employee_finder.dart for the full reasoning of why this ML pipeline code
 * currently lives in `camera_monitor/ai/` instead of a standalone `ai_pipeline`
 * module. Keep computer vision logic scoped here unless cross-feature reuse
 * becomes absolutely necessary.
 */

import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profile.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_embedding_service.dart';

enum SampleResult {
  success,
  noFace,
  multiplePeople,
  lowConfidence,
  noPose,
  wrongPosition,
  invalidSignature,
}

class ScanInstruction {
  final int index;
  final String text;
  final String emoji;

  const ScanInstruction({
    required this.index,
    required this.text,
    required this.emoji,
  });
}

class CapturedBiometricSample {
  final List<double> embedding;
  final BodySignature? bodySignature;
  final double qualityScore;
  final BiometricSampleMetadata metadata;

  const CapturedBiometricSample({
    required this.embedding,
    required this.bodySignature,
    required this.qualityScore,
    required this.metadata,
  });
}

class SampleAssessment {
  final SampleResult result;
  final CapturedBiometricSample? sample;
  final String feedback;

  const SampleAssessment({
    required this.result,
    required this.feedback,
    this.sample,
  });

  bool get isSuccess => result == SampleResult.success && sample != null;
}

class EmployeeProfiler {
  static const int samplesRequired = 8;
  static const double minFaceConfidence = 0.40;
  static const double minPoseConfidence = 0.30;

  static const List<ScanInstruction> instructions = [
    ScanInstruction(
      index: 0,
      text: 'Mira directo a la camara',
      emoji: '😐',
    ),
    ScanInstruction(
      index: 1,
      text: 'Gira levemente la cabeza a tu izquierda',
      emoji: '👈',
    ),
    ScanInstruction(
      index: 2,
      text: 'Gira levemente la cabeza a tu derecha',
      emoji: '👉',
    ),
    ScanInstruction(
      index: 3,
      text: 'Levanta levemente la cabeza',
      emoji: '👆',
    ),
    ScanInstruction(
      index: 4,
      text: 'Inclina levemente la cabeza hacia abajo',
      emoji: '👇',
    ),
    ScanInstruction(
      index: 5,
      text: 'De frente otra vez para confirmar',
      emoji: '😐',
    ),
    ScanInstruction(
      index: 6,
      text: 'Gira levemente la cabeza a tu izquierda otra vez',
      emoji: 'ðŸ‘ˆ',
    ),
    ScanInstruction(
      index: 7,
      text: 'Gira levemente la cabeza a tu derecha otra vez',
      emoji: 'ðŸ‘‰',
    ),
  ];

  final List<List<double>> _faceEmbeddings = [];
  final List<BodySignature> _bodySignatures = [];
  final List<BiometricSampleMetadata> _sampleMetadata = [];

  late final PoseDetector _poseDetector;
  late final FaceDetector _faceDetector;
  final FaceAnalyzer _faceAnalyzer;
  final FaceEmbeddingService _embeddingService;

  EmployeeProfiler({
    required FaceAnalyzer faceAnalyzer,
    required FaceEmbeddingService embeddingService,
  })  : _faceAnalyzer = faceAnalyzer,
        _embeddingService = embeddingService {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.single),
    );
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableClassification: true,
        enableTracking: false,
      ),
    );
  }

  int get capturedSamples => _faceEmbeddings.length;
  bool get isComplete => _faceEmbeddings.length >= samplesRequired;

  Future<SampleResult> addSample(
    InputImage inputImage,
    CameraImage cameraImage,
  ) async {
    final assessment = await assessSample(inputImage, cameraImage);
    if (assessment.isSuccess) {
      _commitSample(assessment.sample!);
    }
    return assessment.result;
  }

  Future<SampleAssessment> assessSample(
    InputImage inputImage,
    CameraImage cameraImage,
  ) async {
    final results = await Future.wait([
      _faceDetector.processImage(inputImage),
      _poseDetector.processImage(inputImage),
    ]);

    final faces = results[0] as List<Face>;
    final poses = results[1] as List<Pose>;

    if (faces.isEmpty) {
      return const SampleAssessment(
        result: SampleResult.noFace,
        feedback: 'No se detecto rostro',
      );
    }
    if (faces.length > 1) {
      return const SampleAssessment(
        result: SampleResult.multiplePeople,
        feedback: 'Solo debe estar una persona',
      );
    }

    final face = faces.first;
    final frameSize = inputImage.metadata?.size;
    final faceConf = _estimateFaceConfidence(face, frameSize);
    print(
      '[SCAN] FACE CONF: ${faceConf.toStringAsFixed(3)} '
      '(threshold: $minFaceConfidence)',
    );

    if (faceConf < minFaceConfidence) {
      return const SampleAssessment(
        result: SampleResult.lowConfidence,
        feedback: 'Acercate y mira al frente',
      );
    }

    Pose? pose;
    if (poses.isNotEmpty) {
      pose = poses.first;
    }

    double poseConf = 0.0;
    if (pose != null) {
      poseConf = _estimatePoseConfidence(pose);
      print(
        '[SCAN] POSE CONF: ${poseConf.toStringAsFixed(3)} '
        '(threshold: $minPoseConfidence)',
      );
    }

    final acceptWithoutPose = faceConf > 0.60;
    if (poseConf < minPoseConfidence && !acceptWithoutPose) {
      return SampleAssessment(
        result: poses.isEmpty ? SampleResult.noPose : SampleResult.lowConfidence,
        feedback: poses.isEmpty
            ? 'Asegura que se vea cabeza y torso'
            : 'Mantente centrado y quieto',
      );
    }

    final currentIdx = _faceEmbeddings.length;
    if (currentIdx < instructions.length && !_isPositionCorrectForSample(face, currentIdx)) {
      return SampleAssessment(
        result: SampleResult.wrongPosition,
        feedback: instructions[currentIdx].text,
      );
    }

    BodySignature? sig;
    if (pose != null) {
      sig = BodySignature.fromPose(pose);
    }

    final croppedFace =
        await _faceAnalyzer.cropFaceFromCameraImageAsync(cameraImage, face);
    if (croppedFace == null) {
      return const SampleAssessment(
        result: SampleResult.lowConfidence,
        feedback: 'No pude recortar bien el rostro',
      );
    }

    final cropQuality = await _faceAnalyzer.assessCropQuality(croppedFace);
    print(
      '[SCAN] CROP QUALITY - '
      'brightness: ${cropQuality.brightness.toStringAsFixed(3)}, '
      'contrast: ${cropQuality.contrast.toStringAsFixed(3)}, '
      'sharpness: ${cropQuality.sharpness.toStringAsFixed(3)}, '
      'overall: ${cropQuality.overallScore.toStringAsFixed(3)}, '
      'passes: ${cropQuality.passes}, '
      'feedback: ${cropQuality.feedback}',
    );

    // Quality Gate — centralizado desde AiThresholds
    if (cropQuality.overallScore < AiThresholds.enrollMinCropQuality) {
      return SampleAssessment(
        result: SampleResult.lowConfidence,
        feedback: 'Mejora la iluminación o tu posición',
      );
    }

    // Soft-accept: si el crop no pasa las reglas individuales pero el score
    // global y la confianza facial son aceptables, lo dejamos pasar.
    final canSoftAcceptCrop = !cropQuality.passes &&
        cropQuality.overallScore >= AiThresholds.enrollMinCropQuality &&
        faceConf >= AiThresholds.enrollSoftAcceptFaceConf;

    if (!cropQuality.passes && !canSoftAcceptCrop) {
      return SampleAssessment(
        result: SampleResult.lowConfidence,
        feedback: cropQuality.feedback,
      );
    }

    if (canSoftAcceptCrop) {
      print('[SCAN] Soft-accepting crop for enrollment (quality=${cropQuality.overallScore.toStringAsFixed(2)}, faceConf=${faceConf.toStringAsFixed(2)}).');
    }

    List<double> embedding;
    try {
      embedding = await _embeddingService.generateEmbedding(croppedFace);
    } catch (e) {
      print('[SCAN] Error extrayendo embedding facial: $e');
      return const SampleAssessment(
        result: SampleResult.invalidSignature,
        feedback: 'No se pudo extraer la biometria',
      );
    }

    final qualityScore = (faceConf * 0.45) +
        (cropQuality.overallScore * 0.40) +
        (poseConf.clamp(0.0, 1.0) * 0.15);

    final sampleMetadata = BiometricSampleMetadata(
      qualityScore: qualityScore,
      yaw: face.headEulerAngleY ?? 0.0,
      pitch: face.headEulerAngleX ?? 0.0,
      capturedAt: DateTime.now(),
    );

    if (!_passesDiversityGate(sampleMetadata)) {
      return const SampleAssessment(
        result: SampleResult.wrongPosition,
        feedback: 'Esa toma es muy parecida a una anterior',
      );
    }

    return SampleAssessment(
      result: SampleResult.success,
      feedback: 'Muestra valida',
      sample: CapturedBiometricSample(
        embedding: embedding,
        bodySignature: sig != null && sig.isValid ? sig : null,
        qualityScore: qualityScore,
        metadata: sampleMetadata,
      ),
    );
  }

  EmployeeProfile buildProfile({
    required String employeeId,
    required String workstationId,
  }) {
    assert(
      isComplete,
      'Se necesitan $samplesRequired muestras antes de buildProfile()',
    );

    final List<List<double>> storedEmbeddings = List.from(_faceEmbeddings);

    final avgBody = _bodySignatures.isEmpty
        ? BodySignature.zero
        : BodySignature(
            shoulderToHipRatio: _bodySignatures
                    .map((s) => s.shoulderToHipRatio)
                    .reduce((a, b) => a + b) /
                _bodySignatures.length,
            torsoToLegRatio: _bodySignatures
                    .map((s) => s.torsoToLegRatio)
                    .reduce((a, b) => a + b) /
                _bodySignatures.length,
            armSpanRatio: _bodySignatures
                    .map((s) => s.armSpanRatio)
                    .reduce((a, b) => a + b) /
                _bodySignatures.length,
            headToShoulderRatio: _bodySignatures
                    .map((s) => s.headToShoulderRatio)
                    .reduce((a, b) => a + b) /
                _bodySignatures.length,
            neckLength: _bodySignatures
                    .map((s) => s.neckLength)
                    .reduce((a, b) => a + b) /
                _bodySignatures.length,
          );

    return EmployeeProfile(
      employeeId: employeeId,
      workstationId: workstationId,
      faceEmbeddings: storedEmbeddings,
      bodySignature: avgBody,
      capturedAt: DateTime.now(),
      sampleCount: samplesRequired,
      lastReenrollmentAt: DateTime.now(),
      sampleMetadata: List<BiometricSampleMetadata>.from(_sampleMetadata),
    );
  }

  void reset() {
    _faceEmbeddings.clear();
    _bodySignatures.clear();
    _sampleMetadata.clear();
  }

  void commitAssessedSample(CapturedBiometricSample sample) {
    _commitSample(sample);
  }

  void dispose() {
    _poseDetector.close();
    _faceDetector.close();
  }

  void _commitSample(CapturedBiometricSample sample) {
    _faceEmbeddings.add(sample.embedding);
    _sampleMetadata.add(sample.metadata);
    if (sample.bodySignature != null && sample.bodySignature!.isValid) {
      _bodySignatures.add(sample.bodySignature!);
    }
  }

  bool _passesDiversityGate(BiometricSampleMetadata candidate) {
    for (final existing in _sampleMetadata) {
      final yawDelta = (existing.yaw - candidate.yaw).abs();
      final pitchDelta = (existing.pitch - candidate.pitch).abs();
      if (yawDelta < 4.0 && pitchDelta < 4.0) {
        return false;
      }
    }
    return true;
  }

  double _estimateFaceConfidence(Face face, Size? frameSize) {
    double sizeScore = 0.5;
    if (frameSize != null) {
      final boxArea = face.boundingBox.width * face.boundingBox.height;
      final frameArea = frameSize.width * frameSize.height;
      sizeScore = (boxArea / frameArea).clamp(0.0, 1.0) * 2.0;
      sizeScore = sizeScore.clamp(0.0, 1.0);
    }

    final rotY = face.headEulerAngleY?.abs() ?? 45.0;
    final rotZ = face.headEulerAngleZ?.abs() ?? 45.0;
    final angleScore = (1.0 - ((rotY + rotZ) / 90.0)).clamp(0.0, 1.0);

    final landmarksScore = face.landmarks.isNotEmpty ? 1.0 : 0.0;
    final eyeScore = ((face.leftEyeOpenProbability ?? 0.5) +
            (face.rightEyeOpenProbability ?? 0.5)) /
        2.0;
    final classScore = (landmarksScore * 0.5) + (eyeScore * 0.5);

    final finalConf =
        (sizeScore * 0.5) + (angleScore * 0.3) + (classScore * 0.2);

    print(
      '[SCAN] CONF DETAILS - size: ${sizeScore.toStringAsFixed(2)}, '
      'angle: ${angleScore.toStringAsFixed(2)}, '
      'class: ${classScore.toStringAsFixed(2)}',
    );

    return finalConf;
  }

  double _estimatePoseConfidence(Pose pose) {
    final keyTypes = [
      PoseLandmarkType.nose,
      PoseLandmarkType.leftShoulder,
      PoseLandmarkType.rightShoulder,
      PoseLandmarkType.leftHip,
      PoseLandmarkType.rightHip,
    ];
    final likelihoods =
        keyTypes.map((t) => pose.landmarks[t]?.likelihood ?? 0.0).toList();
    return likelihoods.reduce((a, b) => a + b) / likelihoods.length;
  }

  bool isPositionStateCorrect(Face face) {
    return _isPositionCorrectForSample(face, _faceEmbeddings.length);
  }

  bool _isPositionCorrectForSample(Face face, int sampleIndex) {
    final yaw = face.headEulerAngleY ?? 0.0;
    final pitch = face.headEulerAngleX ?? 0.0;

    switch (sampleIndex) {
      case 0: // Frente
        return yaw.abs() <= 12.0 && pitch.abs() <= 14.0;
      case 1: // Izquierda (yaw negativo = izquierda del sujeto)
        return yaw < -4.0 && pitch.abs() <= 18.0;
      case 2: // Derecha
        return yaw > 4.0 && pitch.abs() <= 18.0;
      case 3: // Arriba (pitch negativo = cabeza arriba en ML Kit)
        return yaw.abs() <= 18.0 && pitch < -3.0;
      case 4: // Abajo (pitch positivo = cabeza abajo)
        return yaw.abs() <= 18.0 && pitch > 3.0;
      case 5: // Frente otra vez
        return yaw.abs() <= 12.0 && pitch.abs() <= 14.0;
      case 6: // Izquierda otra vez
        return yaw < -4.0 && pitch.abs() <= 18.0;
      case 7: // Derecha otra vez
        return yaw > 4.0 && pitch.abs() <= 18.0;
      default:
        return true;
    }
  }
}
