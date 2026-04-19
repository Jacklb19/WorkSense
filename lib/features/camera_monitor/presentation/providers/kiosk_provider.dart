import 'dart:async';
import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter/foundation.dart';
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

// ── Database Provider ──────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ── Save Use Case Provider ─────────────────────────────────────────────────────

final saveActivityEventUseCaseProvider =
    Provider<SaveActivityEventUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  final repo = ActivityRepositoryImpl(db, syncRepo);
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

  // Re-identificación y Sesión
  final SessionStatus sessionStatus;
  final bool isEmployeeScanned;
  final EmployeeProfile? employeeProfile;
  final String? identificationMethod;
  final double identityConfidence;
  final String? assignedEmployeeId;
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
  });

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
    SessionStatus? sessionStatus,
    bool? isEmployeeScanned,
    EmployeeProfile? employeeProfile,
    String? identificationMethod,
    double? identityConfidence,
    String? assignedEmployeeId,
    DateTime? sessionStartTime,
    String? workstationStatus,
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
      identificationMethod: identificationMethod ?? this.identificationMethod,
      identityConfidence: identityConfidence ?? this.identityConfidence,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
      sessionStartTime: sessionStartTime ?? this.sessionStartTime,
      workstationStatus: workstationStatus ?? this.workstationStatus,
    );
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

  EmployeeFinder? _finder;

  bool _isAnalyzing = false;
  bool _disposed = false;
  DateTime _lastAnalysisTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastMovementTime = DateTime.now();
  DateTime _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastReidTime = DateTime.fromMillisecondsSinceEpoch(0);
  int _adaptationsCount = 0;
  int _consecutiveAbsentFrames = 0;
  
  /// Number of consecutive absent frames required to cancel entryPending/exitPending.
  static const int _absentFramesToCancel = 8;
  
  StreamSubscription? _remoteSub;

  static const Duration _analysisInterval = Duration(milliseconds: 600);
  static const Duration _saveInterval = Duration(
    seconds: AiThresholds.defaultAnalysisIntervalSeconds,
  );
  static const Duration _reidInterval = Duration(
    seconds: AiThresholds.reidIntervalSeconds,
  );

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

    if (record != null &&
        record.faceEmbedding != null &&
        record.bodySignature != null &&
        assignedId != null) {
      // Reconstruir el perfil desde la BD usando el serializer centralizado
      final embeddingRaw = BiometricSerializer.deserializeEmbedding(record.faceEmbedding);
      
      final bodyJson =
          (jsonDecode(record.bodySignature!) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble()));

      if (embeddingRaw != null) {
        final profile = EmployeeProfile(
          employeeId: assignedId,
          workstationId: workstationId,
          faceEmbedding: embeddingRaw,
          bodySignature: BodySignature.fromJson(bodyJson),
          capturedAt: record.profileCapturedAt ?? DateTime.now(),
          sampleCount: 5,
          version: record.profileVersion,
        );

        _finder = EmployeeFinder(profile);
        debugPrint('[MONITOR] Perfil cargado para ${profile.employeeId}.');
        state = state.copyWith(
          isEmployeeScanned: true,
          employeeProfile: profile,
          assignedEmployeeId: assignedId,
          currentState: ActivityState.ausente,
          sessionStatus: SessionStatus.idle,
        );

        _listenRemoteStatus(workstationId);

        // Ya no iniciamos cámara de inmediato, lo maneja el Listener de Realtime
        // Si quieres forzar inicio manual para test: if(state.workstationStatus == 'ACTIVE') await initializeCamera(cameras);
        return true;
      }
    }

    // Sin perfil biométrico
    state = state.copyWith(
      isEmployeeScanned: false,
      assignedEmployeeId: assignedId,
      currentState: ActivityState.noIdentificado,
    );
    
    _listenRemoteStatus(workstationId);
    return false;
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

      if (status == 'ACTIVE' && !isRunning) {
        debugPrint('[REALTIME] Activating camera for $workstationId');
        final cameras = await availableCameras();
        await initializeCamera(cameras);
      } else if (status == 'IDLE' && isRunning) {
        debugPrint('[REALTIME] Deactivating camera for $workstationId');
        await stopCamera();
      } else if (status == 'BREAK' && isRunning) {
        debugPrint('[REALTIME] Pausing camera for break');
        await stopCamera();
      }
      
      if (!_disposed) state = state.copyWith(workstationStatus: status);
    }, onError: (e) {
      debugPrint('[REALTIME Error] $e');
    });
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
      // Strategy:
      //  - When IDLE or ENTRY_PENDING: generate embeddings EVERY frame (need to find/confirm employee)
      //  - When ACTIVE: only generate embeddings on reid intervals (save CPU, already confirmed)
      final Map<int, List<double>> embeddingsMap = {};
      final bool needsIdentification = state.sessionStatus == SessionStatus.idle || 
                                       state.sessionStatus == SessionStatus.entryPending;
      final shouldReid = now.difference(_lastReidTime) >= _reidInterval;
      final bool shouldGenerateEmbeddings = needsIdentification || shouldReid;
      
      if (allFaces.isNotEmpty && (_finder!.profile.employeeId != null) && shouldGenerateEmbeddings) {
        for (final face in allFaces) {
          final cropped = await _faceAnalyzer.cropFaceFromCameraImageAsync(image, face);
          if (cropped != null) {
            final emb = await _embeddingService.generateEmbedding(cropped);
            embeddingsMap[face.trackingId ?? allFaces.indexOf(face)] = emb;
            _lastReidTime = now;
          }
        }
      }

      // When no embeddings were generated (reid cooldown during active session)
      // and faces ARE visible, skip identity check but STILL run activity classification.
      if (embeddingsMap.isEmpty && allFaces.isNotEmpty && state.sessionStatus == SessionStatus.active) {
        _consecutiveAbsentFrames = 0; // reset, person is clearly visible
        
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
        
        // Run activity classification (face angles, pose, hands movement)
        final faceResult = _faceAnalyzer.analyzeSingle(largestFace);
        final poseResult = _poseAnalyzer.analyzeSingle(closestPose);
        
        if (poseResult.handsMoving) _lastMovementTime = now;
        final isInactive = now.difference(_lastMovementTime).inSeconds >=
            AiThresholds.inactivityThresholdSeconds;
        
        final aiResult = _classifier.classify(
          pose: poseResult,
          face: faceResult,
          isInactive: isInactive,
        );
        
        final previousActivityState = state.currentState;
        
        state = state.copyWith(
          currentState: aiResult.state,
          confidence: aiResult.confidence,
          isProcessing: false,
          poses: closestPose != null ? [closestPose] : const [],
          faces: [largestFace],
          imageSize: imgSize,
        );
        
        // Save events during active session
        final stateChanged = aiResult.state != previousActivityState;
        final saveIntervalElapsed = now.difference(_lastSaveTime) >= _saveInterval;
        if (stateChanged || saveIntervalElapsed) {
          _saveEvent(aiResult, now,
              identityConfidence: state.identityConfidence,
              identificationMethod: state.identificationMethod ?? 'TRACKING');
          _lastSaveTime = now;
        }
        
        return;
      }

      // Buscar al empleado en el frame con embeddings reales
      final findResult = await _finder!.findInFrame(
        detectedFaces: allFaces,
        detectedPoses: allPoses,
        faceEmbeddings: embeddingsMap,
      );
      if (_disposed) return;

      switch (findResult.status) {
        case FindStatus.absent:
        case FindStatus.outsideArea:
          _handleAbsent(findResult, imgSize);
          
        case FindStatus.found:
          _consecutiveAbsentFrames = 0;
          _handleFound(findResult, allFaces, allPoses, imgSize, now);
      }
    } catch (e) {
      debugPrint('[MONITOR] Error frame analysis: $e');
      state = state.copyWith(isProcessing: false);
    }
  }

  void _handleAbsent(FindResult findResult, Size imgSize) {
    _consecutiveAbsentFrames++;
    
    // Only cancel entryPending/exitPending after several consecutive absent frames.
    // This prevents a single bad frame from destroying the welcome overlay.
    SessionStatus nextStatus = state.sessionStatus;
    if ((state.sessionStatus == SessionStatus.entryPending ||
        state.sessionStatus == SessionStatus.exitPending) &&
        _consecutiveAbsentFrames >= _absentFramesToCancel) {
      nextStatus = SessionStatus.idle;
      debugPrint('[MONITOR] Cancelled pending after $_consecutiveAbsentFrames absent frames.');
    }

    state = state.copyWith(
      currentState: findResult.status == FindStatus.absent
          ? ActivityState.ausente
          : ActivityState.fueraDelArea,
      identityConfidence: 0.0,
      isProcessing: false,
      poses: const [],
      faces: const [],
      imageSize: imgSize,
      sessionStatus: nextStatus,
    );
  }

  void _handleFound(FindResult findResult, List<Face> allFaces, List<Pose> allPoses, Size imgSize, DateTime now) {
    final employeeFace = findResult.employeeFace!;
    final employeePose = findResult.employeePose;

    final faceResult = _faceAnalyzer.analyzeSingle(employeeFace);
    final poseResult = _poseAnalyzer.analyzeSingle(employeePose);

    if (poseResult.handsMoving) _lastMovementTime = now;
    final isInactive = now.difference(_lastMovementTime).inSeconds >=
        AiThresholds.inactivityThresholdSeconds;

    final aiResult = _classifier.classify(
      pose: poseResult,
      face: faceResult,
      isInactive: isInactive,
    );

    final methodLabel = findResult.identifiedBy?.name.toUpperCase() ?? 'FACE';
    final previousActivityState = state.currentState;

    // Actualizar confianza y overlays
    state = state.copyWith(
      currentState: aiResult.state,
      confidence: aiResult.confidence,
      identityConfidence: findResult.confidence,
      identificationMethod: methodLabel,
      isProcessing: false,
      poses: employeePose != null ? [employeePose] : const [],
      faces: [employeeFace],
      imageSize: imgSize,
    );

    // ── Lógica de Sesión ──────────────────────────────────────────────
    
    // CASO 1: Estamos IDLE y detectamos al dueño con confianza ALTA
    if (state.sessionStatus == SessionStatus.idle && 
        findResult.confidence >= AiThresholds.minEmbeddingMatchScore) {
      state = state.copyWith(sessionStatus: SessionStatus.entryPending);
    }

    // CASO 2: Sesión ACTIVA — guardar logs normales
    if (state.sessionStatus == SessionStatus.active) {
      final stateChanged = aiResult.state != previousActivityState;
      final saveIntervalElapsed = now.difference(_lastSaveTime) >= _saveInterval;
      
      if (stateChanged || saveIntervalElapsed) {
        _saveEvent(aiResult, now,
            identityConfidence: findResult.confidence,
            identificationMethod: methodLabel);
        _lastSaveTime = now;
      }

      // Aprendizaje incremental conservador (solo si confianza es muy alta)
      if (findResult.confidence >= 0.92) {
         // (Lógica de adaptación de perfil si fuera necesaria)
      }
    }
  }

  // ── Handlers de Acción del Usuario ───────────────────────────────────────

  Future<void> approveEntry() async {
    if (state.sessionStatus != SessionStatus.entryPending) return;
    
    final now = DateTime.now();
    state = state.copyWith(
      sessionStatus: SessionStatus.active,
      sessionStartTime: now,
      currentState: ActivityState.trabajando,
    );

    await _saveEvent(
      AiResult(state: ActivityState.trabajando, confidence: 1.0),
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
    
    // 1. Guardar evento de salida (AUSENTE para indicar fin de jornada)
    await _saveEvent(
      AiResult(state: ActivityState.ausente, confidence: 1.0),
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
    
    debugPrint('[SESSION] Salida aprobada. Sesión cerrada.');
  }

  void cancelApproval() {
    if (state.sessionStatus == SessionStatus.entryPending) {
       state = state.copyWith(sessionStatus: SessionStatus.idle);
    } else if (state.sessionStatus == SessionStatus.exitPending) {
       state = state.copyWith(sessionStatus: SessionStatus.active);
    }
  }

  // ── Helpers ──────────────────────────────────────────────────────────────

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
    _disposed = true;
    _isAnalyzing = false;
    final controller = _cameraController;
    _cameraController = null;
    try {
      if (controller != null && controller.value.isInitialized) {
        if (controller.value.isStreamingImages) {
          await controller.stopImageStream().catchError((_) {});
        }
        await controller.dispose().catchError((_) {});
      }
    } catch (_) {}
    if (!_disposed) state = state.copyWith(cameraInitialized: false);
  }

  @override
  void dispose() {
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

