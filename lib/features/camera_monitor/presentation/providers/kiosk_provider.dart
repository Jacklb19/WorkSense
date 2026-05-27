import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart' show SchedulerBinding;
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/core/utils/biometric_utils.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:worksense_app/data/repositories/activity_repository_impl.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/ai/activity_classifier.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';
import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_finder.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profile.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_embedding_service.dart';
import 'package:worksense_app/features/camera_monitor/ai/pose_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/domain/usecases/save_activity_event_use_case.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';
import 'package:worksense_app/domain/entities/workstation.dart';

// ── Database Provider ──────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Repository Provider ────────────────────────────────────────────────────────
final activityRepositoryProvider = Provider<ActivityRepositoryImpl>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return ActivityRepositoryImpl(db, syncRepo);
});

// ── Save Use Case Provider ─────────────────────────────────────────────────────

final saveActivityEventUseCaseProvider =
    Provider<SaveActivityEventUseCase>((ref) {
  final repo = ref.watch(activityRepositoryProvider);
  return SaveActivityEventUseCase(repo);
});

// ── Kiosk State ────────────────────────────────────────────────────────────────

enum SessionStatus {
  idle,            // Buscando empleado / Esperando sensor
  entryPending,    // Empleado detectado con alta confianza, esperando que presione 'Confirmar Entrada'
  active,          // Empleado trabajando, monitoreo de actividad vivo
  exitPending,     // Empleado detectado, esperando que presione 'Confirmar Salida'
}

class KioskState {
  final ActivityState currentState;
  final double confidence;
  final bool isProcessing;
  final int frameCount;
  final DateTime? lastEventTime;
  final bool cameraInitialized;
  final String? error;
  final String workstationId;
  final List<Pose> poses;
  final List<Face> faces;
  final Size imageSize;
  final String? companyId;

  // Re-identificación y Sesión
  final SessionStatus sessionStatus;
  final bool isEmployeeScanned;
  final EmployeeProfile? employeeProfile;
  final String? identificationMethod;
  final double identityConfidence;
  final String? assignedEmployeeId;
  final WorkstationRoi? workstationRoi;
  final DateTime? sessionStartTime;
  
  // Sentinel Mode
  final String workstationStatus;

  const KioskState({
    this.currentState = ActivityState.noIdentificado,
    this.confidence = 0.0,
    this.isProcessing = false,
    this.frameCount = 0,
    this.lastEventTime,
    this.cameraInitialized = false,
    this.error,
    this.workstationId = '',
    this.companyId,
    this.poses = const [],
    this.faces = const [],
    this.imageSize = Size.zero,
    this.sessionStatus = SessionStatus.idle,
    this.isEmployeeScanned = false,
    this.employeeProfile,
    this.identificationMethod,
    this.identityConfidence = 0.0,
    this.assignedEmployeeId,
    this.sessionStartTime,
    this.workstationStatus = 'IDLE',
    this.workstationRoi,
  });

  // Sentinel object used by copyWith to distinguish "pass null intentionally"
  // from "don't change this field". Dart doesn't have a built-in way to do this
  // for nullable types, so we use a private sentinel.
  static const _kKeep = Object();

  KioskState copyWith({
    ActivityState? currentState,
    double? confidence,
    bool? isProcessing,
    int? frameCount,
    DateTime? lastEventTime,
    bool? cameraInitialized,
    String? error,
    String? workstationId,
    List<Pose>? poses,
    List<Face>? faces,
    Size? imageSize,
    String? companyId,
    SessionStatus? sessionStatus,
    bool? isEmployeeScanned,
    EmployeeProfile? employeeProfile,
    Object? identificationMethod = _kKeep, // Object? allows explicit null
    double? identityConfidence,
    String? assignedEmployeeId,
    Object? sessionStartTime = _kKeep,     // Object? allows explicit null
    String? workstationStatus,
    WorkstationRoi? workstationRoi,
  }) {
    return KioskState(
      currentState: currentState ?? this.currentState,
      confidence: confidence ?? this.confidence,
      isProcessing: isProcessing ?? this.isProcessing,
      frameCount: frameCount ?? this.frameCount,
      lastEventTime: lastEventTime ?? this.lastEventTime,
      cameraInitialized: cameraInitialized ?? this.cameraInitialized,
      error: error,
      workstationId: workstationId ?? this.workstationId,
      poses: poses ?? this.poses,
      faces: faces ?? this.faces,
      imageSize: imageSize ?? this.imageSize,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      isEmployeeScanned: isEmployeeScanned ?? this.isEmployeeScanned,
      employeeProfile: employeeProfile ?? this.employeeProfile,
      identificationMethod: identical(identificationMethod, _kKeep)
          ? this.identificationMethod
          : identificationMethod as String?,
      identityConfidence: identityConfidence ?? this.identityConfidence,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      sessionStartTime: identical(sessionStartTime, _kKeep)
          ? this.sessionStartTime
          : sessionStartTime as DateTime?,
      workstationStatus: workstationStatus ?? this.workstationStatus,
      companyId: companyId ?? this.companyId,
      workstationRoi: workstationRoi ?? this.workstationRoi,
    );
  }
}

// ── Activity Window Buffer ───────────────────────────────────────────────────

class _WindowEntry {
  final ActivityState state;
  final DateTime timestamp;
  _WindowEntry(this.state, this.timestamp);
}

class ActivityWindowBuffer {
  final Duration windowDuration;
  final List<_WindowEntry> _buffer = [];

  ActivityWindowBuffer({this.windowDuration = const Duration(seconds: 4)});

  /// Adds a new frame-level state. Returns the majority state if a full window is completed,
  /// otherwise returns null indicating the window is still accumulating.
  ActivityState addAndGetMajority(ActivityState state, DateTime timestamp) {
    _buffer.add(_WindowEntry(state, timestamp));

    _buffer.removeWhere((entry) => 
        timestamp.difference(entry.timestamp) > windowDuration);

    final counts = <ActivityState, int>{};
    for (final entry in _buffer) {
      counts[entry.state] = (counts[entry.state] ?? 0) + 1;
    }

    // [TIE-BREAK EXPLICITO]
    // Inicializamos con el estado del frame actual (state) y su conteo.
    // Si hay un empate absoluto con otro estado en el buffer, el > estricto 
    // evita sobreescribirlo. Así, la balanza siempre favorece lo más reciente.
    var majorityState = state;
    var maxCount = counts[state] ?? 0;
    
    for (final entry in counts.entries) {
      if (entry.key != state && entry.value > maxCount) {
        maxCount = entry.value;
        majorityState = entry.key;
      }
    }

    return majorityState;
  }

  void reset() {
    _buffer.clear();
  }
}

// ── Kiosk Notifier ─────────────────────────────────────────────────────────────

class KioskNotifier extends StateNotifier<KioskState> {
  final SaveActivityEventUseCase _saveEventUseCase;
  final AppDatabase _db;
  final FaceEmbeddingService _embeddingService;

  CameraController? _cameraController;
  late final PoseDetector _poseDetector;
  late final FaceDetector _faceDetector;
  late final PoseAnalyzer _poseAnalyzer;
  late final FaceAnalyzer _faceAnalyzer;
  late final ActivityClassifier _classifier;
  late final ActivityWindowBuffer _activityWindowBuffer;

  EmployeeFinder? _finder;

  bool _isAnalyzing = false;
  bool _disposed = false;
  DateTime _lastAnalysisTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastReidTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _consecutiveAbsentFrames = 0;
  int _consecutiveFaceMissFrames = 0;
  int _stableEntryFrames = 0;
  bool _requiresFreshIdentityCheck = true;

  /// Timestamp when the locked employee first went absent during an active session.
  /// Null means they are present (or no active session).
  DateTime? _absenceStart;

  /// After this many seconds absent during an active session, the session is
  /// cancelled and the kiosk returns to idle (requiring a new face detection).
  static const Duration _absenceTimeout = Duration(seconds: 5);

  /// Number of consecutive absent frames required to cancel entryPending/exitPending.
  static const int _absentFramesToCancel = 8;
  
  StreamSubscription? _remoteSub;

  static const Duration _analysisInterval = Duration(milliseconds: 600);
  static const Duration _saveInterval = Duration(
    seconds: AiThresholds.defaultAnalysisIntervalSeconds,
  );

  /// Dynamic re-ID interval: longer during stable active sessions,
  /// shorter when there's ambiguity or fresh check needed.
  Duration get _currentReidInterval {
    if (state.sessionStatus == SessionStatus.active &&
        !_requiresFreshIdentityCheck &&
        _consecutiveFaceMissFrames == 0) {
      return const Duration(seconds: AiThresholds.monitorStableReidSeconds);
    }
    return const Duration(seconds: AiThresholds.monitorAmbiguousReidSeconds);
  }

  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  KioskNotifier(this._saveEventUseCase, this._db, this._embeddingService) 
      : super(const KioskState()) {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableTracking: true,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );
    _poseAnalyzer = PoseAnalyzer();
    _faceAnalyzer = FaceAnalyzer();
    _classifier = ActivityClassifier();
    _activityWindowBuffer = ActivityWindowBuffer(windowDuration: const Duration(seconds: 4));
    
    // Asegurar que el modelo TFLite esté cargado
    _embeddingService.initialize();
  }

  CameraController? get cameraController => _cameraController;

  /// Sets the workstation ID for this kiosk session.
  void setWorkstationId(String id) {
    state = state.copyWith(workstationId: id);
  }

  /// Sets an error message to be displayed on screen.
  void setError(String message) {
    state = state.copyWith(error: message);
  }

  /// Carga el perfil del empleado desde Drift y arranca la cámara si existe.
  /// Retorna true si hay perfil registrado, false si hay que escanear.
  Future<bool> loadProfileAndInit(
      List<CameraDescription> cameras, String workstationId) async {
    state = state.copyWith(workstationId: workstationId);

    final record = await _db.getWorkstationById(workstationId);
    final assignedId = record?.assignedEmployeeId;
    final companyId = record?.companyId;
    WorkstationRoi? roi;
    final roiJson = record != null ? await _db.getWorkstationRoi(workstationId) : null;
    if (roiJson != null && roiJson.isNotEmpty) {
      try {
        roi = WorkstationRoi.fromMap(
          (jsonDecode(roiJson) as Map<String, dynamic>),
        );
      } catch (_) {}
    }

    if (record != null &&
        record.faceEmbeddings != null &&
        record.bodySignature != null &&
        assignedId != null) {
      final profile = await _buildStoredProfile(
        record,
        assignedId,
        workstationId,
      );

      if (profile != null) {
        _finder = EmployeeFinder(profile);
        debugPrint('[MONITOR] Perfil cargado para ${profile.employeeId}.');
        state = state.copyWith(
          isEmployeeScanned: true,
          employeeProfile: profile,
          assignedEmployeeId: assignedId,
          currentState: ActivityState.ausente,
          sessionStatus: SessionStatus.idle,
          companyId: companyId,
          workstationRoi: roi,
        );

        _listenRemoteStatus(workstationId);

        return true;
      }
    }

    // Sin perfil biométrico
    state = state.copyWith(
      isEmployeeScanned: false,
      assignedEmployeeId: assignedId,
      currentState: ActivityState.noIdentificado,
      companyId: companyId,
      workstationRoi: roi,
    );
    
    _listenRemoteStatus(workstationId);
    return false;
  }

  Future<EmployeeProfile?> _buildStoredProfile(
    WorkstationRecord record,
    String assignedId,
    String workstationId,
  ) async {
    final snapshot = await _db.getProfileSnapshot(workstationId);
    if (snapshot != null && snapshot.isNotEmpty) {
      try {
        return EmployeeProfile.fromJsonString(snapshot);
      } catch (e) {
        debugPrint('[MONITOR] Error parsing snapshot, fallback legacy: $e');
      }
    }

    final embeddingRaw =
        BiometricSerializer.deserializeMultipleEmbeddings(record.faceEmbeddings);
    if (embeddingRaw == null || record.bodySignature == null) return null;

    final bodyJson =
        (jsonDecode(record.bodySignature!) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, (v as num).toDouble()));

    return EmployeeProfile(
      employeeId: assignedId,
      workstationId: workstationId,
      faceEmbeddings: embeddingRaw,
      bodySignature: BodySignature.fromJson(bodyJson),
      capturedAt: record.profileCapturedAt ?? DateTime.now(),
      sampleCount: embeddingRaw.length,
      version: record.profileVersion,
      lastReenrollmentAt: record.profileCapturedAt,
    );
  }
  
  void _listenRemoteStatus(String workstationId) {
    _remoteSub?.cancel();
    _remoteSub = Supabase.instance.client
        .from('workstations')
        .stream(primaryKey: ['id'])
        .eq('id', workstationId)
        .listen((events) async {
      if (events.isEmpty) return;
      final data = events.first;
      final status = data['status'] as String? ?? 'IDLE';

      final bool isRunning = _cameraController != null && state.cameraInitialized;

      // Only start the monitoring camera when an enrolled profile exists.
      // Starting it without a profile would (a) block touches on the enrollment UI,
      // (b) draw pose/face landmarks over the enrollment text, and
      // (c) conflict with the enrollment camera for the physical camera resource.
      if (status == 'ACTIVE' && state.isEmployeeScanned) {
        if (isRunning) {
          // Camera already running — could be a stale session from the wrong person.
          // Stop and restart cleanly to ensure fresh tracking state.
          debugPrint('[REALTIME] Camera already running on ACTIVE — restarting cleanly for $workstationId');
          await stopCamera();
          _resetMonitoringSession();
        }
        debugPrint('[REALTIME] Activating camera for $workstationId');
        final cameras = await availableCameras();
        await initializeCamera(cameras);
      } else if (status == 'IDLE') {
        if (isRunning) {
          debugPrint('[REALTIME] Deactivating camera for $workstationId');
          await stopCamera();
        }
        // Full session reset so that the next ACTIVE event starts fresh
        _resetMonitoringSession();
      } else if (status == 'BREAK' && isRunning) {
        debugPrint('[REALTIME] Pausing camera for break');
        await stopCamera();
      }

      if (!_disposed) state = state.copyWith(workstationStatus: status);
    }, onError: (e) {
      debugPrint('[REALTIME Error] $e');
    });
  }

  /// Resets all in-memory monitoring session state without touching the camera.
  /// Call this when a session ends (IDLE) or needs a clean restart (new ACTIVE).
  void _resetMonitoringSession() {
    _consecutiveAbsentFrames = 0;
    _consecutiveFaceMissFrames = 0;
    _stableEntryFrames = 0;
    _requiresFreshIdentityCheck = true;
    _absenceStart = null;
    _lastReidTime = DateTime.fromMillisecondsSinceEpoch(0);
    _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(0);
    _activityWindowBuffer.reset();
    _finder?.reset();
    if (!_disposed) {
      state = state.copyWith(
        sessionStatus: SessionStatus.idle,
        currentState: ActivityState.ausente,
        identityConfidence: 0.0,
        sessionStartTime: null, // now properly clears to null via sentinel
        poses: const [],
        faces: const [],
      );
    }
    debugPrint('[MONITOR] Session state reset complete.');
  }

  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      state = state.copyWith(error: 'No se encontraron cámaras.');
      return;
    }

    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
      state = state.copyWith(cameraInitialized: true, error: null);
      await _startImageStream();
    } catch (e) {
      state = state.copyWith(
        error: 'No se pudo iniciar la cámara.',
        cameraInitialized: false,
      );
    }
  }

  Future<void> _startImageStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) return;
    await _cameraController!.startImageStream(_processFrame);
  }

  void _processFrame(CameraImage image) {
    if (_disposed || _isAnalyzing) return;

    final now = DateTime.now();
    if (now.difference(_lastAnalysisTime) < _analysisInterval) return;

    _isAnalyzing = true;
    _lastAnalysisTime = now;
    state = state.copyWith(
      isProcessing: true,
      frameCount: state.frameCount + 1,
    );

    _analyzeFrame(image, now).then((_) {
      _isAnalyzing = false;
    }).catchError((e) {
      debugPrint('[MONITOR] Error en frame: $e');
      _isAnalyzing = false;
      state = state.copyWith(isProcessing: false);
    });
  }

  Future<void> _analyzeFrame(CameraImage image, DateTime now) async {
    if (_disposed) return;
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }

      final rot = inputImage.metadata?.rotation ?? InputImageRotation.rotation0deg;
      final bool isRotated = rot == InputImageRotation.rotation90deg ||
          rot == InputImageRotation.rotation270deg;
      final imgSize = Size(
        isRotated ? image.height.toDouble() : image.width.toDouble(),
        isRotated ? image.width.toDouble() : image.height.toDouble(),
      );

      final results = await Future.wait([
        _poseDetector.processImage(inputImage),
        _faceDetector.processImage(inputImage),
      ]);
      if (_disposed) return;

      final allPoses = results[0] as List<Pose>;
      final allFaces = results[1] as List<Face>;

      if (_finder == null) {
        state = state.copyWith(
          currentState: ActivityState.noIdentificado,
          isProcessing: false,
          poses: allPoses,
          faces: allFaces,
          imageSize: imgSize,
        );
        return;
      }

      // ── Generación de Embeddings Inteligente ────────────────────────────────
      final Map<int, List<double>> embeddingsMap = {};
      final bool needsIdentification = state.sessionStatus == SessionStatus.idle || 
                                       state.sessionStatus == SessionStatus.entryPending;
      final bool hasIntruder = allFaces.length > 1;
      final bool shouldReid = now.difference(_lastReidTime) >= _currentReidInterval;
      final bool shouldGenerateEmbeddings =
          needsIdentification ||
          shouldReid ||
          hasIntruder ||
          _requiresFreshIdentityCheck;

      // Grace period: only flag fresh identity check after consecutive misses
      // exceed the threshold, not on every single miss frame.
      if (state.sessionStatus == SessionStatus.active) {
        if (allFaces.isEmpty) {
          _consecutiveFaceMissFrames++;
          if (_consecutiveFaceMissFrames >= AiThresholds.monitorGracePeriodFrames) {
            _requiresFreshIdentityCheck = true;
          }
        } else if (allFaces.length > 1) {
          // Multiple faces: immediate revalidation concern
          _requiresFreshIdentityCheck = true;
          _consecutiveFaceMissFrames = 0;
        } else if (!_finder!.isTrackingLockedTo(allFaces.first)) {
          _consecutiveFaceMissFrames++;
          if (_consecutiveFaceMissFrames >= AiThresholds.monitorGracePeriodFrames) {
            _requiresFreshIdentityCheck = true;
          }
        } else {
          _consecutiveFaceMissFrames = 0;
        }
      }
      
      if (allFaces.isNotEmpty && shouldGenerateEmbeddings) {
        if (hasIntruder) {
          debugPrint('[MONITOR] Intruder detection! Force validating all ${allFaces.length} faces.');
        }
        for (final face in allFaces) {
          final cropped = await _faceAnalyzer.cropFaceFromCameraImageAsync(image, face);
          if (cropped != null) {
            final emb = await _embeddingService.generateEmbedding(cropped);
            embeddingsMap[face.trackingId ?? allFaces.indexOf(face)] = emb;
            _lastReidTime = now;
          }
        }
      }

      final bool canTrustTrackedOwnerWithoutEmbedding =
          embeddingsMap.isEmpty &&
          state.sessionStatus == SessionStatus.active &&
          !_requiresFreshIdentityCheck &&
          allFaces.length == 1 &&
          _finder!.isTrackingLockedTo(allFaces.first);

      if (canTrustTrackedOwnerWithoutEmbedding) {
        _consecutiveAbsentFrames = 0; // reset, person is clearly visible
        _absenceStart = null; // clear absence timer — employee is tracked
        
        // Pick the largest face for activity analysis
        final largestFace = allFaces.reduce((a, b) =>
          (a.boundingBox.width * a.boundingBox.height) > (b.boundingBox.width * b.boundingBox.height) ? a : b);
        
        // Find closest pose to the largest face
        Pose? closestPose;
        if (allPoses.isNotEmpty) {
          final faceCenterX = largestFace.boundingBox.center.dx;
          final faceCenterY = largestFace.boundingBox.center.dy;
          double minDist = double.infinity;
          for (final pose in allPoses) {
            final nose = pose.landmarks[PoseLandmarkType.nose];
            if (nose != null) {
              final dx = nose.x - faceCenterX;
              final dy = nose.y - faceCenterY;
              final dist = dx * dx + dy * dy;
              if (dist < minDist) {
                minDist = dist;
                closestPose = pose;
              }
            }
          }
        }
        
        // Run activity classification (face angles + pose corporal)
        final faceResult = _faceAnalyzer.analyzeSingle(largestFace);
        final poseResult = _poseAnalyzer.analyzeSingle(closestPose, imgSize.width);

        final aiResult = _classifier.classify(
          pose: poseResult,
          face: faceResult,
        );

        final smoothedState = _activityWindowBuffer.addAndGetMajority(aiResult.state, now);
        
        final previousActivityState = state.currentState;
        
        state = state.copyWith(
          currentState: smoothedState,
          confidence: aiResult.confidence,
          isProcessing: false,
          poses: closestPose != null ? [closestPose] : const [],
          faces: [largestFace],
          imageSize: imgSize,
        );
        
        // Save events during active session
        final stateChanged = smoothedState != previousActivityState;
        final saveIntervalElapsed = now.difference(_lastSaveTime) >= _saveInterval;
        if (stateChanged || saveIntervalElapsed) {
          _saveEvent(
              AiResult(state: smoothedState, confidence: aiResult.confidence), 
              now,
              identityConfidence: state.identityConfidence,
              identificationMethod: state.identificationMethod ?? 'TRACKING');
          _lastSaveTime = now;
        }
        
        return;
      }

      // Buscar al empleado en el frame con embeddings reales
      var findResult = await _finder!.findInFrame(
        detectedFaces: allFaces,
        detectedPoses: allPoses,
        faceEmbeddings: embeddingsMap,
      );
      if (findResult.status == FindStatus.found &&
          !_isWithinAssignedRegion(
            findResult.employeeFace,
            findResult.employeePose,
            imgSize,
          )) {
        findResult = FindResult.outsideArea();
      }
      if (_disposed) return;

      switch (findResult.status) {
        case FindStatus.absent:
        case FindStatus.outsideArea:
          _handleAbsent(findResult, imgSize);
          break;
        case FindStatus.found:
          _consecutiveAbsentFrames = 0;
          _handleFound(findResult, allFaces, allPoses, imgSize, now);
          break;
      }
    } catch (e) {
      debugPrint('[MONITOR] Error frame analysis: $e');
      state = state.copyWith(isProcessing: false);
    }
  }

  void _handleAbsent(FindResult findResult, Size imgSize) {
    _consecutiveAbsentFrames++;
    _stableEntryFrames = 0;

    final now = DateTime.now();

    if (state.sessionStatus == SessionStatus.active) {
      _consecutiveFaceMissFrames++;
      if (_consecutiveFaceMissFrames >= AiThresholds.monitorGracePeriodFrames) {
        _requiresFreshIdentityCheck = true;
        _activityWindowBuffer.reset();
      }

      // ── 5-second absence timeout ─────────────────────────────────────────
      _absenceStart ??= now; // mark start of absence
      final absentFor = now.difference(_absenceStart!);
      if (absentFor >= _absenceTimeout) {
        // Employee gone too long — end session, require face detection again.
        _absenceStart = null;
        _consecutiveAbsentFrames = 0;
        _consecutiveFaceMissFrames = 0;
        _stableEntryFrames = 0;
        _requiresFreshIdentityCheck = true;
        _activityWindowBuffer.reset();
        _finder?.reset();
        debugPrint('[MONITOR] Employee absent for ${absentFor.inSeconds}s — session cancelled.');
        state = state.copyWith(
          sessionStatus: SessionStatus.idle,
          currentState: ActivityState.ausente,
          identityConfidence: 0.0,
          isProcessing: false,
          poses: const [],
          faces: const [],
          imageSize: imgSize,
        );
        return;
      }
    } else {
      _absenceStart = null; // no timeout outside active session
      _activityWindowBuffer.reset();
    }

    // Only cancel entryPending/exitPending after several consecutive absent frames.
    SessionStatus nextStatus = state.sessionStatus;
    if ((state.sessionStatus == SessionStatus.entryPending ||
        state.sessionStatus == SessionStatus.exitPending) &&
        _consecutiveAbsentFrames >= _absentFramesToCancel) {
      nextStatus = SessionStatus.idle;
      debugPrint('[MONITOR] Cancelled pending after $_consecutiveAbsentFrames absent frames.');
    }

    // Progressive confidence degradation during grace period.
    final degradedConfidence = state.sessionStatus == SessionStatus.active &&
            _consecutiveAbsentFrames < AiThresholds.monitorMaxConsecutiveMisses
        ? (state.identityConfidence * 0.85).clamp(0.0, 1.0)
        : 0.0;

    state = state.copyWith(
      currentState: findResult.status == FindStatus.absent
          ? ActivityState.ausente
          : ActivityState.fueraDelArea,
      identityConfidence: degradedConfidence,
      isProcessing: false,
      poses: const [],
      faces: const [],
      imageSize: imgSize,
      sessionStatus: nextStatus,
    );
  }

  void _handleFound(FindResult findResult, List<Face> allFaces, List<Pose> allPoses, Size imgSize, DateTime now) {
    _requiresFreshIdentityCheck = false;
    _consecutiveFaceMissFrames = 0;
    _absenceStart = null; // employee is back — reset absence timer
    final employeeFace = findResult.employeeFace!;
    final employeePose = findResult.employeePose;

    final faceResult = _faceAnalyzer.analyzeSingle(employeeFace);
    final poseResult = _poseAnalyzer.analyzeSingle(employeePose, imgSize.width);

    final aiResult = _classifier.classify(
      pose: poseResult,
      face: faceResult,
    );

    final smoothedState = _activityWindowBuffer.addAndGetMajority(aiResult.state, now);

    final methodLabel = findResult.identifiedBy?.name.toUpperCase() ?? 'FACE';
    final previousActivityState = state.currentState;
    
    final requiresEntryStability =
        state.sessionStatus == SessionStatus.idle ||
        state.sessionStatus == SessionStatus.entryPending;
    final hasStableEntryPresence =
        _passesEntryPresenceGate(employeeFace, imgSize);

    // Actualizar confianza y overlays
    state = state.copyWith(
      currentState: smoothedState,
      confidence: aiResult.confidence,
      identityConfidence: findResult.confidence,
      identificationMethod: methodLabel,
      isProcessing: false,
      poses: employeePose != null ? [employeePose] : const [],
      faces: [employeeFace],
      imageSize: imgSize,
    );

    if (requiresEntryStability) {
      if (findResult.confidence >= AiThresholds.minEmbeddingMatchScore &&
          hasStableEntryPresence) {
        _stableEntryFrames++;
      } else {
        _stableEntryFrames = 0;
      }
    } else {
      _stableEntryFrames = 0;
    }

    // ── Lógica de Sesión ──────────────────────────────────────────────
    
    // CASO 1: Estamos IDLE y detectamos al dueño con confianza ALTA
    if (state.sessionStatus == SessionStatus.idle && 
        findResult.confidence >= AiThresholds.minEmbeddingMatchScore &&
        _stableEntryFrames >= AiThresholds.liveDetectionStableFrames) {
      state = state.copyWith(sessionStatus: SessionStatus.entryPending);
    }

    // CASO 2: Sesión ACTIVA — guardar logs normales
    if (state.sessionStatus == SessionStatus.active) {
      final stateChanged = smoothedState != previousActivityState;
      final saveIntervalElapsed = now.difference(_lastSaveTime) >= _saveInterval;
      
      if (stateChanged || saveIntervalElapsed) {
        _saveEvent(
            AiResult(state: smoothedState, confidence: aiResult.confidence), 
            now,
            identityConfidence: findResult.confidence,
            identificationMethod: methodLabel);
        _lastSaveTime = now;
      }
    }
  }

  // ── Handlers de Acción del Usuario ───────────────────────────────────────

  Future<void> approveEntry() async {
    if (state.sessionStatus != SessionStatus.entryPending) return;

    final now = DateTime.now();
    _stableEntryFrames = 0;
    _absenceStart = null; // fresh start — employee just confirmed entry
    state = state.copyWith(
      sessionStatus: SessionStatus.active,
      sessionStartTime: now,
      currentState: ActivityState.trabajando,
    );
    _requiresFreshIdentityCheck = false;

    await _saveEvent(
      const AiResult(state: ActivityState.trabajando, confidence: 1.0),
      now,
      identityConfidence: state.identityConfidence,
      identificationMethod: 'FACE_EMBEDDING',
    );
    
    debugPrint('[SESSION] Entrada aprobada para ${state.assignedEmployeeId}');
  }

  Future<void> requestExit() async {
    if (state.sessionStatus != SessionStatus.active) return;
    state = state.copyWith(sessionStatus: SessionStatus.exitPending);
  }

  Future<void> approveExit() async {
    if (state.sessionStatus != SessionStatus.exitPending) return;

    final now = DateTime.now();
    _stableEntryFrames = 0;
    _absenceStart = null;
    
    // 1. Guardar evento de salida (AUSENTE para indicar fin de jornada)
    await _saveEvent(
      const AiResult(state: ActivityState.ausente, confidence: 1.0),
      now,
      identityConfidence: state.identityConfidence,
      identificationMethod: 'FACE_EMBEDDING',
    );

    // 2. Limpiar estado
    state = state.copyWith(
      sessionStatus: SessionStatus.idle,
      sessionStartTime: null,
      currentState: ActivityState.ausente,
    );

    // resetear finder para evitar locks de tracking viejos
    _finder?.reset();
    _requiresFreshIdentityCheck = true;
    
    debugPrint('[SESSION] Salida aprobada. Sesión cerrada.');
  }

  void cancelApproval() {
    if (state.sessionStatus == SessionStatus.entryPending) {
       _stableEntryFrames = 0;
       state = state.copyWith(sessionStatus: SessionStatus.idle);
    } else if (state.sessionStatus == SessionStatus.exitPending) {
       state = state.copyWith(sessionStatus: SessionStatus.active);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

  bool _passesEntryPresenceGate(Face face, Size imgSize) {
    final frameArea = imgSize.width * imgSize.height;
    if (frameArea <= 0) return false;

    final box = face.boundingBox;
    final areaRatio = (box.width * box.height) / frameArea;
    final centerX = box.left + (box.width / 2);
    final centerY = box.top + (box.height / 2);

    final minX = imgSize.width * AiThresholds.liveFaceGuideMargin;
    final maxX = imgSize.width * (1 - AiThresholds.liveFaceGuideMargin);
    final minY = imgSize.height * AiThresholds.liveFaceGuideMargin;
    final maxY = imgSize.height * (1 - AiThresholds.liveFaceGuideMargin);

    final centered = centerX >= minX &&
        centerX <= maxX &&
        centerY >= minY &&
        centerY <= maxY;
    final fullyVisible = box.left >= 0 &&
        box.top >= 0 &&
        box.right <= imgSize.width &&
        box.bottom <= imgSize.height;

    final yaw = (face.headEulerAngleY ?? 0.0).abs();
    final pitch = (face.headEulerAngleX ?? 0.0).abs();
    final frontal = yaw <= AiThresholds.normalYawRange &&
        pitch <= (AiThresholds.normalPitchRange + 2);

    return areaRatio >= AiThresholds.minLiveFaceAreaRatio &&
        centered &&
        fullyVisible &&
        frontal;
  }

  bool _isWithinAssignedRegion(Face? face, Pose? pose, Size imgSize) {
    final roi = state.workstationRoi;
    if (roi == null) return true;

    bool pointInside(double x, double y) {
      final minX = imgSize.width * roi.x;
      final minY = imgSize.height * roi.y;
      final maxX = minX + (imgSize.width * roi.width);
      final maxY = minY + (imgSize.height * roi.height);
      return x >= minX && x <= maxX && y >= minY && y <= maxY;
    }

    if (face != null) {
      final center = face.boundingBox.center;
      if (!pointInside(center.dx, center.dy)) {
        return false;
      }
    }

    if (pose != null) {
      final nose = pose.landmarks[PoseLandmarkType.nose];
      if (nose != null && !pointInside(nose.x, nose.y)) {
        return false;
      }
    }

    return true;
  }

  InputImage? _buildInputImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation rotation;

    if (Platform.isAndroid) {
      final deviceOrientation = _cameraController!.value.deviceOrientation;
      int rotationCompensation = _orientationMap[deviceOrientation] ?? 0;
      rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ?? InputImageRotation.rotation0deg;
    } else {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
    }

    final rawFormat = image.format.raw;
    if (rawFormat is! int || image.planes.isEmpty) return null;
    final format = InputImageFormatValue.fromRawValue(rawFormat);
    if (format == null) return null;

    final plane = image.planes.first;
    return InputImage.fromBytes(
      bytes: plane.bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: plane.bytesPerRow,
      ),
    );
  }

  Future<void> _saveEvent(
      AiResult aiResult,
      DateTime timestamp, {
        double identityConfidence = 0.0,
        String? identificationMethod,
      }) async {
    if (state.workstationId.isEmpty) return;

    final event = ActivityEvent(
      id: const Uuid().v4(),
      employeeId: state.assignedEmployeeId,
      workstationId: state.workstationId,
      companyId: state.companyId,
      state: aiResult.state,
      confidence: aiResult.confidence,
      timestamp: timestamp,
      synced: false,
      identityConfidence: identityConfidence,
      identificationMethod: identificationMethod,
    );

    try {
      await _saveEventUseCase(event);
      if (!_disposed) state = state.copyWith(lastEventTime: timestamp);
    } catch (e) {
      debugPrint('[MONITOR] Error guardando evento: $e');
    }
  }

  Future<void> stopCamera() async {
    _isAnalyzing = false;
    final controller = _cameraController;
    _cameraController = null;

    // ── Update state FIRST so Flutter removes CameraPreview from the tree ──
    // CameraController.dispose() calls notifyListeners() internally, which
    // triggers the ValueListenableBuilder inside CameraPreview to rebuild and
    // call buildPreview() on a now-disposed controller → CameraException.
    // Setting cameraInitialized=false first marks the widget dirty; the actual
    // controller disposal is deferred to a post-frame callback so Flutter has
    // already rebuilt (and unmounted CameraPreview) before dispose() fires.
    if (!_disposed) {
      try { state = state.copyWith(cameraInitialized: false); } catch (_) {}
    }

    if (controller == null) return;

    // Defer disposal to after the next rendered frame.
    final completer = Completer<void>();
    SchedulerBinding.instance.addPostFrameCallback((_) async {
      try {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream();
        }
        await controller.dispose();
      } catch (_) {}
      completer.complete();
    });
    await completer.future;
  }

  @override
  void dispose() {
    _disposed = true;
    stopCamera();
    Future.microtask(() async {
      try {
        await _poseDetector.close();
        await _faceDetector.close();
      } catch (_) {}
    });
    _poseAnalyzer.reset();
    _classifier.reset();
    _remoteSub?.cancel();
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final kioskProvider =
    StateNotifierProvider.autoDispose<KioskNotifier, KioskState>((ref) {
  final saveUseCase = ref.watch(saveActivityEventUseCaseProvider);
  final db = ref.watch(appDatabaseProvider);
  final embeddingService = ref.watch(faceEmbeddingServiceProvider);
  return KioskNotifier(saveUseCase, db, embeddingService);
});

final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) {
  return availableCameras();
});
