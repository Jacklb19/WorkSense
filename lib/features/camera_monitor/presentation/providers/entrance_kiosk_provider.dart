import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Size;
import 'package:drift/drift.dart' as drift;
import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/core/utils/biometric_utils.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profile.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_embedding_service.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';

class EntranceKioskState {
  final bool isReady;
  final String? error;
  final bool isProcessing;
  final String statusMessage;
  final String? lastMatchedEmployeeId;

  const EntranceKioskState({
    this.isReady = false,
    this.error,
    this.isProcessing = false,
    this.statusMessage = 'Escaneando...',
    this.lastMatchedEmployeeId,
  });

  EntranceKioskState copyWith({
    bool? isReady,
    String? error,
    bool? isProcessing,
    String? statusMessage,
    String? lastMatchedEmployeeId,
  }) {
    return EntranceKioskState(
      isReady: isReady ?? this.isReady,
      error: error ?? this.error,
      isProcessing: isProcessing ?? this.isProcessing,
      statusMessage: statusMessage ?? this.statusMessage,
      lastMatchedEmployeeId: lastMatchedEmployeeId, // deliberately allow null reset
    );
  }
}

class EntranceKioskNotifier extends StateNotifier<EntranceKioskState> {
  final AppDatabase _db;
  final FaceEmbeddingService _embeddingService;

  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  late final FaceAnalyzer _faceAnalyzer;

  bool _isAnalyzing = false;
  bool _disposed = false;
  DateTime _lastAnalysisTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _analysisInterval = Duration(milliseconds: 1000);
  
  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // Cached registry
  final Map<String, List<double>> _employeeRegistry = {};
  
  // Timer to clear status message
  Timer? _clearMessageTimer;

  EntranceKioskNotifier(this._db, this._embeddingService) : super(const EntranceKioskState()) {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableTracking: false,
        enableLandmarks: true,
      ),
    );
    _faceAnalyzer = FaceAnalyzer();
  }

  CameraController? get cameraController => _cameraController;

  Future<void> initialize(List<CameraDescription> cameras) async {
    state = const EntranceKioskState(statusMessage: 'Cargando base de datos biométrica...');
    
    // 1. Load Embeddings
    await _embeddingService.initialize();
    await _loadRegistry();

    // 2. Start Camera
    if (cameras.isEmpty) {
      state = state.copyWith(error: 'No cameras found.', statusMessage: 'Error');
      return;
    }
    final camera = cameras.firstWhere(
      (c) => c.lensDirection == CameraLensDirection.front,
      orElse: () => cameras.first,
    );

    _cameraController = CameraController(
      camera,
      ResolutionPreset.low, // optimización
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
      if (_disposed) return;
      state = state.copyWith(isReady: true, statusMessage: 'Recepción Activa');
      _startImageStream();
    } catch (e) {
      state = state.copyWith(error: 'Camera initialization failed: $e');
    }
  }

  Future<void> _loadRegistry() async {
    _employeeRegistry.clear();
    int count = 0;

    // 1. Intentar cargar desde la BD local
    count = await _loadFromLocalDb();

    // 2. Si no hay nada local, descargar directo de Supabase (fallback para CAMERA_MONITOR)
    if (count == 0) {
      debugPrint('[ENTRANCE] BD local vacía. Descargando workstations de Supabase...');
      state = state.copyWith(statusMessage: 'Descargando perfiles de la nube...');
      try {
        final client = Supabase.instance.client;
        final response = await client.from('workstations').select();
        final remoteWorkstations = List<Map<String, dynamic>>.from(response);
        
        debugPrint('[ENTRANCE] Recibidos ${remoteWorkstations.length} workstations de Supabase.');
        
        for (var w in remoteWorkstations) {
          // Guardar en BD local para futuras consultas
          await _db.insertWorkstationRecord(WorkstationRecordsCompanion(
            id: drift.Value(w['id']),
            name: drift.Value(w['name'] ?? 'Sin nombre'),
            companyId: drift.Value(w['company_id']),
            deviceId: drift.Value(w['device_id']),
            assignedEmployeeId: drift.Value(w['assigned_employee_id']),
            faceEmbedding: drift.Value(w['face_embedding']?.toString()),
            bodySignature: drift.Value(w['body_signature']?.toString()),
            status: drift.Value(w['status'] ?? 'IDLE'),
          ));
          
          // Cargar embedding directamente en memoria
          if (w['assigned_employee_id'] != null && w['face_embedding'] != null) {
            try {
              final embStr = w['face_embedding'].toString();
              List<dynamic> jsonList = jsonDecode(embStr);
              List<double> embedding = jsonList.map((e) => (e as num).toDouble()).toList();
              if (embedding.isNotEmpty) {
                _employeeRegistry[w['assigned_employee_id']] = embedding;
                count++;
              }
            } catch (e) {
              debugPrint('[ENTRANCE] Error decoding remote embedding: $e');
            }
          }
        }
      } catch (e) {
        debugPrint('[ENTRANCE] Error descargando de Supabase: $e');
      }
    }

    // Actualizar UI
    if (count == 0) {
      state = state.copyWith(statusMessage: 'Advertencia: 0 perfiles con biométricos.');
    } else {
      state = state.copyWith(statusMessage: 'Recepción activa ($count perfiles cargados).');
    }
    debugPrint('[ENTRANCE] Cargados $count perfiles faciales en memoria.');
  }

  Future<int> _loadFromLocalDb() async {
    final workstations = await _db.getAllWorkstationRecords();
    int count = 0;
    
    for (var w in workstations) {
      if (w.assignedEmployeeId != null && w.faceEmbedding != null) {
        try {
          List<dynamic> jsonList = jsonDecode(w.faceEmbedding!);
          List<double> embedding = jsonList.map((e) => (e as num).toDouble()).toList();
          if (embedding.isNotEmpty) {
             _employeeRegistry[w.assignedEmployeeId!] = embedding;
             count++;
          }
        } catch (e) {
          debugPrint('[ENTRANCE] Error decoding embedding for ${w.assignedEmployeeId}: $e');
        }
      }
    }
    return count;
  }

  void _startImageStream() {
    _cameraController?.startImageStream((image) {
      if (_disposed || _isAnalyzing) return;
      
      final now = DateTime.now();
      if (now.difference(_lastAnalysisTime) < _analysisInterval) return;

      _isAnalyzing = true;
      _lastAnalysisTime = now;
      
      _processFrame(image).then((_) {
        _isAnalyzing = false;
      }).catchError((e) {
        debugPrint('[ENTRANCE] Frame Error: $e');
        _isAnalyzing = false;
      });
    });
  }

  Future<void> _processFrame(CameraImage image) async {
    if (state.lastMatchedEmployeeId != null) return; // Wait until ready
    
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty || _disposed) {
        if (state.statusMessage != 'Recepción activa' && state.statusMessage.startsWith('Detectando')) {
           state = state.copyWith(statusMessage: 'Recepción activa');
        }
        return;
      }

      state = state.copyWith(statusMessage: 'Detectando rostro...');

      // Solo evaluamos la cara más grande/cercana
      final largestFace = faces.reduce((a, b) => 
        (a.boundingBox.width * a.boundingBox.height) > (b.boundingBox.width * b.boundingBox.height) ? a : b);

      final cropped = await _faceAnalyzer.cropFaceFromCameraImageAsync(image, largestFace);
      if (cropped == null) return;

      final incomingEmb = await _embeddingService.generateEmbedding(cropped);
      
      if (_employeeRegistry.isEmpty) {
        state = state.copyWith(statusMessage: 'No hay empleados en BD. Sincroniza app o crea empleados.');
        return;
      }

      // Compare with registry
      String? bestMatchId;
      double maxSim = 0.0;

      for (var entry in _employeeRegistry.entries) {
        final sim = EmployeeProfile.cosineSimilarity(entry.value, incomingEmb);
        if (sim > maxSim) {
          maxSim = sim;
          bestMatchId = entry.key;
        }
      }

      if (maxSim >= AiThresholds.minEmbeddingMatchScore && bestMatchId != null) {
         await _triggerEntrance(bestMatchId);
      } else {
         state = state.copyWith(statusMessage: 'Rostro desconocido (Sim: ${(maxSim*100).toStringAsFixed(1)}%)');
      }
    } catch (e) {
      debugPrint('[ENTRANCE] Error: $e');
    }
  }

  Future<void> _triggerEntrance(String employeeId) async {
    state = state.copyWith(
       lastMatchedEmployeeId: employeeId,
       statusMessage: '¡Bienvenido! Activando tu estación de trabajo...',
    );

    try {
      // Registrar en Supabase - Realtime activará la estación remotamente!
      await Supabase.instance.client
          .from('workstations')
          .update({'status': 'ACTIVE', 'last_employee_id': employeeId})
          .eq('assigned_employee_id', employeeId);
      
      // Opcional: Insertar un ActivityEvent de Entry si quisieras loguearlo aquí
          
      // Feedback visual
      state = state.copyWith(statusMessage: 'Estación Activada.');
      
      // Volver a estado de recepción en 5 segundos
      _clearMessageTimer?.cancel();
      _clearMessageTimer = Timer(const Duration(seconds: 4), () {
        if (!_disposed) {
          state = state.copyWith(
            lastMatchedEmployeeId: null, 
            statusMessage: 'Recepción Activa'
          );
        }
      });

    } catch (e) {
      debugPrint('[ENTRANCE] Supabase trigger error: $e');
      state = state.copyWith(
        lastMatchedEmployeeId: null, 
        statusMessage: 'Error al conectar con la estación.'
      );
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;
    InputImageRotation rotation;

    if (defaultTargetPlatform == TargetPlatform.android) {
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

  void stopCamera() {
    _disposed = true;
    _clearMessageTimer?.cancel();
    final controller = _cameraController;
    _cameraController = null;
    controller?.stopImageStream().catchError((_) {});
    controller?.dispose().catchError((_) {});
    _faceDetector.close();
  }

  @override
  void dispose() {
    stopCamera();
    super.dispose();
  }
}

final entranceKioskProvider = StateNotifierProvider.autoDispose<EntranceKioskNotifier, EntranceKioskState>((ref) {
  return EntranceKioskNotifier(
    ref.watch(appDatabaseProvider),
    ref.watch(faceEmbeddingServiceProvider),
  );
});
