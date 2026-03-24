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
  static const double minFaceConfidence = 0.75;
  static const double minPoseConfidence = 0.60;

  static const List<ScanInstruction> instructions = [
    ScanInstruction(
      index: 0,
      text: 'Mira directo a la cámara en tu posición normal de trabajo',
      emoji: '👁️',
    ),
    ScanInstruction(
      index: 1,
      text: 'Gira levemente la cabeza hacia tu izquierda (15-20 grados)',
      emoji: '↖️',
    ),
    ScanInstruction(
      index: 2,
      text: 'Gira levemente la cabeza hacia tu derecha (15-20 grados)',
      emoji: '↗️',
    ),
    ScanInstruction(
      index: 3,
      text: 'Inclina la cabeza levemente hacia abajo (como mirando el escritorio)',
      emoji: '⬇️',
    ),
    ScanInstruction(
      index: 4,
      text: 'Levanta levemente la cabeza (como mirando una pantalla alta)',
      emoji: '⬆️',
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

    // Confianza de cara (derivada de landmarks)
    final faceConf = _estimateFaceConfidence(face);
    if (faceConf < minFaceConfidence) return SampleResult.lowConfidence;

    // Debe detectarse al menos 1 pose
    if (poses.isEmpty) return SampleResult.noPose;

    final pose = poses.first;

    // Verificar confianza de pose con landmarks principales
    final poseConf = _estimatePoseConfidence(pose);
    if (poseConf < minPoseConfidence) return SampleResult.lowConfidence;

    // Calcular BodySignature
    final sig = BodySignature.fromPose(pose);
    if (sig == null || !sig.isValid) return SampleResult.invalidSignature;

    // Calcular embedding facial
    final embedding = _extractFaceEmbedding(face);

    _faceEmbeddings.add(embedding);
    _bodySignatures.add(sig);

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

  double _estimateFaceConfidence(Face face) {
    double conf = 0.75;
    if (face.landmarks.isNotEmpty) conf = 0.85;
    if (face.headEulerAngleY != null) conf = 0.90;
    return conf;
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
