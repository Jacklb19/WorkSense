/* 
 * ARCHITECTURAL DECISION NOTE:
 * The Artificial Intelligence (ML) code (embeddings, landmarks, tracking) is 
 * intentionally kept here strictly inside `features/camera_monitor/ai/`.
 * 
 * In a previous refactor session, an empty `features/ai_pipeline/` directory 
 * existed causing architectural ambiguity. After careful analysis, it was 
 * determined that all computer vision and body/face signature calculations 
 * are completely exclusive to the Kiosk camera monitor feature. 
 * `camera_monitor` handles both live tracking (via EmployeeFinder) and the 
 * setup phase (via EmployeeProfiler & EmployeeScanScreen). 
 * 
 * CONDITIONS FOR EXTRACTION:
 * If the application scales to use these ML models OUTSIDE of the camera_monitor 
 * context (e.g., a cross-feature requirement where employees upload profile 
 * photos for validation from their own dashboards, or server-side CCTV video 
 * processing), then — and only then — should this logic be extracted to its 
 * own root feature module (like `features/ai_pipeline/`) to avoid circular 
 * dependencies. Until then, keep it scoped to `camera_monitor` to adhere
 * cleanly to Clean Architecture and avoid empty phantom folders.
 */

import 'package:flutter/foundation.dart';
  import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
  import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
  import 'package:worksense_app/core/constants/ai_thresholds.dart';
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

  /// Helper tipado que compara el embedding actual contra una lista de embeddings almacenados.
  /// Prepara el terreno para el uso de múltiples muestras (Improvement 2) sin requerir \'dynamic\'.
  double _compareAgainstMultiple(List<double> liveEmbedding, List<List<double>> storedEmbeddings) {
    if (liveEmbedding.isEmpty || storedEmbeddings.isEmpty) return 0.0;
    
    double maxScore = 0.0;
    // Use tracking-mode floor: lower than fresh identification threshold
    // because tracking ID already provides continuity context.
    const double threshold = AiThresholds.monitorTrackingEmbeddingFloor;

    for (final stored in storedEmbeddings) {
      if (stored.isEmpty || liveEmbedding.length != stored.length) continue;
      
      final score = EmployeeProfile.cosineSimilarity(liveEmbedding, stored);
      if (score > maxScore) {
        maxScore = score;
      }
    }

    return maxScore >= threshold ? maxScore : 0.0;
  }

  _IsolatedFindResult _computeFindInFrameWorker(_FindInFrameParams params) {
    int? currentLockedTrackingId = params.lockedTrackingId;
    final bool multiplePeople = params.faces.length > 1;
    final double identityThreshold = EmployeeProfile.identityThreshold;
    // Umbral de seguimiento más estricto si hay intrusos (múltiples personas)
    final double trackingBodyThreshold = multiplePeople ? 0.60 : 0.30;
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
            ? _compareAgainstMultiple(tracked.rawEmbedding, params.profile.faceEmbeddings)
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
      final faceScore = _compareAgainstMultiple(
        face.rawEmbedding,
        params.profile.faceEmbeddings,
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

    static const int _maxConsecutiveMisses = AiThresholds.monitorMaxConsecutiveMisses;

    EmployeeFinder(this._profile);

    EmployeeProfile get profile => _profile;
    int? get lockedTrackingId => _lockedTrackingId;

    bool isTrackingLockedTo(Face face) =>
        _lockedTrackingId != null && face.trackingId == _lockedTrackingId;

    /// Busca al empleado en el frame actual aislando los calculos pesados
    /// del UI thread para prevenir caida de frames.
    /// Busca al empleado en el frame actual aislando los calculos pesados
    /// del UI thread para prevenir caida de frames.
    Future<FindResult> findInFrame({
      required List<Face> detectedFaces,
      required List<Pose> detectedPoses,
      required Map<int, List<double>> faceEmbeddings, // [trackingId or index] -> embedding
    }) async {
      // 1. Extraer a DTOs serializables en el main thread (rápido)
      final facesDto = <_FaceData>[];
      for (int i = 0; i < detectedFaces.length; i++) {
        final face = detectedFaces[i];
        final centerX = face.boundingBox.left + face.boundingBox.width / 2;
        final centerY = face.boundingBox.top + face.boundingBox.height / 2;
        
        // Usar embedding real pasado desde el exterior (MobileFaceNet)
        // Si no hay embedding para esta cara, se envía una lista vacía o de ceros
        final embedding = faceEmbeddings[face.trackingId] ?? 
                          faceEmbeddings[i] ?? 
                          const [];

        facesDto.add(_FaceData(
          i,
          face.trackingId,
          embedding,
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

    void reset() {
      _lockedTrackingId = null;
      _consecutiveMisses = 0;
      _lastFoundTime = null;
    }
  }

