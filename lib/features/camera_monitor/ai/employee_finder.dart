  import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
  import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
  import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';
  import 'package:worksense_app/features/camera_monitor/ai/employee_profile.dart';

  enum FindStatus { found, outsideArea, absent }

  enum IdentificationMethod { trackingId, faceEmbedding, body, combined }

  class FindResult {
    final FindStatus status;
    final Face? employeeFace;
    final Pose? employeePose;
    final double confidence;
    final IdentificationMethod? identifiedBy;

    const FindResult._({
      required this.status,
      this.employeeFace,
      this.employeePose,
      this.confidence = 0.0,
      this.identifiedBy,
    });

    factory FindResult.absent() => const FindResult._(status: FindStatus.absent);

    factory FindResult.outsideArea() =>
        const FindResult._(status: FindStatus.outsideArea, confidence: 0.85);

    factory FindResult.found({
      required Face face,
      Pose? pose,
      required double confidence,
      required IdentificationMethod method,
    }) =>
        FindResult._(
          status: FindStatus.found,
          employeeFace: face,
          employeePose: pose,
          confidence: confidence,
          identifiedBy: method,
        );
  }

  /// Motor de búsqueda del empleado en tiempo real.
  /// Se instancia una vez al iniciar el Kiosk y se reutiliza en cada frame.
  class EmployeeFinder {
    final EmployeeProfile _profile;

    int? _lockedTrackingId;
    int _consecutiveMisses = 0;
    DateTime? _lastFoundTime;

    static const double _identityThreshold = EmployeeProfile.identityThreshold;
    static const double _trackingBodyThreshold = 0.30;
    static const int _maxConsecutiveMisses = 5;
    static const double _maxFaceToPoseDistance = 200.0;

    EmployeeFinder(this._profile);

    EmployeeProfile get profile => _profile;

    /// Busca al empleado en el frame actual.
    Future<FindResult> findInFrame({
      required List<Face> detectedFaces,
      required List<Pose> detectedPoses,
    }) async {
      // Caso 1: nadie en cámara
      if (detectedFaces.isEmpty && detectedPoses.isEmpty) {
        _consecutiveMisses++;
        if (_consecutiveMisses >= _maxConsecutiveMisses) _lockedTrackingId = null;
        return FindResult.absent();
      }

      // Caso 2: optimización por trackingId (rápido)
      if (_lockedTrackingId != null) {
        final tracked = detectedFaces
            .where((f) => f.trackingId == _lockedTrackingId)
            .firstOrNull;

        if (tracked != null) {
          // Extraer embedding facial del frame actual
          final faceEmb = extractFaceEmbedding(tracked);
          final faceScore = faceEmb.any((v) => v != 0.0)
              ? EmployeeProfile.cosineSimilarity(faceEmb, _profile.faceEmbedding)
              : null;

          final closestPose = _closestPoseTo(tracked, detectedPoses);
          final bodyScore = closestPose != null
              ? _calculateBodyScore(closestPose)
              : null;

          final score = _profile.matchScore(
            faceScore: faceScore,
            bodyScore: bodyScore,
          );

          if (score >= _trackingBodyThreshold) {
            _consecutiveMisses = 0;
            _lastFoundTime = DateTime.now();
            return FindResult.found(
              face: tracked,
              pose: closestPose,
              confidence: score,
              method: IdentificationMethod.trackingId,
            );
          }
        }

        // Si el trackingId falló (cara no encontrada o score insuficiente),
        // limpiar para permitir que el Caso 3 ejecute en este mismo frame.
        _lockedTrackingId = null;
      }

      // Caso 3: búsqueda completa por embedding facial
      // (siempre ejecuta si llegamos aquí, porque el Caso 2 ya limpió _lockedTrackingId)
      _lockedTrackingId = null;

      Face? bestFace;
      Pose? bestPose;
      double bestScore = 0.0;
      IdentificationMethod bestMethod = IdentificationMethod.faceEmbedding;

      print('[FINDER] Profile faceEmbedding length: ${_profile.faceEmbedding.length}');
      print('[FINDER] Profile bodySignature valid: ${_profile.bodySignature.isValid}');
      print('[FINDER] Faces detectadas: ${detectedFaces.length}');

      for (final face in detectedFaces) {
        final faceEmb = extractFaceEmbedding(face);
        final faceScore = EmployeeProfile.cosineSimilarity(
          faceEmb,
          _profile.faceEmbedding,
        );
        print('[FINDER] faceEmb length: ${faceEmb.length}, score: $faceScore');
        print('[FINDER] face landmarks count: ${face.landmarks.length}');

        final closestPose = _closestPoseTo(face, detectedPoses);
        final bodyScore =
            closestPose != null ? _calculateBodyScore(closestPose) : null;

        IdentificationMethod method;
        if (faceScore > 0 && bodyScore != null) {
          method = IdentificationMethod.combined;
        } else if (faceScore > 0) {
          method = IdentificationMethod.faceEmbedding;
        } else {
          method = IdentificationMethod.body;
        }

        final combined = _profile.matchScore(
          faceScore: faceScore > 0 ? faceScore : null,
          bodyScore: bodyScore,
        );

        if (combined > bestScore) {
          bestScore = combined;
          bestFace = face;
          bestPose = closestPose;
          bestMethod = method;
        }
      }

      if (bestScore >= _identityThreshold && bestFace != null) {
        _lockedTrackingId = bestFace.trackingId;
        _consecutiveMisses = 0;
        _lastFoundTime = DateTime.now();
        return FindResult.found(
          face: bestFace,
          pose: bestPose,
          confidence: bestScore,
          method: bestMethod,
        );
      }

      // Confianza parcial — aceptar con tracking pero sin bloqueo fuerte
      if (bestScore >= _identityThreshold * 0.75 && bestFace != null) {
        _lockedTrackingId = bestFace.trackingId;
        _consecutiveMisses = 0;
        _lastFoundTime = DateTime.now();
        return FindResult.found(
          face: bestFace,
          pose: bestPose,
          confidence: bestScore,
          method: bestMethod,
        );
      }

      // Si hay personas pero ninguna es el empleado
      if (detectedFaces.isNotEmpty || detectedPoses.isNotEmpty) {
        _consecutiveMisses++;
        return FindResult.outsideArea();
      }

      _consecutiveMisses++;
      return FindResult.absent();
    }

    /// Encuentra la pose más cercana a una cara (por posición de nariz).
    Pose? _closestPoseTo(Face face, List<Pose> poses) {
      if (poses.isEmpty) return null;

      final faceCenterX =
          face.boundingBox.left + face.boundingBox.width / 2;
      final faceCenterY =
          face.boundingBox.top + face.boundingBox.height / 2;

      Pose? closest;
      double minDist = double.infinity;

      for (final pose in poses) {
        final nose = pose.landmarks[PoseLandmarkType.nose];
        if (nose == null) continue;

        final dx = nose.x - faceCenterX;
        final dy = nose.y - faceCenterY;
        final dist = dx * dx + dy * dy;

        if (dist < minDist) {
          minDist = dist;
          closest = pose;
        }
      }

      // Rechazar si la distancia es mayor al umbral
      if (minDist > _maxFaceToPoseDistance * _maxFaceToPoseDistance) return null;
      return closest;
    }

    double _calculateBodyScore(Pose pose) {
      final sig = BodySignature.fromPose(pose);
      if (sig == null || !sig.isValid) return 0.0;
      return _profile.bodySignature.similarityTo(sig);
    }

    /// Extrae embedding facial geométrico de los landmarks de la cara.
    static List<double> extractFaceEmbedding(Face face) {
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

    /// Resetea el estado interno (llamar al reiniciar el Kiosk o re-escanear).
    void reset() {
      _lockedTrackingId = null;
      _consecutiveMisses = 0;
      _lastFoundTime = null;
    }
  }
