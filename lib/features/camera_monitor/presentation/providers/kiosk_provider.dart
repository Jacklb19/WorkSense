import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:uuid/uuid.dart';
import 'package:worksense_app/core/constants/aithresholds.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/data/repositories/activity_repository_impl.dart';
import 'package:worksense_app/domain/entities/activity_event.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';
import 'package:worksense_app/features/camera_monitor/domain/usecases/save_activity_event_use_case.dart';
import 'package:worksense_app/features/camera_monitor/ai/activity_classifier.dart';
import 'package:worksense_app/features/camera_monitor/ai/ai_result.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/ai/pose_analyzer.dart';

// â”€â”€ Database Provider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final appDatabaseProvider = Provider<AppDatabase>((ref) {
  final db = AppDatabase();
  ref.onDispose(db.close);
  return db;
});

// â”€â”€ Save Use Case Provider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final saveActivityEventUseCaseProvider =
    Provider<SaveActivityEventUseCase>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final repo = ActivityRepositoryImpl(db);
  return SaveActivityEventUseCase(repo);
});

// â”€â”€ Kiosk State â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class KioskState {
  final ActivityState currentState;
  final double confidence;
  final bool isProcessing;
  final int frameCount;
  final DateTime? lastEventTime;
  final bool cameraInitialized;
  final String? error;
  final String workstationId;

  const KioskState({
    this.currentState = ActivityState.ausente,
    this.confidence = 0.0,
    this.isProcessing = false,
    this.frameCount = 0,
    this.lastEventTime,
    this.cameraInitialized = false,
    this.error,
    this.workstationId = 'default',
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
    );
  }
}

// â”€â”€ Kiosk Notifier â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

class KioskNotifier extends StateNotifier<KioskState> {
  final SaveActivityEventUseCase _saveEventUseCase;

  CameraController? _cameraController;
  late final PoseDetector _poseDetector;
  late final FaceDetector _faceDetector;
  late final PoseAnalyzer _poseAnalyzer;
  late final FaceAnalyzer _faceAnalyzer;
  late final ActivityClassifier _classifier;

  bool _isAnalyzing = false;
  DateTime _lastAnalysisTime = DateTime.fromMillisecondsSinceEpoch(0);
  DateTime _lastMovementTime = DateTime.now();
  DateTime _lastSaveTime = DateTime.fromMillisecondsSinceEpoch(0);

  // Analizar cada 800ms â€” rÃ¡pido para que la UI se actualice en tiempo real
  static const Duration _analysisInterval = Duration(milliseconds: 800);

  // Guardar evento a BD/Supabase cada 30 segundos (o si cambia el estado)
  static const Duration _saveInterval = Duration(
    seconds: AiThresholds.defaultAnalysisIntervalSeconds,
  );

  // Mapeo de orientaciÃ³n de dispositivo a compensaciÃ³n en grados
  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  KioskNotifier(this._saveEventUseCase) : super(const KioskState()) {
    _poseDetector = PoseDetector(
      options: PoseDetectorOptions(
        mode: PoseDetectionMode.stream,
      ),
    );
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableTracking: true,
      ),
    );
    _poseAnalyzer = PoseAnalyzer();
    _faceAnalyzer = FaceAnalyzer();
    _classifier = ActivityClassifier();
  }

  CameraController? get cameraController => _cameraController;

  Future<void> initializeCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) {
      state = state.copyWith(error: 'No se encontraron cÃ¡maras.');
      return;
    }

    // Prefer front camera for monitoring
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
    // Skip if currently analyzing or interval not elapsed
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
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) {
        state = state.copyWith(isProcessing: false);
        return;
      }

      // Run pose and face detection concurrently
      final results = await Future.wait([
        _poseDetector.processImage(inputImage),
        _faceDetector.processImage(inputImage),
      ]);

      final poses = results[0] as List<Pose>;
      final faces = results[1] as List<Face>;

      final poseResult = _poseAnalyzer.analyze(poses);
      final faceResult = _faceAnalyzer.analyze(faces);

      // Determine inactivity
      if (poseResult.handsMoving) {
        _lastMovementTime = now;
      }
      final inactivityDuration = now.difference(_lastMovementTime);
      final isInactive = inactivityDuration.inSeconds >=
          AiThresholds.inactivityThresholdSeconds;

      final aiResult = _classifier.classify(
        pose: poseResult,
        face: faceResult,
        isInactive: isInactive,
      );

      state = state.copyWith(
        currentState: aiResult.state,
        confidence: aiResult.confidence,
        isProcessing: false,
      );

      // Guardar evento si: cambiÃ³ el estado O pasaron 30 segundos
      final stateChanged = aiResult.state != state.currentState;
      final saveIntervalElapsed =
          now.difference(_lastSaveTime) >= _saveInterval;

      if (stateChanged || saveIntervalElapsed) {
        await _saveEvent(aiResult, now);
        _lastSaveTime = now;
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
      // CÃ¡lculo correcto de rotaciÃ³n para Android segÃºn docs de ML Kit
      final deviceOrientation = _cameraController!.value.deviceOrientation;
      int rotationCompensation =
          _orientationMap[deviceOrientation] ?? 0;

      if (camera.lensDirection == CameraLensDirection.front) {
        // CÃ¡mara frontal: suma y aplica mÃ³dulo
        rotationCompensation =
            (sensorOrientation + rotationCompensation) % 360;
      } else {
        // CÃ¡mara trasera: resta
        rotationCompensation =
            (sensorOrientation - rotationCompensation + 360) % 360;
      }

      rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ??
          InputImageRotation.rotation0deg;
    } else {
      // iOS: usar directamente el sensorOrientation
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

  Future<void> _saveEvent(AiResult aiResult, DateTime timestamp) async {
    final event = ActivityEvent(
      id: const Uuid().v4(),
      workstationId: state.workstationId,
      state: aiResult.state,
      confidence: aiResult.confidence,
      timestamp: timestamp,
      synced: false,
    );

    try {
      await _saveEventUseCase(event);
      state = state.copyWith(lastEventTime: timestamp);
    } catch (_) {
      // Silent failure â€” event will be retried on next sync
    }
  }

  void setWorkstationId(String id) {
    state = state.copyWith(workstationId: id);
  }

  void setError(String message) {
    state = state.copyWith(error: message, cameraInitialized: false);
  }

  @override
  void dispose() {
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();
    _poseDetector.close();
    _faceDetector.close();
    _poseAnalyzer.reset();
    _classifier.reset();
    super.dispose();
  }
}

// â”€â”€ Provider â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€â”€

final kioskProvider =
    StateNotifierProvider<KioskNotifier, KioskState>((ref) {
  final saveUseCase = ref.watch(saveActivityEventUseCaseProvider);
  return KioskNotifier(saveUseCase);
});

final availableCamerasProvider = FutureProvider<List<CameraDescription>>((ref) {
  return availableCameras();
});

