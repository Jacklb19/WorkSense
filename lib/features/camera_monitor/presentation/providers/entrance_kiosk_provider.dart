import 'dart:async';
import 'dart:convert';
import 'dart:ui' show Size;
import 'package:camera/camera.dart';
import 'package:drift/drift.dart' as drift;
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/core/constants/app_constants.dart';
import 'package:worksense_app/core/utils/biometric_utils.dart';
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/data/repositories/attendance_repository_impl.dart';
import 'package:worksense_app/domain/repositories/attendance_repository.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profile.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_embedding_service.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/shared/providers/sync_state_provider.dart';

/// Describes the current phase of the entrance kiosk flow.
enum KioskPhase {
  /// Initial boot / loading registry
  initializing,

  /// Camera active, scanning faces
  scanning,

  /// Blink passed, actively evaluating identity across multiple frames
  verifying,

  /// Face recognized â€“ showing welcome overlay
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
      lastMatchedEmployeeId:
          lastMatchedEmployeeId, // deliberately allow null reset
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

  // ── Evidence window for multi-frame identity confirmation ──
  /// Best score seen per employee across the current evidence window.
  final Map<String, double> _evidenceBestScores = {};

  /// Count of frames where each employee exceeded the match threshold.
  final Map<String, int> _evidenceConfirmations = {};

  /// Total frames evaluated in the current evidence window.
  int _evidenceFrameCount = 0;

  /// Number of near-match retries used in the current attempt.
  int _nearMatchRetries = 0;

  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  // Cached registry: employeeId -> embeddings
  final Map<String, List<List<double>>> _employeeRegistry = {};

  // Cached names: employeeId -> employee name
  final Map<String, String> _employeeNames = {};

  // Cached workstation names: employeeId -> workstation name
  final Map<String, String> _workstationNames = {};

  // Cached workstation IDs: employeeId -> workstation UUID
  final Map<String, String> _workstationIds = {};

  // Timers for phase transitions
  Timer? _phaseTimer;

  EntranceKioskNotifier(
    this._db,
    this._embeddingService,
    this._attendanceRepo,
  ) : super(const EntranceKioskState()) {
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

  String? _getMetadataKey(Map<String, dynamic>? metadata, String key) {
    if (metadata == null) return null;
    final lowerKey = key.toLowerCase();
    for (final k in metadata.keys) {
      final lk = k.toLowerCase();
      if (lk == lowerKey) {
        return metadata[k]?.toString();
      }
    }
    return null;
  }

  String? get _currentCompanyId {
    final user = Supabase.instance.client.auth.currentUser;
    if (user == null) return null;
    final companyId = _getMetadataKey(user.appMetadata, 'company_id') ??
        _getMetadataKey(user.userMetadata, 'company_id');
    if (companyId == null || companyId.isEmpty || companyId == AppConstants.defaultCompanyId) {
      return null;
    }
    return companyId;
  }

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
      state = state.copyWith(
        error: 'No cameras found.',
        statusMessage: 'Error',
      );
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
    final companyId = _currentCompanyId;
    int count = 0;

    // 1. Load employee names from local DB
    await _loadEmployeeNames(companyId: companyId);

    // 2. Intentar cargar desde la BD local
    count = await _loadFromLocalDb(companyId: companyId);

    // 3. Si no hay nada local, descargar directo de Supabase (fallback para CAMERA_MONITOR)
    if (count == 0) {
      if (companyId == null || companyId.isEmpty) {
        debugPrint(
          '[ENTRANCE] Sin company_id valido. Se omite descarga remota.',
        );
        state = state.copyWith(
          statusMessage: 'Sin compania configurada para cargar perfiles.',
        );
      } else {
        debugPrint(
          '[ENTRANCE] BD local vacía. Descargando workstations de Supabase...',
        );
        state = state.copyWith(
          statusMessage: 'Descargando perfiles de la nube...',
        );
        try {
          final client = Supabase.instance.client;
          final response = await client
              .from('workstations')
              .select()
              .eq('company_id', companyId);
          final remoteWorkstations = List<Map<String, dynamic>>.from(response);

          debugPrint(
            '[ENTRANCE] Recibidos ${remoteWorkstations.length} workstations de Supabase.',
          );

          for (final w in remoteWorkstations) {
            // Guardar en BD local para futuras consultas
            await _db.insertWorkstationRecord(
              WorkstationRecordsCompanion(
                id: drift.Value(w['id']),
                name: drift.Value(w['name'] ?? 'Sin nombre'),
                companyId: drift.Value(w['company_id']),
                deviceId: drift.Value(w['device_id']),
                assignedEmployeeId: drift.Value(w['assigned_employee_id']),
                faceEmbeddings:
                    drift.Value(w['face_embedding']?.toString()),
                bodySignature:
                    drift.Value(w['body_signature']?.toString()),
                status: drift.Value(w['status'] ?? 'IDLE'),
              ),
            );
            if (w['roi'] != null) {
              await _db.saveWorkstationRoi(
                w['id'],
                jsonEncode(w['roi']),
              );
            }

            // Cargar embedding directamente en memoria
            if (w['assigned_employee_id'] != null &&
                w['face_embedding'] != null) {
              try {
                final embStr = w['face_embedding'].toString();
                final embeddings =
                    BiometricSerializer.deserializeMultipleEmbeddings(
                  embStr,
                );
                if (embeddings != null && embeddings.isNotEmpty) {
                  _employeeRegistry[w['assigned_employee_id']] =
                      embeddings;
                  _workstationNames[w['assigned_employee_id']] =
                      w['name'] ?? 'Estación';
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
              final empResponse = await client
                  .from('employees')
                  .select('id, name, last_name')
                  .eq('company_id', companyId);
              final remoteEmployees =
                  List<Map<String, dynamic>>.from(empResponse);
              for (final emp in remoteEmployees) {
                final fullName = [
                  emp['name']?.toString() ?? '',
                  emp['last_name']?.toString() ?? '',
                ].where((part) => part.isNotEmpty).join(' ');
                _employeeNames[emp['id']] =
                    fullName.isNotEmpty ? fullName : 'Empleado';
              }
            } catch (e) {
              debugPrint('[ENTRANCE] Error downloading employee names: $e');
            }
          }
        } catch (e) {
          debugPrint('[ENTRANCE] Error descargando de Supabase: $e');
        }
      }
    }

    // Actualizar UI
    if (count == 0) {
      state = state.copyWith(
        statusMessage: 'Advertencia: 0 perfiles con biométricos.',
      );
    } else {
      state = state.copyWith(
        statusMessage: 'Recepción activa ($count perfiles cargados).',
      );
    }
    debugPrint('[ENTRANCE] Cargados $count perfiles faciales en memoria.');
  }

  Future<void> _loadEmployeeNames({String? companyId}) async {
    try {
      final employees = companyId == null || companyId.isEmpty
          ? await _db.getAllEmployeeRecords()
          : await _db.getEmployeeRecordsByCompany(companyId);
      for (final emp in employees) {
        final fullName = [emp.name, emp.lastName]
            .where((part) => part.isNotEmpty)
            .join(' ');
        _employeeNames[emp.id] = fullName.isNotEmpty ? fullName : emp.name;
      }
    } catch (e) {
      debugPrint('[ENTRANCE] Error loading employee names: $e');
    }
  }

  Future<int> _loadFromLocalDb({String? companyId}) async {
    final workstations = companyId == null || companyId.isEmpty
        ? await _db.getAllWorkstationRecords()
        : await _db.getWorkstationRecordsByCompany(companyId);
    int count = 0;

    for (final w in workstations) {
      if (w.assignedEmployeeId != null && w.faceEmbeddings != null) {
        try {
          final embeddings =
              BiometricSerializer.deserializeMultipleEmbeddings(
            w.faceEmbeddings!,
          );
          if (embeddings != null && embeddings.isNotEmpty) {
            _employeeRegistry[w.assignedEmployeeId!] = embeddings;
            _workstationNames[w.assignedEmployeeId!] = w.name;
            _workstationIds[w.assignedEmployeeId!] = w.id;
            count++;
          }
        } catch (e) {
          debugPrint(
            '[ENTRANCE] Error decoding embedding for ${w.assignedEmployeeId}: $e',
          );
        }
      }
    }
    return count;
  }

  void _startImageStream() {
    _cameraController?.startImageStream((image) {
      if (_disposed || _isAnalyzing) return;
      // Only process frames during scanning or verifying phase
      if (state.phase != KioskPhase.scanning &&
          state.phase != KioskPhase.verifying) {
        return;
      }

      final now = DateTime.now();
      if (now.difference(_lastAnalysisTime).inMilliseconds <
          AiThresholds.entranceFrameIntervalMs) {
        return;
      }

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
    if (state.phase != KioskPhase.scanning &&
        state.phase != KioskPhase.verifying) {
      return;
    }

    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);
      if (faces.isEmpty || _disposed) {
        // No face: if we were verifying, don't hard-reset — tolerate brief dropouts
        if (state.phase == KioskPhase.verifying) {
          _evidenceFrameCount++;
          if (_evidenceFrameCount >=
              AiThresholds.entranceEvidenceWindowSize) {
            _resetEvidence();
            state = state.copyWith(
              statusMessage: 'Rostro no reconocido',
              phase: KioskPhase.scanning,
            );
          }
          return;
        }
        if (state.statusMessage != 'Recepción Activa') {
          state = state.copyWith(statusMessage: 'Recepción Activa');
          _hasBlinked = false;
        }
        return;
      }

      final largestFace = faces.reduce(
        (a, b) =>
            (a.boundingBox.width * a.boundingBox.height) >
                    (b.boundingBox.width * b.boundingBox.height)
                ? a
                : b,
      );
      final hasIntruder = faces.length > 1;

      // --- PRESENCE VALIDATION (decoupled from identity) ---
      final widthRatio = largestFace.boundingBox.width / image.width;
      if (widthRatio < AiThresholds.entranceMinFaceWidthRatio) {
        state = state.copyWith(statusMessage: 'Acércate a la cámara');
        // Don't reset blink or evidence for momentary distance issues
        return;
      }

      if ((largestFace.headEulerAngleY?.abs() ?? 0) >
              AiThresholds.entranceMaxHeadAngle ||
          (largestFace.headEulerAngleX?.abs() ?? 0) >
              AiThresholds.entranceMaxHeadAngle) {
        state = state.copyWith(statusMessage: 'Mira directamente de frente');
        return;
      }

      // --- BLINK CHALLENGE (one-time gate, not reset on bad frames) ---
      if (!_hasBlinked) {
        final leftEyeOpen = largestFace.leftEyeOpenProbability ?? 1.0;
        final rightEyeOpen = largestFace.rightEyeOpenProbability ?? 1.0;

        if (leftEyeOpen < AiThresholds.entranceBlinkClosedThreshold &&
            rightEyeOpen < AiThresholds.entranceBlinkClosedThreshold) {
          _hasBlinked = true;
          _resetEvidence();
          state = state.copyWith(
            statusMessage: 'Verificado âœ“ Identificando...',
            phase: KioskPhase.verifying,
          );
        } else {
          state = state.copyWith(statusMessage: 'Parpadea para verificar');
          return;
        }
      }

      // --- IDENTITY EVALUATION (evidence window) ---
      final cropped = await _faceAnalyzer.cropFaceFromCameraImageAsync(
        image,
        largestFace,
      );
      if (cropped == null) return;

      final cropQuality = await _faceAnalyzer.assessCropQuality(cropped);
      if (cropQuality.overallScore < AiThresholds.enrollMinCropQuality) {
        state = state.copyWith(statusMessage: 'Ajusta luz o posicion');
        return;
      }

      final incomingEmb = await _embeddingService.generateEmbedding(cropped);

      if (_employeeRegistry.isEmpty) {
        state = state.copyWith(statusMessage: 'No hay empleados registrados.');
        return;
      }

      // Compare against all employees and all their stored embeddings
      String? frameBestId;
      double frameBestSim = 0.0;

      for (final entry in _employeeRegistry.entries) {
        double maxEmpSim = 0.0;
        for (final storedEmb in entry.value) {
          if (storedEmb.isEmpty || storedEmb.length != incomingEmb.length) {
            continue;
          }
          final sim = EmployeeProfile.cosineSimilarity(
            storedEmb,
            incomingEmb,
          );
          if (sim > maxEmpSim) maxEmpSim = sim;
        }

        if (hasIntruder) {
          maxEmpSim -= 0.03;
        }

        // Track best score ever seen for this employee in the window
        final prevBest = _evidenceBestScores[entry.key] ?? 0.0;
        if (maxEmpSim > prevBest) {
          _evidenceBestScores[entry.key] = maxEmpSim;
        }

        // Count confirmations (frames above threshold)
        if (maxEmpSim >= AiThresholds.entranceMatchThreshold) {
          _evidenceConfirmations[entry.key] =
              (_evidenceConfirmations[entry.key] ?? 0) + 1;
        }

        if (maxEmpSim > frameBestSim) {
          frameBestSim = maxEmpSim;
          frameBestId = entry.key;
        }
      }

      _evidenceFrameCount++;
      debugPrint(
        '[ENTRANCE] Frame $_evidenceFrameCount/${AiThresholds.entranceEvidenceWindowSize} — '
        'best: ${frameBestSim.toStringAsFixed(3)} (${frameBestId ?? "?"}) | '
        'confirmations: $_evidenceConfirmations',
      );

      // Check if any employee reached required confirmations AND best-score floor.
      // Both conditions must be met to prevent low-but-repeated scores from
      // granting access (e.g. an impostor scoring 0.82 on 3 frames but never
      // reaching a truly distinctive peak).
      for (final entry in _evidenceConfirmations.entries) {
        if (entry.value >= AiThresholds.entranceRequiredConfirmations) {
          final bestScore = _evidenceBestScores[entry.key] ?? 0.0;
          if (bestScore >= AiThresholds.entranceMinBestScore) {
            debugPrint(
              '[ENTRANCE] ✅ Match confirmed for ${entry.key} '
              'with ${entry.value} confirmations, best=${bestScore.toStringAsFixed(3)}',
            );
            _resetEvidence();
            await _triggerEntrance(entry.key);
            return;
          } else {
            // Enough frames but peak not high enough — keep sampling.
            debugPrint(
              '[ENTRANCE] ⚠️ ${entry.key} reached ${entry.value} confirmations '
              'but best score ${bestScore.toStringAsFixed(3)} < '
              '${AiThresholds.entranceMinBestScore} — continuing...',
            );
          }
        }
      }

      // Update status during verification
      if (frameBestSim >= AiThresholds.entranceMatchThreshold) {
        state = state.copyWith(statusMessage: 'Confirmando acceso...');
      } else if (frameBestSim >=
          AiThresholds.entranceMatchThreshold -
              AiThresholds.entranceNearMatchMargin) {
        state = state.copyWith(statusMessage: 'Verificando identidad...');
      } else {
        state = state.copyWith(statusMessage: 'Identificando...');
      }

      // Check if evidence window exhausted
      if (_evidenceFrameCount >= AiThresholds.entranceEvidenceWindowSize) {
        // Check if there's a near-match that deserves one more try
        final topEmployee = _evidenceBestScores.entries
            .fold<MapEntry<String, double>?>(
          null,
          (best, e) => best == null || e.value > best.value ? e : best,
        );

        if (topEmployee != null &&
            topEmployee.value >=
                AiThresholds.entranceMatchThreshold -
                    AiThresholds.entranceNearMatchMargin &&
            (_evidenceConfirmations[topEmployee.key] ?? 0) >= 1 &&
            _nearMatchRetries < AiThresholds.entranceMaxNearMatchRetries) {
          // Near match with at least 1 confirmation — extend window once
          _nearMatchRetries++;
          _evidenceFrameCount =
              0; // Reset frame counter for a clean extra window
          debugPrint(
            '[ENTRANCE] Near-match retry #$_nearMatchRetries for ${topEmployee.key} '
            '(best=${topEmployee.value.toStringAsFixed(3)})',
          );
          return;
        }

        // No match found
        debugPrint(
          '[ENTRANCE] âŒ No match after ${AiThresholds.entranceEvidenceWindowSize} frames. '
          'Best: ${topEmployee?.value.toStringAsFixed(3)} for ${topEmployee?.key}',
        );
        _resetEvidence();
        _hasBlinked = false;
        state = state.copyWith(
          statusMessage: 'Rostro no reconocido',
          phase: KioskPhase.scanning,
        );
      }
    } catch (e) {
      debugPrint('[ENTRANCE] Error: $e');
    }
  }

  void _resetEvidence() {
    _evidenceBestScores.clear();
    _evidenceConfirmations.clear();
    _evidenceFrameCount = 0;
    _nearMatchRetries = 0;
  }

  Future<void> _triggerEntrance(String employeeId) async {
    // ── Immediately clear per-person state before anything else ──
    // This prevents any lingering frame from the current person being processed
    // as the next person if the stream is not fully stopped.
    _hasBlinked = false;
    _resetEvidence();

    // Immediately transition to welcome phase to stop all further processing
    final employeeName = _employeeNames[employeeId] ?? 'Empleado';
    final workstationName =
        _workstationNames[employeeId] ?? 'Estación de Trabajo';

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
      final workstation =
          wsId != null ? await _db.getWorkstationById(wsId) : null;
      final employee = await _db.getEmployeeRecordById(employeeId);

      if (openSession != null) {
        // Tiene sesión abierta -> CLOCK OUT
        await _attendanceRepo.clockOut(
          employeeId: employeeId,
          workstationId: workstation?.id,
        );

        // Apagar estación
        await Supabase.instance.client
            .from('workstations')
            .update({'status': 'IDLE'})
            .eq('assigned_employee_id', employeeId);

        final hour = DateTime.now().hour;
        final min = DateTime.now().minute.toString().padLeft(2, '0');
        state = state.copyWith(
          statusMessage:
              '¡Hasta luego $employeeName! Sesión cerrada a las $hour:$min.',
        );
        debugPrint(
          '[ENTRANCE] ✅ Clock-OUT y estación apagada para $employeeName',
        );
      } else {
        // No tiene sesión -> CLOCK IN
        await _attendanceRepo.clockIn(
          employeeId: employeeId,
          companyId: employee?.companyId ?? '',
          workstationId: workstation?.id,
        );

        // Prender estación
        await Supabase.instance.client
            .from('workstations')
            .update({'status': 'ACTIVE', 'last_employee_id': employeeId})
            .eq('assigned_employee_id', employeeId);

        // Mensaje personalizado
        final count = todaySessions.length +
            1; // +1 porque el clock_in de arriba aun no lo refrescamos de la query previa a insertarlo
        final timeStr =
            '${DateTime.now().hour}:${DateTime.now().minute.toString().padLeft(2, '0')}';

        String welcomeMsg;
        if (count == 1) {
          welcomeMsg =
              '¡Bienvenido $employeeName!\nPrimera entrada a las $timeStr.';
        } else {
          welcomeMsg =
              '¡Hola de nuevo $employeeName!\nEntrada #$count del día a las $timeStr.';
        }

        state = state.copyWith(statusMessage: welcomeMsg);
        debugPrint(
          '[ENTRANCE] ✅ Clock-IN y estación activada para $employeeName',
        );
      }
    } catch (e) {
      debugPrint('[ENTRANCE] Supabase trigger / Asistencia error: $e');
      state = state.copyWith(
        statusMessage: 'Reconocido, pero hubo un error de red.',
      );
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

      // ── CRITICAL: Reset per-person blink flag BEFORE restarting stream ──
      // Without this, the NEXT person skips the anti-spoof blink challenge
      // because _hasBlinked=true was left over from the previous match.
      // This was the root cause of dania being recognized as stalejo.
      _hasBlinked = false;
      _resetEvidence();

      // Restart camera stream only after resetting state
      _startImageStream();

      // After 3 seconds of cooldown (extra second so the person walks away),
      // return to scanning. _hasBlinked is already false — next person must blink.
      _phaseTimer = Timer(const Duration(seconds: 3), () {
        if (_disposed) return;
        // Double-check blink flag is clear before allowing scanning
        _hasBlinked = false;
        _resetEvidence();
        state = const EntranceKioskState(
          isReady: true,
          phase: KioskPhase.scanning,
          statusMessage: 'Recepción Activa',
        );
        // Reload registry in background so next scan uses the latest biometrics
        _loadRegistry();
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
      rotationCompensation =
          (sensorOrientation - rotationCompensation + 360) % 360;
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ??
          InputImageRotation.rotation0deg;
    } else {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ??
          InputImageRotation.rotation0deg;
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

final entranceKioskProvider = StateNotifierProvider.autoDispose<
    EntranceKioskNotifier,
    EntranceKioskState>((ref) {
  return EntranceKioskNotifier(
    ref.watch(appDatabaseProvider),
    ref.watch(faceEmbeddingServiceProvider),
    ref.watch(attendanceRepositoryProvider),
  );
});
