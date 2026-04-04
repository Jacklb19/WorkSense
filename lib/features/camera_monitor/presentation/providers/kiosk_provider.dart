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
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/data/repositories/activity_repository_impl.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/ai/activity_classifier.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';
import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_finder.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profile.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/ai/pose_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/domain/usecases/save_activity_event_use_case.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

// ── Database Provider ──────────────────────────────────────────────────────────

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// ... (other imports)

// â”€â”€ Save Use Case Provider ─────────────────────────────────────────────────────

final saveActivityEventUseCaseProvider =
    Provider<SaveActivityEventUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  final repo = ActivityRepositoryImpl(db, syncRepo);
  return SaveActivityEventUseCase(repo);
});

// ── Kiosk State ────────────────────────────────────────────────────────────────

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

  // Re-identificación
  final bool isEmployeeScanned;
  final EmployeeProfile? employeeProfile;
  final String? identificationMethod;
  final double identityConfidence;
  final String? assignedEmployeeId;

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
    this.isEmployeeScanned = false,
    this.employeeProfile,
    this.identificationMethod,
    this.identityConfidence = 0.0,
    this.assignedEmployeeId,
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
    bool? isEmployeeScanned,
    EmployeeProfile? employeeProfile,
    String? identificationMethod,
    double? identityConfidence,
    String? assignedEmployeeId,
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
      isEmployeeScanned: isEmployeeScanned ?? this.isEmployeeScanned,
      employeeProfile: employeeProfile ?? this.employeeProfile,
      identificationMethod: identificationMethod ?? this.identificationMethod,
      identityConfidence: identityConfidence ?? this.identityConfidence,
      assignedEmployeeId: assignedEmployeeId ?? this.assignedEmployeeId,
    );
  }
}

// ── Kiosk Notifier ─────────────────────────────────────────────────────────────

class KioskNotifier extends StateNotifier<KioskState> {
  final SaveActivityEventUseCase _saveEventUseCase;
  final AppDatabase _db;

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
  int _adaptationsCount = 0;

  static const int _adaptationsToPersist = 30;
  static const double _learningConfidenceThreshold = 0.85;

  static const Duration _analysisInterval = Duration(milliseconds: 800);
  static const Duration _saveInterval = Duration(
    seconds: AiThresholds.defaultAnalysisIntervalSeconds,
  );

  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  KioskNotifier(this._saveEventUseCase, this._db) : super(const KioskState()) {
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
  }

  CameraController? get cameraController => _cameraController;

  /// Carga el perfil del empleado desde Drift y arranca la cámara si existe.
  /// Retorna true si hay perfil registrado, false si hay que escanear.
  Future<bool> loadProfileAndInit(
      List<CameraDescription> cameras, String workstationId) async {
    state = state.copyWith(workstationId: workstationId);

    final record = await _db.getWorkstationById(workstationId);

    // Guardar siempre el employeeId asignado (aunque no haya perfil biométrico)
    final assignedId = record?.assignedEmployeeId;

    if (record != null &&
        record.faceEmbedding != null &&
        record.bodySignature != null &&
        assignedId != null) {
      // Reconstruir el perfil desde la BD
      final embeddingRaw = (jsonDecode(record.faceEmbedding!) as List<dynamic>)
          .map((e) => (e as num).toDouble())
          .toList();
      final bodyJson =
          (jsonDecode(record.bodySignature!) as Map<String, dynamic>)
              .map((k, v) => MapEntry(k, (v as num).toDouble()));

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
      debugPrint(
          '[MONITOR] Perfil cargado para ${profile.employeeId}. Muestras: ${profile.sampleCount}');
      state = state.copyWith(
        isEmployeeScanned: true,
        employeeProfile: profile,
        assignedEmployeeId: assignedId,
        currentState: ActivityState.ausente,
      );

      await initializeCamera(cameras);
      return true;
    }

    // Sin perfil biométrico — hay que escanear
    state = state.copyWith(
      isEmployeeScanned: false,
      assignedEmployeeId: assignedId,
      currentState: ActivityState.noIdentificado,
    );
    return false;
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
        error: 'No se pudo iniciar la cámara. Verifica los permisos.',
        cameraInitialized: false,
      );
    }
  }

  Future<void> _startImageStream() async {
    if (_cameraController == null || !_cameraController!.value.isInitialized) {
      return;
    }
    await _cameraController!.startImageStream(_processFrame);
  }

  void _processFrame(CameraImage image) {
    if (_disposed) return;
    if (_isAnalyzing) return;

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
    }).catchError((_) {
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

      // Detectar todas las caras y poses del frame
      final results = await Future.wait([
        _poseDetector.processImage(inputImage),
        _faceDetector.processImage(inputImage),
      ]);
      if (_disposed) return;

      final allPoses = results[0] as List<Pose>;
      final allFaces = results[1] as List<Face>;

      debugPrint(
          '[MONITOR] Frame analizado. Caras: ${allFaces.length}, Poses: ${allPoses.length}');

      // Si no hay perfil registrado, solo actualizar overlay de detección
      if (_finder == null) {
        state = state.copyWith(
          currentState: ActivityState.noIdentificado,
          confidence: 1.0,
          isProcessing: false,
          poses: allPoses,
          faces: allFaces,
          imageSize: imgSize,
        );
        return;
      }

      // Buscar al empleado en el frame
      final findResult = await _finder!.findInFrame(
        detectedFaces: allFaces,
        detectedPoses: allPoses,
      );
      if (_disposed) return;

      debugPrint(
          '[MONITOR] findInFrame result: ${findResult.status}, confidence: ${findResult.confidence.toStringAsFixed(2)}');

      switch (findResult.status) {
        case FindStatus.absent:
          state = state.copyWith(
            currentState: ActivityState.ausente,
            confidence: 0.9,
            identityConfidence: 0.0,
            identificationMethod: null,
            isProcessing: false,
            poses: const [],
            faces: const [],
            imageSize: imgSize,
          );

        case FindStatus.outsideArea:
          state = state.copyWith(
            currentState: ActivityState.fueraDelArea,
            confidence: 0.85,
            identityConfidence: 0.0,
            identificationMethod: null,
            isProcessing: false,
            poses: const [],
            faces: const [],
            imageSize: imgSize,
          );

        case FindStatus.found:
          final employeeFace = findResult.employeeFace!;
          final employeePose = findResult.employeePose;

          // Analizar SOLO la cara y pose del empleado
          final faceResult = _faceAnalyzer.analyzeSingle(employeeFace);
          final poseResult = _poseAnalyzer.analyzeSingle(employeePose);

          if (poseResult.handsMoving) {
            _lastMovementTime = now;
          }
          final isInactive = now.difference(_lastMovementTime).inSeconds >=
              AiThresholds.inactivityThresholdSeconds;

          final aiResult = _classifier.classify(
            pose: poseResult,
            face: faceResult,
            isInactive: isInactive,
          );

          final methodLabel =
              findResult.identifiedBy?.name.toUpperCase() ?? 'FACE';

          // Capturar estado ANTES del copyWith para detectar cambio real
          final previousActivityState = state.currentState;

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

          // Guardar evento si cambió el estado o pasó el intervalo
          final stateChanged = aiResult.state != previousActivityState;
          final saveIntervalElapsed =
              now.difference(_lastSaveTime) >= _saveInterval;
          if (stateChanged || saveIntervalElapsed) {
            await _saveEvent(aiResult, now,
                identityConfidence: findResult.confidence,
                identificationMethod: methodLabel);
            _lastSaveTime = now;
          }
          if (_disposed) return;

          // ── Aprendizaje incremental ───────────────────────────────────────
          // Solo aprender cuando la confianza es alta (≥ 0.85)
          if (_finder != null &&
              findResult.confidence >= _learningConfidenceThreshold) {
            final liveEmb = EmployeeFinder.extractFaceEmbedding(employeeFace);
            final liveBody = employeePose != null
                ? BodySignature.fromPose(employeePose)
                : null;

            final adapted = _finder!.profile.adaptedWith(
              liveFaceEmbedding: liveEmb,
              liveBodySignature: liveBody,
            );
            _finder = EmployeeFinder(adapted);
            _adaptationsCount++;

            if (_adaptationsCount >= _adaptationsToPersist) {
              _adaptationsCount = 0;
              await _persistProfile(adapted);
            }
          }
      }
    } catch (_) {
      state = state.copyWith(isProcessing: false);
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    if (_cameraController == null) return null;

    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation rotation;

    if (Platform.isAndroid) {
      final deviceOrientation = _cameraController!.value.deviceOrientation;
      int rotationCompensation = _orientationMap[deviceOrientation] ?? 0;

      if (camera.lensDirection == CameraLensDirection.front) {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      } else {
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ??
          InputImageRotation.rotation0deg;
    } else {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;
    }

    final rawFormat = image.format.raw;
    if (rawFormat is! int) return null;
    final format = InputImageFormatValue.fromRawValue(rawFormat);
    if (format == null) return null;

    if (image.planes.isEmpty) return null;

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

  Future<void> _persistProfile(EmployeeProfile profile) async {
    try {
      await _db.saveEmployeeProfile(
        workstationId: state.workstationId,
        employeeId: profile.employeeId,
        faceEmbeddingJson: jsonEncode(profile.faceEmbedding),
        bodySignatureJson: jsonEncode(profile.bodySignature.toJson()),
      );
    } catch (_) {}
  }

  Future<void> _saveEvent(
      AiResult aiResult,
      DateTime timestamp, {
        double identityConfidence = 0.0,
        String? identificationMethod,
      }) async {
    if (state.workstationId.isEmpty) return; // ← aquí, primera línea del cuerpo

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
      state = state.copyWith(lastEventTime: timestamp);
    } catch (_) {
      // Silent failure — event will be retried on next sync
    }
  }

  void setWorkstationId(String id) {
    state = state.copyWith(workstationId: id);
  }

  void setError(String message) {
    state = state.copyWith(error: message, cameraInitialized: false);
  }

  /// Detiene el stream y libera la cámara. Llamar al salir de la pantalla.
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

    state = state.copyWith(cameraInitialized: false);
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
    super.dispose();
  }
}

// ── Provider ───────────────────────────────────────────────────────────────────

final kioskProvider =
    StateNotifierProvider.autoDispose<KioskNotifier, KioskState>((ref) {
  final saveUseCase = ref.watch(saveActivityEventUseCaseProvider);
  final db = ref.watch(appDatabaseProvider);
  return KioskNotifier(saveUseCase, db);
});

final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) {
  return availableCameras();
});
