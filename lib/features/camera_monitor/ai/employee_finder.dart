  import 'package:flutter/foundation.dart';
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

  // DTOs para comunicación con Isolate
  class _FindInFrameParams {
    final EmployeeProfile profile;
    final List<_FaceData> faces;
    final List<_PoseData> poses;
    final int? lockedTrackingId;

    _FindInFrameParams(this.profile, this.faces, this.poses, this.lockedTrackingId);
  }

  class _FaceData {
    final int index;
    final int? trackingId;
    final List<double> rawEmbedding;
    final double centerX;
    final double centerY;

    _FaceData(this.index, this.trackingId, this.rawEmbedding, this.centerX, this.centerY);
  }

  class _PoseData {
    final int index;
    final double noseX;
    final double noseY;
    final BodySignature? signature;

    _PoseData(this.index, this.noseX, this.noseY, this.signature);
  }

  class _IsolatedFindResult {
    final FindStatus status;
    final int? faceIndex;
    final int? poseIndex;
    final double confidence;
    final IdentificationMethod? identifiedBy;
    final int? newLockedTrackingId;
    final bool clearLockedTrackingId;

    _IsolatedFindResult({
      required this.status,
      this.faceIndex,
      this.poseIndex,
      this.confidence = 0.0,
      this.identifiedBy,
      this.newLockedTrackingId,
      this.clearLockedTrackingId = false,
    });
  }

  _IsolatedFindResult _computeFindInFrameWorker(_FindInFrameParams params) {
    int? currentLockedTrackingId = params.lockedTrackingId;
    const double identityThreshold = EmployeeProfile.identityThreshold;
    const double trackingBodyThreshold = 0.30;
    const double maxFaceToPoseDistance = 200.0;

    if (params.faces.isEmpty && params.poses.isEmpty) {
      return _IsolatedFindResult(status: FindStatus.absent);
    }

    // Caso 2: optimización por trackingId
    if (currentLockedTrackingId != null) {
      final tracked = params.faces
          .where((f) => f.trackingId == currentLockedTrackingId)
          .firstOrNull;

      if (tracked != null) {
        final faceScore = tracked.rawEmbedding.any((v) => v != 0.0)
            ? EmployeeProfile.cosineSimilarity(tracked.rawEmbedding, params.profile.faceEmbedding)
            : null;

        _PoseData? closestPose;
        double minDist = double.infinity;
        for (final p in params.poses) {
          final dx = p.noseX - tracked.centerX;
          final dy = p.noseY - tracked.centerY;
          final dist = dx * dx + dy * dy;
          if (dist < minDist && dist <= maxFaceToPoseDistance * maxFaceToPoseDistance) {
            minDist = dist;
            closestPose = p;
          }
        }

        final bodyScore = closestPose?.signature != null && closestPose!.signature!.isValid
            ? params.profile.bodySignature.similarityTo(closestPose.signature!)
            : null;

        final score = params.profile.matchScore(
          faceScore: faceScore,
          bodyScore: bodyScore,
        );

        if (score >= trackingBodyThreshold) {
          return _IsolatedFindResult(
            status: FindStatus.found,
            faceIndex: tracked.index,
            poseIndex: closestPose?.index,
            confidence: score,
            identifiedBy: IdentificationMethod.trackingId,
            newLockedTrackingId: currentLockedTrackingId,
          );
        }
      }
    }

    _FaceData? bestFace;
    _PoseData? bestPose;
    double bestScore = 0.0;
    IdentificationMethod bestMethod = IdentificationMethod.faceEmbedding;

    for (final face in params.faces) {
      final faceScore = EmployeeProfile.cosineSimilarity(
        face.rawEmbedding,
        params.profile.faceEmbedding,
      );

      _PoseData? closestPose;
      double minDist = double.infinity;
      for (final p in params.poses) {
        final dx = p.noseX - face.centerX;
        final dy = p.noseY - face.centerY;
        final dist = dx * dx + dy * dy;
        if (dist < minDist && dist <= maxFaceToPoseDistance * maxFaceToPoseDistance) {
          minDist = dist;
          closestPose = p;
        }
      }

      final bodyScore =
          closestPose?.signature != null && closestPose!.signature!.isValid
              ? params.profile.bodySignature.similarityTo(closestPose.signature!)
              : null;

      IdentificationMethod method;
      if (faceScore > 0 && bodyScore != null) {
        method = IdentificationMethod.combined;
      } else if (faceScore > 0) {
        method = IdentificationMethod.faceEmbedding;
      } else {
        method = IdentificationMethod.body;
      }

      final combined = params.profile.matchScore(
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

    if (bestScore >= identityThreshold && bestFace != null) {
      return _IsolatedFindResult(
        status: FindStatus.found,
        faceIndex: bestFace.index,
        poseIndex: bestPose?.index,
        confidence: bestScore,
        identifiedBy: bestMethod,
        newLockedTrackingId: bestFace.trackingId,
        clearLockedTrackingId: true,
      );
    }

    if (bestScore >= identityThreshold * 0.75 && bestFace != null) {
      return _IsolatedFindResult(
        status: FindStatus.found,
        faceIndex: bestFace.index,
        poseIndex: bestPose?.index,
        confidence: bestScore,
        identifiedBy: bestMethod,
        newLockedTrackingId: bestFace.trackingId,
        clearLockedTrackingId: true,
      );
    }

    if (params.faces.isNotEmpty || params.poses.isNotEmpty) {
      return _IsolatedFindResult(
        status: FindStatus.outsideArea,
        clearLockedTrackingId: true,
      );
    }

    return _IsolatedFindResult(
      status: FindStatus.absent,
      clearLockedTrackingId: true,
    );
  }

  /// Motor de búsqueda del empleado en tiempo real.
  /// Se instancia una vez al iniciar el Kiosk y se reutiliza en cada frame.
  class EmployeeFinder {
    final EmployeeProfile _profile;

    int? _lockedTrackingId;
    int _consecutiveMisses = 0;
    DateTime? _lastFoundTime;

    static const int _maxConsecutiveMisses = 5;

    EmployeeFinder(this._profile);

    EmployeeProfile get profile => _profile;

    /// Busca al empleado en el frame actual aislando los calculos pesados
    /// del UI thread para prevenir caida de frames.
    Future<FindResult> findInFrame({
      required List<Face> detectedFaces,
      required List<Pose> detectedPoses,
    }) async {
      // 1. Extraer a DTOs serializables en el main thread (rápido)
      final facesDto = <_FaceData>[];
      for (int i = 0; i < detectedFaces.length; i++) {
        final face = detectedFaces[i];
        final centerX = face.boundingBox.left + face.boundingBox.width / 2;
        final centerY = face.boundingBox.top + face.boundingBox.height / 2;
        facesDto.add(_FaceData(
          i,
          face.trackingId,
          extractFaceEmbedding(face),
          centerX,
          centerY,
        ));
      }

      final posesDto = <_PoseData>[];
      for (int i = 0; i < detectedPoses.length; i++) {
        final pose = detectedPoses[i];
        final nose = pose.landmarks[PoseLandmarkType.nose];
        if (nose != null) {
          posesDto.add(_PoseData(
            i,
            nose.x,
            nose.y,
            BodySignature.fromPose(pose),
          ));
        }
      }

      final params = _FindInFrameParams(
        _profile,
        facesDto,
        posesDto,
        _lockedTrackingId,
      );

      // 2. Ejecutar cálculo pesado en Isolate
      final isolatedResult = await compute(_computeFindInFrameWorker, params);

      // 3. Manejar el regreso del estado local
      if (isolatedResult.clearLockedTrackingId) {
        _lockedTrackingId = null;
      }
      
      if (isolatedResult.newLockedTrackingId != null) {
        _lockedTrackingId = isolatedResult.newLockedTrackingId;
      }

      if (isolatedResult.status == FindStatus.absent || isolatedResult.status == FindStatus.outsideArea) {
        _consecutiveMisses++;
        if (_consecutiveMisses >= _maxConsecutiveMisses) {
          _lockedTrackingId = null;
        }
      } else {
        _consecutiveMisses = 0;
        _lastFoundTime = DateTime.now();
      }

      // 4. Mapear al modelo que requiere objetos nativos (Face y Pose)
      if (isolatedResult.status == FindStatus.found && isolatedResult.faceIndex != null) {
        return FindResult.found(
          face: detectedFaces[isolatedResult.faceIndex!],
          pose: isolatedResult.poseIndex != null ? detectedPoses[isolatedResult.poseIndex!] : null,
          confidence: isolatedResult.confidence,
          method: isolatedResult.identifiedBy!,
        );
      } else if (isolatedResult.status == FindStatus.outsideArea) {
        return FindResult.outsideArea();
      } else {
        return FindResult.absent();
      }
    }

    /// Extrae embedding facial geométrico de los landmarks de la cara. (ejecuta rápido)
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

    void reset() {
      _lockedTrackingId = null;
      _consecutiveMisses = 0;
      _lastFoundTime = null;
    }
  }
