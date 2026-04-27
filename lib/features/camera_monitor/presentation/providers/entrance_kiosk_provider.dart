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

import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profile.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_embedding_service.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/data/repositories/attendance_repository_impl.dart';
import 'package:worksense_app/data/repositories/sync_repository_impl.dart';
import 'package:worksense_app/domain/repositories/attendance_repository.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

/// Describes the current phase of the entrance kiosk flow.
enum KioskPhase {
  /// Initial boot / loading registry
  initializing,
  /// Camera active, scanning faces
  scanning,
  /// Face recognized – showing welcome overlay
  welcome,
  /// Cooldown after welcome before re-enabling scanning
  cooldown,
}

class EntranceKioskState {
  final bool isReady;
  final String? error;
  final bool isProcessing;
  final String statusMessage;
  final String? lastMatchedEmployeeId;
  final String? matchedEmployeeName;
  final String? matchedWorkstationName;
  final KioskPhase phase;

  const EntranceKioskState({
    this.isReady = false,
    this.error,
    this.isProcessing = false,
    this.statusMessage = 'Escaneando...',
    this.lastMatchedEmployeeId,
    this.matchedEmployeeName,
    this.matchedWorkstationName,
    this.phase = KioskPhase.initializing,
  });

  EntranceKioskState copyWith({
    bool? isReady,
    String? error,
    bool? isProcessing,
    String? statusMessage,
    String? lastMatchedEmployeeId,
    String? matchedEmployeeName,
    String? matchedWorkstationName,
    KioskPhase? phase,
  }) {
    return EntranceKioskState(
      isReady: isReady ?? this.isReady,
      error: error ?? this.error,
      isProcessing: isProcessing ?? this.isProcessing,
      statusMessage: statusMessage ?? this.statusMessage,
      lastMatchedEmployeeId: lastMatchedEmployeeId, // deliberately allow null reset
      matchedEmployeeName: matchedEmployeeName,
      matchedWorkstationName: matchedWorkstationName,
      phase: phase ?? this.phase,
    );
  }
}

class EntranceKioskNotifier extends StateNotifier<EntranceKioskState> {
  final AppDatabase _db;
  final FaceEmbeddingService _embeddingService;
  final AttendanceRepository _attendanceRepo;

  CameraController? _cameraController;
  late final FaceDetector _faceDetector;
  late final FaceAnalyzer _faceAnalyzer;

  bool _isAnalyzing = false;
  bool _disposed = false;
  bool _hasBlinked = false;
  DateTime _lastAnalysisTime = DateTime.fromMillisecondsSinceEpoch(0);
  static const Duration _analysisInterval = Duration(milliseconds: 300);
  
  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // Cached registry: employeeId -> embedding
  final Map<String, List<double>> _employeeRegistry = {};
  // Cached names: employeeId -> employee name
  final Map<String, String> _employeeNames = {};
  // Cached workstation names: employeeId -> workstation name
  final Map<String, String> _workstationNames = {};
  // Cached workstation IDs: employeeId -> workstation UUID
  final Map<String, String> _workstationIds = {};
  
  // Timers for phase transitions
  Timer? _phaseTimer;

  EntranceKioskNotifier(this._db, this._embeddingService, this._attendanceRepo) : super(const EntranceKioskState()) {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableTracking: false,
        enableLandmarks: true,
        enableClassification: true,
      ),
    );
    _faceAnalyzer = FaceAnalyzer();
  }

  CameraController? get cameraController => _cameraController;

  Future<void> initialize(List<CameraDescription> cameras) async {
    state = const EntranceKioskState(
      statusMessage: 'Cargando base de datos biométrica...',
      phase: KioskPhase.initializing,
    );
    
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
      ResolutionPreset.medium, // Aumentado de low a medium para mejor precisión facial
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.nv21,
    );

    try {
      await _cameraController!.initialize();
      if (_disposed) return;
      state = state.copyWith(
        isReady: true,
        statusMessage: 'Recepción Activa',
        phase: KioskPhase.scanning,
      );
      _startImageStream();
    } catch (e) {
      state = state.copyWith(error: 'Camera initialization failed: $e');
    }
  }

  Future<void> _loadRegistry() async {
    _employeeRegistry.clear();
    _employeeNames.clear();
    _workstationNames.clear();
    _workstationIds.clear();
    int count = 0;

    // 1. Load employee names from local DB
    await _loadEmployeeNames();

    // 2. Intentar cargar desde la BD local
    count = await _loadFromLocalDb();

    // 3. Si no hay nada local, descargar directo de Supabase (fallback para CAMERA_MONITOR)
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
                _workstationNames[w['assigned_employee_id']] = w['name'] ?? 'Estación';
                _workstationIds[w['assigned_employee_id']] = w['id'];
                count++;
              }
            } catch (e) {
              debugPrint('[ENTRANCE] Error decoding remote embedding: $e');
            }
          }
        }

        // Also try to load employee names from Supabase if not in local DB
        if (_employeeNames.isEmpty) {
          try {
            final empResponse = await client.from('employees').select('id, name');
            final remoteEmployees = List<Map<String, dynamic>>.from(empResponse);
            for (var emp in remoteEmployees) {
              _employeeNames[emp['id']] = emp['name'] ?? 'Empleado';
            }
          } catch (e) {
            debugPrint('[ENTRANCE] Error downloading employee names: $e');
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

  Future<void> _loadEmployeeNames() async {
    try {
      final employees = await _db.getAllEmployeeRecords();
      for (var emp in employees) {
        _employeeNames[emp.id] = emp.name;
      }
    } catch (e) {
      debugPrint('[ENTRANCE] Error loading employee names: $e');
    }
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
             _workstationNames[w.assignedEmployeeId!] = w.name;
             _workstationIds[w.assignedEmployeeId!] = w.id;
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
      // Only process frames during scanning phase
      if (state.phase != KioskPhase.scanning) return;
      
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
    if (state.phase != KioskPhase.scanning) return;
    
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty || _disposed) {
        if (state.statusMessage != 'Recepción Activa') {
           state = state.copyWith(statusMessage: 'Recepción Activa');
           _hasBlinked = false; // Reset blink
        }
        return;
      }

      final largestFace = faces.reduce((a, b) => 
        (a.boundingBox.width * a.boundingBox.height) > (b.boundingBox.width * b.boundingBox.height) ? a : b);

      // --- CENTERING & LIVENESS RULES ---
      // Check distance (size ratio)
      final widthRatio = largestFace.boundingBox.width / image.width;
      if (widthRatio < 0.25) {
        state = state.copyWith(statusMessage: 'Acércate a la cámara');
        _hasBlinked = false;
        return;
      }
      
      // Check angles
      if ((largestFace.headEulerAngleY?.abs() ?? 0) > 12 || (largestFace.headEulerAngleX?.abs() ?? 0) > 12) {
        state = state.copyWith(statusMessage: 'Mira directamente de frente');
        _hasBlinked = false;
        return;
      }

      // Blink Challenge
      if (!_hasBlinked) {
        final leftEyeOpen = largestFace.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpen = largestFace.rightEyeOpenProbability ?? 1.0;
        
        debugPrint('[ENTRANCE] Eyes: L=${leftEyeOpen.toStringAsFixed(2)} R=${rightEyeOpen.toStringAsFixed(2)}');
        
        if (leftEyeOpen < 0.45 && rightEyeOpen < 0.45) {
          _hasBlinked = true;
          state = state.copyWith(statusMessage: 'Verificado ✓ Identificando...');
        } else {
          state = state.copyWith(statusMessage: 'Parpadea para verificar');
          return; // Wait for blink
        }
      }

      final cropped = await _faceAnalyzer.cropFaceFromCameraImageAsync(image, largestFace);
      if (cropped == null) return;

      final incomingEmb = await _embeddingService.generateEmbedding(cropped);
      
      if (_employeeRegistry.isEmpty) {
        state = state.copyWith(statusMessage: 'No hay empleados en BD. Sincroniza app o crea empleados.');
        return;
      }

      String? bestMatchId;
      double maxSim = 0.0;

      for (var entry in _employeeRegistry.entries) {
        final sim = EmployeeProfile.cosineSimilarity(entry.value, incomingEmb);
        if (sim > maxSim) {
          maxSim = sim;
          bestMatchId = entry.key;
        }
      }

      // Strict Threshold for Entrance (0.87 minimum recommended for high security)
      final threshold = 0.87; 

      if (maxSim >= threshold && bestMatchId != null) {
         await _triggerEntrance(bestMatchId);
      } else {
         state = state.copyWith(statusMessage: 'Rostro desconocido (Sim: %)');
         _hasBlinked = false; // Require new blink on fail
      }
    } catch (e) {
      debugPrint('[ENTRANCE] Error: ');
    }
  }

  Future<void> _triggerEntrance(String employeeId) async {
    // Immediately transition to welcome phase to stop all further processing
    final employeeName = _employeeNames[employeeId] ?? 'Empleado';
    final workstationName = _workstationNames[employeeId] ?? 'Estación de Trabajo';
    
    state = EntranceKioskState(
      isReady: true,
      phase: KioskPhase.welcome,
      lastMatchedEmployeeId: employeeId,
      matchedEmployeeName: employeeName,
      matchedWorkstationName: workstationName,
      statusMessage: '¡Bienvenido, $employeeName!',
    );

    // Detener la cámara para evitar procesamiento extra
    try {
      await _cameraController?.stopImageStream();
    } catch (_) {}

    try {
      // 1. Lógica de Asistencia (Clock IN / OUT)
      final openSession = await _attendanceRepo.getOpenSession(employeeId);
      final todaySessions = await _attendanceRepo.getTodaySessions(employeeId);
      
      // Corregido: Buscar por el ID de la estación almacenado en cache, no por el nombre.
      final wsId = _workstationIds[employeeId];
      final workstation = wsId != null ? await _db.getWorkstationById(wsId) : null;
      final employee = await _db.getEmployeeRecordById(employeeId);

      if (openSession != null) {
        // Tiene sesión abierta -> CLOCK OUT
        await _attendanceRepo.clockOut(employeeId: employeeId, workstationId: workstation?.id);
        
        // Apagar estación
        await Supabase.instance.client
            .from('workstations')
            .update({'status': 'IDLE'})
            .eq('assigned_employee_id', employeeId);

        final hour = DateTime.now().hour;
        final min = DateTime.now().minute.toString().padLeft(2, '0');
        state = state.copyWith(statusMessage: '¡Hasta luego $employeeName! Sesión cerrada a las $hour:$min.');
        debugPrint('[ENTRANCE] ✅ Clock-OUT y estación apagada para $employeeName');
      } else {
        // No tiene sesión -> CLOCK IN
        await _attendanceRepo.clockIn(
          employeeId: employeeId, 
          companyId: employee?.companyId ?? '', 
          workstationId: workstation?.id
        );

        // Prender estación
        await Supabase.instance.client
            .from('workstations')
            .update({'status': 'ACTIVE', 'last_employee_id': employeeId})
            .eq('assigned_employee_id', employeeId);

        // Mensaje personalizado 
        final count = todaySessions.length + 1; // +1 porque el clock_in de arriba aun no lo refrescamos de la query previa a insertarlo
        final timeStr = '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';
        
        String welcomeMsg;
        if (count == 1) {
          welcomeMsg = '¡Bienvenido $employeeName!\nPrimera entrada a las $timeStr.';
        } else {
          welcomeMsg = '¡Hola de nuevo $employeeName!\nEntrada #$count del día a las $timeStr.';
        }

        state = state.copyWith(statusMessage: welcomeMsg);
        debugPrint('[ENTRANCE] ✅ Clock-IN y estación activada para $employeeName');
      }
    } catch (e) {
      debugPrint('[ENTRANCE] Supabase trigger / Asistencia error: $e');
      state = state.copyWith(statusMessage: 'Reconocido, pero hubo un error de red.');
    }

    // After 5 seconds: transition to cooldown, then back to scanning
    _phaseTimer?.cancel();
    _phaseTimer = Timer(const Duration(seconds: 5), () {
      if (_disposed) return;
      
      // Cooldown phase: brief transition before re-enabling scanner
      state = const EntranceKioskState(
        isReady: true,
        phase: KioskPhase.cooldown,
        statusMessage: 'Preparando escáner...',
      );

      // Restart camera stream
      _startImageStream();

      // After 2 seconds of cooldown, return to scanning
      _phaseTimer = Timer(const Duration(seconds: 2), () {
        if (_disposed) return;
        state = const EntranceKioskState(
          isReady: true,
          phase: KioskPhase.scanning,
          statusMessage: 'Recepción Activa',
        );
      });
    });
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
    _phaseTimer?.cancel();
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

final attendanceRepositoryProvider = Provider<AttendanceRepository>((ref) {
  final db = ref.watch(appDatabaseProvider);
  final syncRepo = ref.watch(syncRepositoryProvider);
  return AttendanceRepositoryImpl(db, syncRepo);
});

final entranceKioskProvider = StateNotifierProvider.autoDispose<EntranceKioskNotifier, EntranceKioskState>((ref) {
  return EntranceKioskNotifier(
    ref.watch(appDatabaseProvider),
    ref.watch(faceEmbeddingServiceProvider),
    ref.watch(attendanceRepositoryProvider),
  );
});
