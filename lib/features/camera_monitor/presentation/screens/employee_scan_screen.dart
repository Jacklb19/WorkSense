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
import 'package:worksense_app/data/datasources/local/database.dart';
import 'package:worksense_app/features/camera_monitor/ai/employee_profiler.dart';
import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';

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
  final AppDatabase _db;
  final String workstationId;
  final String employeeId;

  CameraController? _cameraController;
  late final EmployeeProfiler _profiler;
  late final FaceDetector _liveDetector;
  late final PoseDetector _livePoseDetector;

  bool _isLiveProcessing = false;
  CameraImage? _lastFrame;

  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  EmployeeScanNotifier({
    required AppDatabase db,
    required this.workstationId,
    required this.employeeId,
  })  : _db = db,
        super(const EmployeeScanState()) {
    _profiler = EmployeeProfiler();
    _liveDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableTracking: false,
      ),
    );
    _livePoseDetector = PoseDetector(
      options: PoseDetectorOptions(mode: PoseDetectionMode.stream),
    );
  }

  CameraController? get cameraController => _cameraController;

  Future<void> initCamera(List<CameraDescription> cameras) async {
    if (cameras.isEmpty) return;

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
      state = state.copyWith(cameraReady: true);
      await _cameraController!.startImageStream(_onFrame);
    } catch (e) {
      state = state.copyWith(error: 'Error al iniciar cámara: $e');
    }
  }

  void _onFrame(CameraImage image) {
    _lastFrame = image;
    if (_isLiveProcessing) return;
    _isLiveProcessing = true;

    _analyzeLive(image).whenComplete(() => _isLiveProcessing = false);
  }

  Future<void> _analyzeLive(CameraImage image) async {
    final inputImage = _buildInputImage(image);
    if (inputImage == null) return;

    try {
      final results = await Future.wait([
        _liveDetector.processImage(inputImage),
        _livePoseDetector.processImage(inputImage),
      ]);

      final faces = results[0] as List<Face>;
      final poses = results[1] as List<Pose>;

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
        state = state.copyWith(
          frameStatus: _FrameStatus.detected,
          feedback: 'Posición correcta ✓',
        );
      }
    } catch (_) {}
  }

  /// Captura la muestra actual. Llama cuando el usuario presiona el botón.
  Future<void> captureCurrentSample() async {
    if (state.isCapturing || _lastFrame == null) return;
    if (state.frameStatus != _FrameStatus.detected) return;

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

    final result = await _profiler.addSample(inputImage);

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
            ? '¡Escaneo completado!'
            : EmployeeProfiler.instructions[nextIndex].text,
      );

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
    }
  }

  Future<void> _buildAndSaveProfile() async {
    try {
      final profile = _profiler.buildProfile(
        employeeId: employeeId,
        workstationId: workstationId,
      );

      await _db.saveEmployeeProfile(
        workstationId: workstationId,
        employeeId: employeeId,
        faceEmbeddingJson: jsonEncode(profile.faceEmbedding),
        bodySignatureJson: jsonEncode(profile.bodySignature.toJson()),
      );
    } catch (e) {
      state = state.copyWith(
        error: 'Error al guardar el perfil: $e',
        isComplete: false,
      );
    }
  }

  void resetScan() {
    _profiler.reset();
    state = const EmployeeScanState(cameraReady: true);
  }

  String _resultMessage(SampleResult result) {
    switch (result) {
      case SampleResult.success:
        return '¡Muestra capturada!';
      case SampleResult.noFace:
        return 'No se detectó ningún rostro. Acércate más.';
      case SampleResult.multiplePeople:
        return 'Solo debe estar el empleado en cámara.';
      case SampleResult.lowConfidence:
        return 'Poca iluminación o distancia incorrecta. Intenta de nuevo.';
      case SampleResult.noPose:
        return 'No se detectó tu cuerpo. Asegúrate de ser visible.';
      case SampleResult.invalidSignature:
        return 'Postura no válida. Quédate quieto e intenta de nuevo.';
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
        comp = (sensorOrientation + comp) % 360;
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
    _cameraController?.stopImageStream().catchError((_) {});
    _cameraController?.dispose();
    _profiler.dispose();
    _liveDetector.close();
    _livePoseDetector.close();
    super.dispose();
  }
}

// ── Provider (family por workstationId+employeeId) ─────────────────────────────

final employeeScanProvider = StateNotifierProvider.family<EmployeeScanNotifier,
    EmployeeScanState, (String, String)>(
  (ref, ids) {
    final db = ref.watch(appDatabaseProvider);
    return EmployeeScanNotifier(
      db: db,
      workstationId: ids.$1,
      employeeId: ids.$2,
    );
  },
);

// ── Pantalla ───────────────────────────────────────────────────────────────────

class EmployeeScanScreen extends ConsumerStatefulWidget {
  final String workstationId;
  final String employeeId;

  /// Callback al completar el escaneo (navegar a KioskScreen).
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

class _EmployeeScanScreenState extends ConsumerState<EmployeeScanScreen> {
  (String, String) get _ids => (widget.workstationId, widget.employeeId);

  @override
  void initState() {
    super.initState();
    SystemChrome.setPreferredOrientations([DeviceOrientation.portraitUp]);

    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final cameras = await ref.read(availableCamerasProvider.future);
      if (mounted) {
        await ref
            .read(employeeScanProvider(_ids).notifier)
            .initCamera(cameras);
      }
    });
  }

  @override
  void dispose() {
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
    final scanState = ref.watch(employeeScanProvider(_ids));
    final controller =
        ref.read(employeeScanProvider(_ids).notifier).cameraController;

    // Navegar al completar
    ref.listen<EmployeeScanState>(employeeScanProvider(_ids), (prev, next) {
      if (!mounted) return;
      if (next.isComplete && !(prev?.isComplete ?? false)) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) widget.onComplete();
        });
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Cámara de fondo
          if (controller != null && scanState.cameraReady)
            CameraPreview(controller)
          else
            const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            ),

          // Recuadro guía
          _GuideFrame(status: scanState.frameStatus),

          // Panel superior
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: _TopBar(
              sampleIndex: scanState.currentSampleIndex,
              total: EmployeeProfiler.samplesRequired,
            ),
          ),

          // Panel inferior con instrucciones + botón
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: _BottomPanel(
              scanState: scanState,
              onCapture: () => ref
                  .read(employeeScanProvider(_ids).notifier)
                  .captureCurrentSample(),
              onReset: () =>
                  ref.read(employeeScanProvider(_ids).notifier).resetScan(),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Widgets internos ───────────────────────────────────────────────────────────

class _TopBar extends StatelessWidget {
  final int sampleIndex;
  final int total;

  const _TopBar({required this.sampleIndex, required this.total});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Colors.black.withOpacity(0.7), Colors.transparent],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Text(
          'Escaneo del Empleado — Muestra ${sampleIndex + 1} de $total',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
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
      case _FrameStatus.searching:
        return Colors.white54;
      case _FrameStatus.detected:
        return Colors.green;
      case _FrameStatus.error:
        return Colors.red;
      case _FrameStatus.capturing:
        return AppColors.primary;
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final frameW = size.width * 0.65;
    final frameH = size.height * 0.55;
    final left = (size.width - frameW) / 2;
    final top = (size.height - frameH) / 2.4;

    return Positioned(
      left: left,
      top: top,
      width: frameW,
      height: frameH,
      child: CustomPaint(
        painter: _DashedRectPainter(color: _color),
      ),
    );
  }
}

class _DashedRectPainter extends CustomPainter {
  final Color color;
  const _DashedRectPainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    const cornerLen = 30.0;
    final corners = [
      // Top-left
      [Offset(0, cornerLen), Offset.zero, Offset(cornerLen, 0)],
      // Top-right
      [
        Offset(size.width - cornerLen, 0),
        Offset(size.width, 0),
        Offset(size.width, cornerLen)
      ],
      // Bottom-left
      [
        Offset(0, size.height - cornerLen),
        Offset(0, size.height),
        Offset(cornerLen, size.height)
      ],
      // Bottom-right
      [
        Offset(size.width - cornerLen, size.height),
        Offset(size.width, size.height),
        Offset(size.width, size.height - cornerLen)
      ],
    ];

    for (final pts in corners) {
      final path = Path()
        ..moveTo(pts[0].dx, pts[0].dy)
        ..lineTo(pts[1].dx, pts[1].dy)
        ..lineTo(pts[2].dx, pts[2].dy);
      canvas.drawPath(path, paint);
    }
  }

  @override
  bool shouldRepaint(_DashedRectPainter old) => old.color != color;
}

class _BottomPanel extends StatelessWidget {
  final EmployeeScanState scanState;
  final VoidCallback onCapture;
  final VoidCallback onReset;

  const _BottomPanel({
    required this.scanState,
    required this.onCapture,
    required this.onReset,
  });

  @override
  Widget build(BuildContext context) {
    final instruction = scanState.currentSampleIndex <
            EmployeeProfiler.instructions.length
        ? EmployeeProfiler.instructions[scanState.currentSampleIndex]
        : null;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withOpacity(0.85), Colors.transparent],
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Emoji grande + instrucción
            if (instruction != null) ...[
              Text(
                instruction.emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 8),
              Text(
                instruction.text,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 12),
            ],

            // Barra de progreso
            LinearProgressIndicator(
              value: scanState.capturedCount / EmployeeProfiler.samplesRequired,
              backgroundColor: Colors.white24,
              color: AppColors.primary,
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
            const SizedBox(height: 8),

            // Checks de muestras
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(
                EmployeeProfiler.samplesRequired,
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Icon(
                    scanState.completedSamples[i]
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: scanState.completedSamples[i]
                        ? Colors.green
                        : Colors.white38,
                    size: 22,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),

            // Feedback
            Text(
              scanState.feedback,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: _feedbackColor(scanState.frameStatus),
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 14),

            // Botón capturar
            if (!scanState.isComplete)
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: scanState.frameStatus == _FrameStatus.detected &&
                          !scanState.isCapturing
                      ? onCapture
                      : null,
                  icon: scanState.isCapturing
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.camera_alt),
                  label: const Text(
                    'Capturar esta posición',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    backgroundColor: AppColors.primary,
                  ),
                ),
              )
            else
              Column(
                children: [
                  const Text(
                    '¡Escaneo completado! Iniciando monitoreo...',
                    style: TextStyle(
                      color: Colors.greenAccent,
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: onReset,
                    child: const Text(
                      'Repetir escaneo',
                      style: TextStyle(color: Colors.white54),
                    ),
                  ),
                ],
              ),

            // Error de guardado
            if (scanState.error != null) ...[
              const SizedBox(height: 8),
              Text(
                scanState.error!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.redAccent, fontSize: 12),
              ),
              TextButton(
                onPressed: onReset,
                child: const Text(
                  'Intentar de nuevo',
                  style: TextStyle(color: Colors.white70),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _feedbackColor(_FrameStatus status) {
    switch (status) {
      case _FrameStatus.detected:
        return Colors.greenAccent;
      case _FrameStatus.error:
        return Colors.redAccent;
      case _FrameStatus.capturing:
        return Colors.lightBlueAccent;
      case _FrameStatus.searching:
        return Colors.white70;
    }
  }
}
