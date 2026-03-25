import 'dart:ui' show Size;
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profile.dart';

enum SampleResult {
  success,
  noFace,
  multiplePeople,
  lowConfidence,
  noPose,
  invalidSignature,
}

/// Instrucción de escaneo para cada una de las 5 muestras.
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

/// Orquesta la captura de las 5 muestras para construir un EmployeeProfile.
class EmployeeProfiler {
  static const int samplesRequired = 5;
  static const double minFaceConfidence = 0.40; // Más flexible para cámara frontal
  static const double minPoseConfidence = 0.30; // Muy flexible para entornos de oficina

  static const List<ScanInstruction> instructions = [
    ScanInstruction(
      index: 0,
      text: 'Mira directo a la cámara en tu posición normal de trabajo',
      emoji: '',
    ),
    ScanInstruction(
      index: 1,
      text: 'Gira levemente la cabeza hacia tu izquierda (15-20 grados)',
      emoji: '',
    ),
    ScanInstruction(
      index: 2,
      text: 'Gira levemente la cabeza hacia tu derecha (15-20 grados)',
      emoji: '',
    ),
    ScanInstruction(
      index: 3,
      text: 'Inclina la cabeza levemente hacia abajo (como mirando el escritorio)',
      emoji: '',
    ),
    ScanInstruction(
      index: 4,
      text: 'Levanta levemente la cabeza (como mirando una pantalla alta)',
      emoji: '',
    ),
  ];

  final List<List<double>> _faceEmbeddings = [];
  final List<BodySignature> _bodySignatures = [];

  late final PoseDetector _poseDetector;
  late final FaceDetector _faceDetector;

  EmployeeProfiler() {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.single),
    );
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.accurate,
        enableLandmarks: true,
        enableClassification: true, // Habilitar para probabilidad de ojos/sonrisa
        enableTracking: false,
      ),
    );
  }

  int get capturedSamples => _faceEmbeddings.length;
  bool get isComplete => _faceEmbeddings.length >= samplesRequired;

  /// Captura y valida una muestra del frame actual.
  /// Retorna [SampleResult.success] si fue aceptada.
  Future<SampleResult> addSample(InputImage inputImage) async {
    final results = await Future.wait([
      _faceDetector.processImage(inputImage),
      _poseDetector.processImage(inputImage),
    ]);

    final faces = results[0] as List<Face>;
    final poses = results[1] as List<Pose>;

    // Debe haber exactamente 1 cara
    if (faces.isEmpty) return SampleResult.noFace;
    if (faces.length > 1) return SampleResult.multiplePeople;

    final face = faces.first;
    final frameSize = inputImage.metadata?.size;

    // Confianza de cara enriquecida
    final faceConf = _estimateFaceConfidence(face, frameSize);
    print('[SCAN] FACE CONF: ${faceConf.toStringAsFixed(3)} (threshold: $minFaceConfidence)');

    if (faceConf < minFaceConfidence) return SampleResult.lowConfidence;

    // Pose: Intentar obtenerla, pero ser indulgente si la cara es muy buena (>0.6)
    Pose? pose;
    if (poses.isNotEmpty) {
      pose = poses.first;
    }

    double poseConf = 0.0;
    if (pose != null) {
      poseConf = _estimatePoseConfidence(pose);
      print('[SCAN] POSE CONF: ${poseConf.toStringAsFixed(3)} (threshold: $minPoseConfidence)');
    }

    // Si no hay pose o es baja, pero la cara es excelente, aceptamos
    final acceptWithoutPose = faceConf > 0.60;

    if (poseConf < minPoseConfidence && !acceptWithoutPose) {
      return poses.isEmpty ? SampleResult.noPose : SampleResult.lowConfidence;
    }

    // Calcular BodySignature solo si hay pose válida
    BodySignature? sig;
    if (pose != null) {
      sig = BodySignature.fromPose(pose);
    }

    // Calcular embedding facial
    final embedding = _extractFaceEmbedding(face);

    _faceEmbeddings.add(embedding);
    // Si no hay firma válida, usamos una previa o zero para no romper el promedio simple,
    // o mejor guardamos la que tengamos.
    _bodySignatures.add(sig ?? (_bodySignatures.isNotEmpty ? _bodySignatures.last : BodySignature.zero));

    return SampleResult.success;
  }

  /// Construye el EmployeeProfile promediando las 5 muestras.
  /// Precondición: isComplete == true.
  EmployeeProfile buildProfile({
    required String employeeId,
    required String workstationId,
  }) {
    assert(isComplete, 'Se necesitan $samplesRequired muestras antes de buildProfile()');

    // Promediar embeddings faciales elemento a elemento
    final length = _faceEmbeddings.first.length;
    final avgEmbedding = List<double>.filled(length, 0.0);
    for (final emb in _faceEmbeddings) {
      for (int i = 0; i < length; i++) {
        avgEmbedding[i] += emb[i] / samplesRequired;
      }
    }
    final normalizedEmbedding = EmployeeProfile.normalizeVector(avgEmbedding);

    // Promediar proporciones corporales
    final avgBody = BodySignature(
      shoulderToHipRatio: _bodySignatures.map((s) => s.shoulderToHipRatio).reduce((a, b) => a + b) / samplesRequired,
      torsoToLegRatio: _bodySignatures.map((s) => s.torsoToLegRatio).reduce((a, b) => a + b) / samplesRequired,
      armSpanRatio: _bodySignatures.map((s) => s.armSpanRatio).reduce((a, b) => a + b) / samplesRequired,
      headToShoulderRatio: _bodySignatures.map((s) => s.headToShoulderRatio).reduce((a, b) => a + b) / samplesRequired,
      neckLength: _bodySignatures.map((s) => s.neckLength).reduce((a, b) => a + b) / samplesRequired,
    );

    return EmployeeProfile(
      employeeId: employeeId,
      workstationId: workstationId,
      faceEmbedding: normalizedEmbedding,
      bodySignature: avgBody,
      capturedAt: DateTime.now(),
      sampleCount: samplesRequired,
    );
  }

  /// Reinicia el proceso de captura desde cero.
  void reset() {
    _faceEmbeddings.clear();
    _bodySignatures.clear();
  }

  void dispose() {
    _poseDetector.close();
    _faceDetector.close();
  }

  // ── Helpers privados ───────────────────────────────────────────────────────

  double _estimateFaceConfidence(Face face, Size? frameSize) {
    // 1. Tamaño relativo (0.5 weight)
    double sizeScore = 0.5; // default si no tenemos frameSize
    if (frameSize != null) {
      final boxArea = face.boundingBox.width * face.boundingBox.height;
      final frameArea = frameSize.width * frameSize.height;
      sizeScore = (boxArea / frameArea).clamp(0.0, 1.0) * 2.0; // Escalar para que ~25% sea 0.5
      sizeScore = sizeScore.clamp(0.0, 1.0);
    }

    // 2. Ángulo (0.3 weight) - Penaliza perfiles extremos
    final rotY = face.headEulerAngleY?.abs() ?? 45.0;
    final rotZ = face.headEulerAngleZ?.abs() ?? 45.0;
    final angleScore = (1.0 - ((rotY + rotZ) / 90.0)).clamp(0.0, 1.0);

    // 3. Clasificación/Landmarks (0.2 weight)
    final landmarksScore = face.landmarks.isNotEmpty ? 1.0 : 0.0;
    final eyeScore = ((face.leftEyeOpenProbability ?? 0.5) + (face.rightEyeOpenProbability ?? 0.5)) / 2.0;
    final classScore = (landmarksScore * 0.5) + (eyeScore * 0.5);

    final finalConf = (sizeScore * 0.5) + (angleScore * 0.3) + (classScore * 0.2);

    print('[SCAN] CONF DETAILS — size: ${sizeScore.toStringAsFixed(2)}, angle: ${angleScore.toStringAsFixed(2)}, class: ${classScore.toStringAsFixed(2)}');

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
    final likelihoods = keyTypes
        .map((t) => pose.landmarks[t]?.likelihood ?? 0.0)
        .toList();
    return likelihoods.reduce((a, b) => a + b) / likelihoods.length;
  }

  /// Extrae un vector de 20 floats normalizados por bounding box de los
  /// landmarks de la cara. Funciona como embedding geométrico sin dependencias externas.
  List<double> _extractFaceEmbedding(Face face) {
    final box = face.boundingBox;
    final w = box.width.clamp(1.0, double.infinity);
    final h = box.height.clamp(1.0, double.infinity);

    final landmarkOrder = [
      FaceLandmarkType.leftEye,
      FaceLandmarkType.rightEye,
      FaceLandmarkType.noseBase,
      FaceLandmarkType.leftMouth,
      FaceLandmarkType.rightMouth,
      FaceLandmarkType.bottomMouth,
      FaceLandmarkType.leftEar,
      FaceLandmarkType.rightEar,
      FaceLandmarkType.leftCheek,
      FaceLandmarkType.rightCheek,
    ];

    final embedding = <double>[];
    for (final type in landmarkOrder) {
      final lm = face.landmarks[type];
      if (lm != null) {
        embedding.add((lm.position.x - box.left) / w);
        embedding.add((lm.position.y - box.top) / h);
      } else {
        embedding.add(0.0);
        embedding.add(0.0);
      }
    }
    return embedding;
  }
}
