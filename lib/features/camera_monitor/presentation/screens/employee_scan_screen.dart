  import 'dart:io' show Platform;

  import 'package:camera/camera.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';
  import 'package:flutter_riverpod/flutter_riverpod.dart';
  import 'package:screen_brightness/screen_brightness.dart';
  import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
  import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
  import 'package:worksense_app/core/constants/ai_thresholds.dart';
  import 'package:worksense_app/core/theme/app_colors.dart';
  import 'package:worksense_app/domain/repositories/employee_repository.dart';
  import 'package:worksense_app/features/camera_monitor/ai/employee_profiler.dart';
  import 'package:worksense_app/features/camera_monitor/ai/face_analyzer.dart';
  import 'package:worksense_app/features/camera_monitor/ai/face_embedding_service.dart';
  import 'package:worksense_app/features/camera_monitor/presentation/providers/kiosk_provider.dart';
  import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';


  // ── Estado del escaneo ─────────────────────────────────────────────────────────

  enum FrameStatus { searching, detected, error, capturing }

  class EmployeeScanState {
    final int currentSampleIndex;
    final List<bool> completedSamples;
    final FrameStatus frameStatus;
    final String feedback;
    final bool isCapturing;
    final bool isComplete;
    final String? error;
    final bool cameraReady;
    final bool isIlluminating;
    final int burstProgress;
    final int burstTotal;

    EmployeeScanState({
      this.currentSampleIndex = 0,
      List<bool>? completedSamples,
      this.frameStatus = FrameStatus.searching,
      this.feedback = 'Posiciónate frente a la cámara',
      this.isCapturing = false,
      this.isComplete = false,
      this.error,
      this.cameraReady = false,
      this.isIlluminating = false,
      this.burstProgress = 0,
      this.burstTotal = AiThresholds.scanBurstFrames,
    }) : completedSamples = completedSamples ?? List.filled(EmployeeProfiler.samplesRequired, false);

    int get capturedCount => completedSamples.where((s) => s).length;

    EmployeeScanState copyWith({
      int? currentSampleIndex,
      List<bool>? completedSamples,
      FrameStatus? frameStatus,
      String? feedback,
      bool? isCapturing,
      bool? isComplete,
      String? error,
      bool? cameraReady,
      bool? isIlluminating,
      int? burstProgress,
      int? burstTotal,
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
        isIlluminating: isIlluminating ?? this.isIlluminating,
        burstProgress: burstProgress ?? this.burstProgress,
        burstTotal: burstTotal ?? this.burstTotal,
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
    late final FaceAnalyzer _faceAnalyzer;
    late final FaceDetector _liveDetector;
    late final PoseDetector _livePoseDetector;

    bool _isLiveProcessing = false;
    bool _disposed = false;
    bool _blockFrameUpdates = false;
    bool _blinkSatisfied = false;
    bool _blinkArmed = false;
    int _openEyesStableFrames = 0;
    int _livenessSampleIndex = 0;
    int _stableLiveFrames = 0;
    CameraImage? _lastFrame;
    DateTime _lastQualityCheckTime = DateTime.fromMillisecondsSinceEpoch(0);
    bool _isCheckingQuality = false;

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
          super(EmployeeScanState()) {
      _faceAnalyzer = FaceAnalyzer();
      _profiler = EmployeeProfiler(
        faceAnalyzer: _faceAnalyzer,
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
      if (_disposed) return;
      _lastFrame = image;
      if (_blockFrameUpdates) return;
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
        if (_disposed || _blockFrameUpdates || state.isCapturing) return;
        _syncLivenessState();

        if (faces.isEmpty) {
          _resetBlinkState();
          _stableLiveFrames = 0;
          state = state.copyWith(
            frameStatus: FrameStatus.searching,
            feedback: 'Centra tu rostro',
          );
        } else if (faces.length > 1) {
          _resetBlinkState();
          _stableLiveFrames = 0;
          state = state.copyWith(
            frameStatus: FrameStatus.error,
            feedback: 'Solo debe estar el empleado en cámara',
          );
        } else if (poses.isEmpty) {
          _resetBlinkState();
          _stableLiveFrames = 0;
          state = state.copyWith(
            frameStatus: FrameStatus.searching,
            feedback: 'Asegúrate de que tu cuerpo sea visible',
          );
        } else {
          if (!state.isCapturing && (state.frameStatus != FrameStatus.capturing)) {
            final face = faces.first;
            final isCorrectPos = _profiler.isPositionStateCorrect(face);
            final passesLivePresence = _passesLivePresenceGate(
              face,
              inputImage.metadata?.size,
              inputImage.metadata?.rotation,
            );
            
            if (isCorrectPos && passesLivePresence) {
              // [PERFORMANCE] Throttling + Lock: Máximo 1 validación cada 400ms y sin solapamiento
              final now = DateTime.now();
              if (!_isCheckingQuality && now.difference(_lastQualityCheckTime).inMilliseconds >= 400) {
                _isCheckingQuality = true;
                _lastQualityCheckTime = now;
                
                try {
                  final cropped = await _faceAnalyzer.cropFaceFromCameraImageAsync(image, face);
                  if (cropped != null) {
                    final quality = await _faceAnalyzer.assessCropQuality(cropped);
                    if (quality.overallScore < AiThresholds.enrollMinCropQuality) {
                      _stableLiveFrames = 0;
                      if (!_disposed) {
                        state = state.copyWith(
                          frameStatus: FrameStatus.error,
                          feedback: 'Mejora la iluminación o tu posición',
                        );
                      }
                      _isCheckingQuality = false;
                      return;
                    }
                  }
                } catch (_) {
                  // Ignore ML Kit errors on frame dropping
                } finally {
                  _isCheckingQuality = false;
                }
              }

              _stableLiveFrames++;
              if (_requiresBlinkChallenge) {
                _updateBlinkChallenge(face);
                if (!_blinkSatisfied) {
                  state = state.copyWith(
                    frameStatus: FrameStatus.searching,
                    feedback: _blinkArmed
                        ? 'Parpadea una vez para validar presencia'
                        : 'Mira al frente con los ojos abiertos',
                  );
                  return;
                }
              }
              if (_stableLiveFrames < AiThresholds.liveDetectionStableFrames) {
                state = state.copyWith(
                  frameStatus: FrameStatus.searching,
                  feedback: 'Sostente frente a la camara un momento',
                );
                return;
              }
              state = state.copyWith(
                frameStatus: FrameStatus.detected,
                feedback: 'Posición correcta',
              );
            } else {
              if (_requiresBlinkChallenge) {
                _resetBlinkState();
              }
              _stableLiveFrames = 0;
              state = state.copyWith(
                frameStatus: FrameStatus.searching,
                feedback: passesLivePresence
                    ? _getGuidanceMessage(state.currentSampleIndex)
                    : 'Centra mejor el rostro dentro del marco',
              );
            }
          }
        }
      } catch (_) {}
    }

    String _getGuidanceMessage(int index) {
      switch (index) {
        case 0: return 'Mira directo a la cámara';
        case 1: return 'Gira levemente la cabeza a tu derecha';
        case 2: return 'Gira levemente la cabeza a tu izquierda';
        case 3: return 'Inclina levemente la cabeza hacia abajo';
        case 4: return 'Levanta levemente la cabeza';
        case 5: return 'De frente otra vez para confirmar';
        case 6: return 'Gira levemente la cabeza a tu derecha otra vez';
        case 7: return 'Gira levemente la cabeza a tu izquierda otra vez';
        default: return 'Ajusta tu posición';
      }
    }

    Future<void> captureCurrentSample() async {
      if (_disposed) return;
      if (state.isCapturing || _lastFrame == null) return;
      if (state.frameStatus != FrameStatus.detected) return;

      try {
        _blockFrameUpdates = true;
        state = state.copyWith(
          isCapturing: true,
          frameStatus: FrameStatus.capturing,
          isIlluminating: true,
          burstProgress: 0,
          burstTotal: AiThresholds.scanBurstFrames,
          feedback: 'Capturando rafaga biometrica',
        );

        await Future<void>.delayed(
          const Duration(milliseconds: AiThresholds.scanBurstDelayMs),
        );

        SampleAssessment? bestAssessment;
        String lastFeedback = 'No se pudo capturar una muestra estable';

        for (int i = 0; i < AiThresholds.scanBurstFrames; i++) {
          final frame = _lastFrame;
          if (frame == null) continue;

          final inputImage = _buildInputImage(frame);
          if (inputImage == null) {
            lastFeedback = 'Error al procesar el frame';
            continue;
          }

          final assessment = await _profiler.assessSample(inputImage, frame);
          lastFeedback = assessment.feedback;

          if (assessment.isSuccess) {
            if (bestAssessment == null ||
                assessment.sample!.qualityScore >
                    bestAssessment.sample!.qualityScore) {
              bestAssessment = assessment;
            }
          }

          if (!_disposed) {
            state = state.copyWith(burstProgress: i + 1);
          }

          if (i < AiThresholds.scanBurstFrames - 1) {
            await Future<void>.delayed(
              const Duration(milliseconds: AiThresholds.scanBurstDelayMs),
            );
          }
        }

        if (bestAssessment != null && bestAssessment.isSuccess) {
          _profiler.commitAssessedSample(bestAssessment.sample!);
          final newCompleted = List<bool>.from(state.completedSamples);
          newCompleted[state.currentSampleIndex] = true;

          final nextIndex = state.currentSampleIndex + 1;
          final isComplete = nextIndex >= EmployeeProfiler.samplesRequired;

          state = state.copyWith(
            completedSamples: newCompleted,
            currentSampleIndex: isComplete ? state.currentSampleIndex : nextIndex,
            isCapturing: false,
            isComplete: isComplete,
            isIlluminating: false,
            frameStatus: FrameStatus.searching,
            burstProgress: 0,
            feedback: 'Buena captura ✓',
          );
          _syncLivenessState(forceReset: true);

          if (!isComplete) {
            await Future<void>.delayed(const Duration(milliseconds: 800));
            if (!_disposed) {
              state = state.copyWith(
                feedback: EmployeeProfiler.instructions[nextIndex].text,
              );
            }
          } else {
            state = state.copyWith(feedback: 'Escaneo completado');
            await _buildAndSaveProfile();
          }
        } else {
          state = state.copyWith(
            isCapturing: false,
            isIlluminating: false,
            frameStatus: FrameStatus.error,
            burstProgress: 0,
            feedback: lastFeedback,
          );
          await Future<void>.delayed(const Duration(milliseconds: 1200));
        }
      } catch (e) {
        if (_disposed) return;
        state = state.copyWith(
          isCapturing: false,
          isIlluminating: false,
          burstProgress: 0,
          error: e.toString(),
        );
      } finally {
        _blockFrameUpdates = false;
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
          faceEmbeddings: profile.faceEmbeddings,
          bodySignature: profile.bodySignature,
          profile: profile,
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
      _resetBlinkState();
      _stableLiveFrames = 0;
      _livenessSampleIndex = 0;
      state = EmployeeScanState(cameraReady: true);
    }

    bool get _requiresBlinkChallenge => state.currentSampleIndex == 0;

    bool _passesLivePresenceGate(Face face, Size? frameSize, InputImageRotation? rotation) {
      if (frameSize == null) return false;

      double fWidth = frameSize.width;
      double fHeight = frameSize.height;

      if (rotation == InputImageRotation.rotation90deg || rotation == InputImageRotation.rotation270deg) {
        fWidth = frameSize.height;
        fHeight = frameSize.width;
      }

      final box = face.boundingBox;
      final frameArea = fWidth * fHeight;
      if (frameArea <= 0) return false;

      final areaRatio = (box.width * box.height) / frameArea;
      final centerX = box.left + (box.width / 2);
      final centerY = box.top + (box.height / 2);

      final minX = fWidth * AiThresholds.liveFaceGuideMargin;
      final maxX = fWidth * (1 - AiThresholds.liveFaceGuideMargin);
      final minY = fHeight * AiThresholds.liveFaceGuideMargin;
      final maxY = fHeight * (1 - AiThresholds.liveFaceGuideMargin);

      final centered = centerX >= minX &&
          centerX <= maxX &&
          centerY >= minY &&
          centerY <= maxY;
      
      final fullyVisible = box.left >= -20 &&
          box.top >= -20 &&
          box.right <= fWidth + 20 &&
          box.bottom <= fHeight + 20;

      return areaRatio >= AiThresholds.minLiveFaceAreaRatio &&
          centered &&
          fullyVisible;
    }

    void _syncLivenessState({bool forceReset = false}) {
      final sampleIndex = state.currentSampleIndex;
      if (forceReset || sampleIndex != _livenessSampleIndex) {
        _livenessSampleIndex = sampleIndex;
        _resetBlinkState();
        _stableLiveFrames = 0;
      }
    }

    void _resetBlinkState() {
      _blinkSatisfied = false;
      _blinkArmed = false;
      _openEyesStableFrames = 0;
    }

    void _updateBlinkChallenge(Face face) {
      final leftEye = face.leftEyeOpenProbability;
      final rightEye = face.rightEyeOpenProbability;
      if (leftEye == null || rightEye == null) return;

      final eyesOpen = leftEye >= AiThresholds.minEyeOpenProbability &&
          rightEye >= AiThresholds.minEyeOpenProbability;
      final eyesClosed = leftEye <= AiThresholds.maxEyeClosedProbability &&
          rightEye <= AiThresholds.maxEyeClosedProbability;

      if (eyesOpen) {
        _openEyesStableFrames++;
        if (_openEyesStableFrames >= AiThresholds.blinkOpenFramesRequired) {
          _blinkArmed = true;
        }
        return;
      }

      if (eyesClosed && _blinkArmed) {
        _blinkSatisfied = true;
        return;
      }

      if (!eyesClosed) {
        _openEyesStableFrames = 0;
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

    /// Brillo original guardado antes de activar el screen flash.
    double? _originalBrightness;

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

    /// Maximiza el brillo de pantalla para iluminar el rostro del sujeto.
    Future<void> _activateScreenFlash() async {
      try {
        _originalBrightness = await ScreenBrightness().current;
        await ScreenBrightness().setScreenBrightness(1.0);
      } catch (_) {
        // screen_brightness no disponible — el overlay blanco igual ayuda.
      }
    }

    /// Restaura el brillo al valor guardado antes del flash.
    Future<void> _restoreScreenBrightness() async {
      try {
        final saved = _originalBrightness;
        if (saved != null) {
          _originalBrightness = null;
          await ScreenBrightness().setScreenBrightness(saved);
        }
      } catch (_) {}
    }

    @override
    void dispose() {
      _restoreScreenBrightness(); // Siempre restaurar brillo al salir.
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
          // Give the user 1.2s to see the success state, then:
          // 1. Stop the enrollment camera so the device camera is free.
          // 2. Pop this screen from its own context (not the parent's).
          // 3. Notify the kiosk to re-init (which will start the monitoring camera).
          // Capture context-dependent refs synchronously, before scheduling.
          final nav = Navigator.of(context);
          final notifier = ref.read(employeeScanProvider(_params).notifier);
          final onComplete = widget.onComplete;
          Future.delayed(const Duration(milliseconds: 1200), () async {
            if (!mounted) return;
            await notifier.stopCamera();
            nav.pop();
            onComplete();
          });
        }

        // Screen flash: maximizar brillo al capturar, restaurar al terminar.
        final wasIlluminating = prev?.isIlluminating ?? false;
        if (next.isIlluminating && !wasIlluminating) {
          _activateScreenFlash();
        } else if (!next.isIlluminating && wasIlluminating) {
          _restoreScreenBrightness();
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

            // Screen flash overlay — fade suave al entrar y salir.
            AnimatedOpacity(
              opacity: scanState.isIlluminating ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 120),
              child: const _ScreenFlashOverlay(),
            ),

            // Glassmorphism HUD
            const _HUDOverlay(),

            // Guide Frame
            _GuideFrame(status: scanState.frameStatus),

            // Step instruction card — shown between guide frame and bottom HUD
            if (!scanState.isComplete)
              Positioned(
                bottom: 240,
                left: 32,
                right: 32,
                child: _StepInstructionCard(
                  currentIndex: scanState.currentSampleIndex,
                  frameStatus: scanState.frameStatus,
                ),
              ),

            // Top Info
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: _TopHUD(
                current: scanState.capturedCount,
                total: EmployeeProfiler.samplesRequired,
                completedSamples: scanState.completedSamples,
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
                Colors.black.withValues(alpha: 0.2),
                Colors.black.withValues(alpha: 0.6),
              ],
              stops: const [0.5, 0.8, 1.0],
            ),
          ),
        ),
      );
    }
  }

  /// Overlay blanco sólido que funciona como flash de cámara frontal.
  ///
  /// Combinado con [ScreenBrightness] al máximo, convierte la pantalla en
  /// una fuente de luz de alta intensidad — la misma técnica de Instagram,
  /// Snapchat y WhatsApp para selfies con flash.
  ///
  /// Siempre está en el árbol; la visibilidad la controla [AnimatedOpacity]
  /// en el padre para transiciones suaves sin mount/unmount.
  class _ScreenFlashOverlay extends StatelessWidget {
    const _ScreenFlashOverlay();

    @override
    Widget build(BuildContext context) {
      return const IgnorePointer(
        child: ColoredBox(color: Colors.white),
      );
    }
  }

  class _TopHUD extends StatelessWidget {
    final int current;
    final int total;
    final List<bool> completedSamples;
    const _TopHUD({required this.current, required this.total, required this.completedSamples});

    @override
    Widget build(BuildContext context) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.black.withValues(alpha: 0.8), Colors.transparent],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'ENROLAMIENTO BIOMÉTRICO',
                    style: TextStyle(
                      color: AppColors.primaryLight,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 2.0,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              // Sample progress dots
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(total, (i) {
                    final done = i < completedSamples.length && completedSamples[i];
                    final active = i == current && !done;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 20 : 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: done
                            ? AppColors.feedbackDetected
                            : active
                                ? AppColors.primaryLight
                                : Colors.white24,
                        borderRadius: BorderRadius.circular(5),
                      ),
                    );
                  }),
                ),
              ),
              const SizedBox(height: 4),
              Center(
                child: Text(
                  'Muestra $current de $total',
                  style: const TextStyle(color: AppColors.textOnCamera38, fontSize: 11),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  // ── Step Instruction Card ──────────────────────────────────────────────────────

  class _StepInstructionCard extends StatelessWidget {
    final int currentIndex;
    final FrameStatus frameStatus;

    const _StepInstructionCard({
      required this.currentIndex,
      required this.frameStatus,
    });

    @override
    Widget build(BuildContext context) {
      if (currentIndex >= EmployeeProfiler.instructions.length) return const SizedBox.shrink();
      final instr = EmployeeProfiler.instructions[currentIndex];
      final isDetected = frameStatus == FrameStatus.detected;
      final isCapturing = frameStatus == FrameStatus.capturing;

      return AnimatedContainer(
        duration: const Duration(milliseconds: 250),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: isDetected
              ? AppColors.feedbackDetected.withValues(alpha: 0.15)
              : Colors.black.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDetected
                ? AppColors.feedbackDetected.withValues(alpha: 0.5)
                : Colors.white12,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(instr.emoji, style: const TextStyle(fontSize: 22)),
            const SizedBox(width: 12),
            Flexible(
              child: Text(
                isCapturing ? 'Capturando…' : instr.text,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: isDetected ? AppColors.feedbackDetected : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            if (isDetected) ...[
              const SizedBox(width: 12),
              const Icon(Icons.check_circle, color: AppColors.feedbackDetected, size: 20),
            ],
          ],
        ),
      );
    }
  }

  class _GuideFrame extends StatelessWidget {
    final FrameStatus status;
    const _GuideFrame({required this.status});

    Color get _color {
      switch (status) {
        case FrameStatus.searching: return AppColors.textOnCamera38;
        case FrameStatus.detected: return AppColors.feedbackDetected;
        case FrameStatus.error: return AppColors.feedbackError;
        case FrameStatus.capturing: return AppColors.feedbackCapturing;
      }
    }

    @override
    Widget build(BuildContext context) {
      final size = MediaQuery.sizeOf(context);
      final frameW = size.width * 0.75;
      final frameH = size.height * 0.45;

      return Center(
        child: Container(
          width: frameW,
          height: frameH,
          decoration: BoxDecoration(
            border: Border.all(color: _color.withValues(alpha: 0.5), width: 1),
            borderRadius: BorderRadius.circular(32),
          ),
          child: Stack(
            children: [
              _CornerIndicator(color: _color, top: 0, left: 0),
              _CornerIndicator(color: _color, top: 0, right: 0),
              _CornerIndicator(color: _color, bottom: 0, left: 0),
              _CornerIndicator(color: _color, bottom: 0, right: 0),
              
              if (status == FrameStatus.capturing)
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
      final bool canCapture = state.frameStatus == FrameStatus.detected && !state.isCapturing;

      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 32),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.bottomCenter,
            end: Alignment.topCenter,
            colors: [Colors.black.withValues(alpha: 0.9), Colors.transparent],
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
              if (state.isCapturing) ...[
                const SizedBox(height: 12),
                Text(
                  'RAFAGA ${state.burstProgress}/${state.burstTotal}',
                  style: const TextStyle(
                    color: AppColors.textOnCamera70,
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.2,
                  ),
                ),
              ],
              const SizedBox(height: 24),

              // Capture Button
              if (!state.isComplete)
                Material(
                  color: Colors.transparent,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: canCapture ? onCapture : null,
                    customBorder: const CircleBorder(),
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
                        color: canCapture
                            ? AppColors.primary.withValues(alpha: 0.2)
                            : Colors.transparent,
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
                                  child: CircularProgressIndicator(
                                      strokeWidth: 3, color: AppColors.primary),
                                )
                              : Icon(
                                  Icons.fingerprint,
                                  color: canCapture
                                      ? AppColors.primary
                                      : Colors.white24,
                                  size: 32),
                        ),
                      ),
                    ),
                  ),
                )
              else
                const Icon(Icons.check_circle, color: AppColors.success, size: 80),

              const SizedBox(height: 16),
            ],
          ),
        ),
      );
    }

    Color _getStatusColor(FrameStatus status) {
      switch (status) {
        case FrameStatus.detected: return AppColors.feedbackDetected;
        case FrameStatus.error: return AppColors.feedbackError;
        default: return AppColors.textOnCamera70;
      }
    }
  }
