import 'dart:convert';
import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/employee.dart';
import 'package:worksense_app/domain/repositories/employee_repository.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profiler.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_analyzer.dart';
import 'package:worksense_app/features/camera_monitor/ai/face_embedding_service.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';


// ── Estado del escaneo ─────────────────────────────────────────────────────────

enum _FrameStatus { searching, detected, error, capturing }

class EmployeeScanState {
  final int currentSampleIndex;
  final List<bool> completedSamples;
  final _FrameStatus frameStatus;
  final String feedback;
  final bool isCapturing;
  final bool isComplete;
  final String? error;
  final bool cameraReady;

  const EmployeeScanState({
    this.currentSampleIndex = 0,
    this.completedSamples = const [false, false, false, false, false],
    this.frameStatus = _FrameStatus.searching,
    this.feedback = 'Posiciónate frente a la cámara',
    this.isCapturing = false,
    this.isComplete = false,
    this.error,
    this.cameraReady = false,
  });

  int get capturedCount => completedSamples.where((s) => s).length;

  EmployeeScanState copyWith({
    int? currentSampleIndex,
    List<bool>? completedSamples,
    _FrameStatus? frameStatus,
    String? feedback,
    bool? isCapturing,
    bool? isComplete,
    String? error,
    bool? cameraReady,
  }) {
    return EmployeeScanState(
      currentSampleIndex: currentSampleIndex ?? this.currentSampleIndex,
      completedSamples: completedSamples ?? this.completedSamples,
      frameStatus: frameStatus ?? this.frameStatus,
      feedback: feedback ?? this.feedback,
      isCapturing: isCapturing ?? this.isCapturing,
      isComplete: isComplete ?? this.isComplete,
      error: error,
      cameraReady: cameraReady ?? this.cameraReady,
    );
  }
}

// ── Notifier ───────────────────────────────────────────────────────────────────

class EmployeeScanNotifier extends StateNotifier<EmployeeScanState> {
  final EmployeeRepository _repository;
  final FaceEmbeddingService _embeddingService;
  final String workstationId;
  final String employeeId;

  CameraController? _cameraController;
  late final EmployeeProfiler _profiler;
  late final FaceDetector _liveDetector;
  late final PoseDetector _livePoseDetector;

  bool _isLiveProcessing = false;
  bool _disposed = false;
  bool _blockFrameUpdates = false;
  CameraImage? _lastFrame;

  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  EmployeeScanNotifier({
    required EmployeeRepository repository,
    required FaceEmbeddingService embeddingService,
    required this.workstationId,
    required this.employeeId,
  })  : _repository = repository,
        _embeddingService = embeddingService,
        super(const EmployeeScanState()) {
    _profiler = EmployeeProfiler(
      faceAnalyzer: FaceAnalyzer(),
      embeddingService: _embeddingService,
    );
    _liveDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableClassification: true,
        enableLandmarks: true,
        enableTracking: true,
      ),
    );
    _livePoseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
  }

  CameraController? get cameraController => _cameraController;

  Future<void> initCamera(List<CameraDescription> cameras) async {
    if (_disposed || cameras.isEmpty) return;

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
      if (_disposed) return;
      state = state.copyWith(cameraReady: true);
      await _cameraController!.startImageStream(_onFrame);
    } catch (e) {
      state = state.copyWith(error: 'Error al iniciar cámara: $e');
    }
  }

  Future<void> stopCamera() async {
    if (_disposed || _cameraController == null) return;
    try {
      if (_cameraController!.value.isStreamingImages) {
        await _cameraController!.stopImageStream();
      }
      await _cameraController!.dispose();
      _cameraController = null;
      state = state.copyWith(cameraReady: false);
    } catch (_) {}
  }

  void _onFrame(CameraImage image) {
    if (_disposed || _blockFrameUpdates) return;
    _lastFrame = image;
    if (_isLiveProcessing) return;
    _isLiveProcessing = true;

    _analyzeLive(image).whenComplete(() {
      _isLiveProcessing = false;
    });
  }

  Future<void> _analyzeLive(CameraImage image) async {
    if (_disposed) return;
    final inputImage = _buildInputImage(image);
    if (inputImage == null) return;

    try {
      final faces = await _liveDetector.processImage(inputImage);
      if (_disposed) return;

      final poses = await _livePoseDetector.processImage(inputImage);
      if (_disposed) return;

      if (faces.isEmpty) {
        state = state.copyWith(
          frameStatus: _FrameStatus.searching,
          feedback: 'Acércate a la cámara',
        );
      } else if (faces.length > 1) {
        state = state.copyWith(
          frameStatus: _FrameStatus.error,
          feedback: 'Solo debe estar el empleado en cámara',
        );
      } else if (poses.isEmpty) {
        state = state.copyWith(
          frameStatus: _FrameStatus.searching,
          feedback: 'Asegúrate de que tu cuerpo sea visible',
        );
      } else {
        if (!state.isCapturing && (state.frameStatus != _FrameStatus.capturing)) {
          state = state.copyWith(
            frameStatus: _FrameStatus.detected,
            feedback: 'Posicion correcta',
          );
        }
      }
    } catch (_) {}
  }

  Future<void> captureCurrentSample() async {
    if (_disposed) return;
    if (state.isCapturing || _lastFrame == null) return;
    if (state.frameStatus != _FrameStatus.detected) return;

    try {
      state = state.copyWith(
        isCapturing: true,
        frameStatus: _FrameStatus.capturing,
      );

      final inputImage = _buildInputImage(_lastFrame!);
      if (inputImage == null) {
        state = state.copyWith(
          isCapturing: false,
          frameStatus: _FrameStatus.error,
          feedback: 'Error al procesar el frame',
        );
        return;
      }

      final result = await _profiler.addSample(inputImage, _lastFrame!);

      if (result == SampleResult.success) {
        final newCompleted = List<bool>.from(state.completedSamples);
        newCompleted[state.currentSampleIndex] = true;

        final nextIndex = state.currentSampleIndex + 1;
        final isComplete = nextIndex >= EmployeeProfiler.samplesRequired;

        state = state.copyWith(
          completedSamples: newCompleted,
          currentSampleIndex: isComplete ? state.currentSampleIndex : nextIndex,
          isCapturing: false,
          isComplete: isComplete,
          frameStatus: _FrameStatus.searching,
          feedback: isComplete
              ? 'Escaneo completado'
              : EmployeeProfiler.instructions[nextIndex].text,
        );

        _blockFrameUpdates = true;
        if (!isComplete) {
          await Future<void>.delayed(const Duration(milliseconds: 1500));
        }
        _blockFrameUpdates = false;

        if (isComplete) {
          await _buildAndSaveProfile();
        }
      } else {
        final msg = _resultMessage(result);
        state = state.copyWith(
          isCapturing: false,
          frameStatus: _FrameStatus.error,
          feedback: msg,
        );
        _blockFrameUpdates = true;
        await Future<void>.delayed(const Duration(milliseconds: 2000));
        _blockFrameUpdates = false;
      }
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(isCapturing: false, error: e.toString());
    }
  }

  Future<void> _buildAndSaveProfile() async {
    if (_disposed) return;
    try {
      final profile = _profiler.buildProfile(
        employeeId: employeeId,
        workstationId: workstationId,
      );

      // Delegar persistencia al repositorio central
      await _repository.enrollEmployee(
        employeeId: employeeId,
        workstationId: workstationId,
        faceEmbedding: profile.faceEmbedding,
        bodySignature: profile.bodySignature,
      );
    } catch (e) {
      if (_disposed) return;
      state = state.copyWith(
        error: 'Error al guardar el perfil: $e',
        isComplete: false,
      );
    }
  }

  void resetScan() {
    if (_disposed) return;
    _profiler.reset();
    state = const EmployeeScanState(cameraReady: true);
  }

  String _resultMessage(SampleResult result) {
    switch (result) {
      case SampleResult.success:
        return 'Muestra capturada';
      case SampleResult.noFace:
        return 'No se detectó rostro. Acércate más.';
      case SampleResult.multiplePeople:
        return 'Solo debe estar el empleado en cámara.';
      case SampleResult.lowConfidence:
        return 'Poca iluminación o distancia incorrecta.';
      case SampleResult.noPose:
        return 'Cuerpo no detectado. Asegúrate de ser visible.';
      case SampleResult.invalidSignature:
        return 'Postura no válida. Quédate quieto.';
    }
  }

  InputImage? _buildInputImage(CameraImage image) {
    if (_cameraController == null) return null;
    final camera = _cameraController!.description;
    final sensorOrientation = camera.sensorOrientation;

    InputImageRotation rotation;
    if (Platform.isAndroid) {
      final deviceOrientation = _cameraController!.value.deviceOrientation;
      int comp = _orientationMap[deviceOrientation] ?? 0;
      if (camera.lensDirection == CameraLensDirection.front) {
        comp = (sensorOrientation - comp + 360) % 360;
      } else {
        comp = (sensorOrientation - comp + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(comp) ??
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

  @override
  void dispose() {
    _disposed = true;
    try {
      _cameraController?.stopImageStream().catchError((_) {});
      _cameraController?.dispose();
    } catch (_) {}
    _liveDetector.close();
    _livePoseDetector.close();
    _profiler.dispose();
    super.dispose();
  }
}

// ── Provider (family por workstationId+employeeId) ─────────────────────────────

typedef ScanParams = ({String workstationId, String employeeId});

final employeeScanProvider = StateNotifierProvider.autoDispose
    .family<EmployeeScanNotifier, EmployeeScanState, ScanParams>(
  (ref, params) {
    final repository = ref.watch(employeeRepositoryProvider);
    final embeddingService = ref.watch(faceEmbeddingServiceProvider);
    return EmployeeScanNotifier(
      repository: repository,
      embeddingService: embeddingService,
      workstationId: params.workstationId,
      employeeId: params.employeeId,
    );
  },
);


// ── Pantalla ───────────────────────────────────────────────────────────────────

class EmployeeScanScreen extends ConsumerStatefulWidget {
  final String workstationId;
  final String employeeId;
  final VoidCallback onComplete;

  const EmployeeScanScreen({
    super.key,
    required this.workstationId,
    required this.employeeId,
    required this.onComplete,
  });

  @override
  ConsumerState<EmployeeScanScreen> createState() => _EmployeeScanScreenState();
}

class _EmployeeScanScreenState extends ConsumerState<EmployeeScanScreen> with WidgetsBindingObserver {
  ScanParams get _params => (workstationId: widget.workstationId, employeeId: widget.employeeId);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);
    ref.read(faceEmbeddingServiceProvider).initialize();
    _initCamera();
  }

  Future<void> _initCamera() async {
    final cameras = await ref.read(availableCamerasProvider.future);
    if (mounted) {
      await ref.read(employeeScanProvider(_params).notifier).initCamera(cameras);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scanState = ref.watch(employeeScanProvider(_params));
    final controller = ref.read(employeeScanProvider(_params).notifier).cameraController;

    ref.listen<EmployeeScanState>(employeeScanProvider(_params), (prev, next) {
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        Future.delayed(const Duration(milliseconds: 1000), () {
          if (mounted) widget.onComplete();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          if (controller != null && scanState.cameraReady)
            Center(
              child: CameraPreview(controller),
            )
          else
            const Center(child: CircularProgressIndicator(color: AppColors.primary)),

          // Glassmorphism HUD
          const _HUDOverlay(),

          // Guide Frame
          _GuideFrame(status: scanState.frameStatus),

          // Top Info
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopHUD(
              current: scanState.capturedCount,
              total: EmployeeProfiler.samplesRequired,
            ),
          ),

          // Bottom Controls
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomHUD(
              state: scanState,
              onCapture: () => ref.read(employeeScanProvider(_params).notifier).captureCurrentSample(),
            ),
          ),
        ],
      ),
    );
  }
}

class _HUDOverlay extends StatelessWidget {
  const _HUDOverlay();

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment.center,
            radius: 0.8,
            colors: [
              Colors.transparent,
              Colors.black.withOpacity(0.2),
              Colors.black.withOpacity(0.6),
            ],
            stops: const [0.5, 0.8, 1.0],
          ),
        ),
      ),
    );
  }
}

class _TopHUD extends StatelessWidget {
  final int current;
  final int total;
  const _TopHUD({required this.current, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.8), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Row(
          children: [
            IconButton(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.close, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'ENROLAMIENTO BIOMÉTRICO',
                  style: TextStyle(
                    color: AppColors.primaryLight,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 2.0,
                  ),
                ),
                Text(
                  'Muestra $current de $total completada',
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _GuideFrame extends StatelessWidget {
  final _FrameStatus status;
  const _GuideFrame({required this.status});

  Color get _color {
    switch (status) {
      case _FrameStatus.searching: return Colors.white38;
      case _FrameStatus.detected: return AppColors.feedbackDetected;
      case _FrameStatus.error: return AppColors.feedbackError;
      case _FrameStatus.capturing: return AppColors.feedbackCapturing;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameW = size.width * 0.75;
    final frameH = size.height * 0.45;

    return Center(
      child: Container(
        width: frameW,
        height: frameH,
        decoration: BoxDecoration(
          border: Border.all(color: _color.withOpacity(0.5), width: 1),
          borderRadius: BorderRadius.circular(32),
        ),
        child: Stack(
          children: [
            _CornerIndicator(color: _color, top: 0, left: 0),
            _CornerIndicator(color: _color, top: 0, right: 0),
            _CornerIndicator(color: _color, bottom: 0, left: 0),
            _CornerIndicator(color: _color, bottom: 0, right: 0),
            
            if (status == _FrameStatus.capturing)
               const Center(
                 child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.primaryLight),
               ),
          ],
        ),
      ),
    );
  }
}

class _CornerIndicator extends StatelessWidget {
  final Color color;
  final double? top, bottom, left, right;
  const _CornerIndicator({required this.color, this.top, this.bottom, this.left, this.right});

  @override
  Widget build(BuildContext context) {
    return Positioned(
      top: top, bottom: bottom, left: left, right: right,
      child: Container(
        width: 30,
        height: 30,
        decoration: BoxDecoration(
          border: Border(
            top: top != null ? BorderSide(color: color, width: 4) : BorderSide.none,
            bottom: bottom != null ? BorderSide(color: color, width: 4) : BorderSide.none,
            left: left != null ? BorderSide(color: color, width: 4) : BorderSide.none,
            right: right != null ? BorderSide(color: color, width: 4) : BorderSide.none,
          ),
        ),
      ),
    );
  }
}

class _BottomHUD extends StatelessWidget {
  final EmployeeScanState state;
  final VoidCallback onCapture;

  const _BottomHUD({required this.state, required this.onCapture});

  @override
  Widget build(BuildContext context) {
    final bool canCapture = state.frameStatus == _FrameStatus.detected && !state.isCapturing;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.9), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Instruction
            Text(
              state.feedback.toUpperCase(),
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _getStatusColor(state.frameStatus),
                fontSize: 13,
                fontWeight: FontWeight.w900,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 24),

            // Capture Button
            if (!state.isComplete)
              GestureDetector(
                onTap: canCapture ? onCapture : null,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: canCapture ? Colors.white : Colors.white24,
                      width: 4,
                    ),
                    color: canCapture ? AppColors.primary.withOpacity(0.2) : Colors.transparent,
                  ),
                  child: Center(
                    child: Container(
                      height: 60,
                      width: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: canCapture ? Colors.white : Colors.white10,
                      ),
                      child: state.isCapturing 
                        ? const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                          )
                        : Icon(
                            Icons.fingerprint, 
                            color: canCapture ? AppColors.primary : Colors.white24, 
                            size: 32
                          ),
                    ),
                  ),
                ),
              )
            else
              const Icon(Icons.check_circle, color: AppColors.success, size: 80),

            const SizedBox(height: 24),
            // Progress dots
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                EmployeeProfiler.samplesRequired,
                (i) => Container(
                  width: 12,
                  height: 12,
                  margin: const EdgeInsets.symmetric(horizontal: 6),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: state.completedSamples[i] 
                      ? AppColors.primaryLight 
                      : Colors.white10,
                    border: Border.all(
                      color: state.currentSampleIndex == i 
                        ? AppColors.primaryLight 
                        : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(_FrameStatus status) {
    switch (status) {
      case _FrameStatus.detected: return AppColors.feedbackDetected;
      case _FrameStatus.error: return AppColors.feedbackError;
      default: return Colors.white70;
    }
  }
}

