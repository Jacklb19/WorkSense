import 'dart:async';
import 'dart:io' show Platform;
import 'dart:ui' show Size;

import 'package:camera/camera.dart';
import 'package:flutter/services.dart' show DeviceOrientation;
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:worksense_app/features/employees/presentation/providers/employees_provider.dart';

class EntranceKioskState {
  final bool cameraInitialized;
  final String? error;
  final bool isScanning;
  final bool faceDetected;
  final String? identifiedEmployeeId;
  final String? identifiedEmployeeName;
  final String statusMessage;

  const EntranceKioskState({
    this.cameraInitialized = false,
    this.error,
    this.isScanning = true,
    this.faceDetected = false,
    this.identifiedEmployeeId,
    this.identifiedEmployeeName,
    this.statusMessage = 'Buscando empleado...',
  });

  EntranceKioskState copyWith({
    bool? cameraInitialized,
    String? error,
    bool? isScanning,
    bool? faceDetected,
    String? identifiedEmployeeId,
    String? identifiedEmployeeName,
    String? statusMessage,
  }) {
    return EntranceKioskState(
      cameraInitialized: cameraInitialized ?? this.cameraInitialized,
      error: error,
      isScanning: isScanning ?? this.isScanning,
      faceDetected: faceDetected ?? this.faceDetected,
      identifiedEmployeeId: identifiedEmployeeId ?? this.identifiedEmployeeId,
      identifiedEmployeeName: identifiedEmployeeName ?? this.identifiedEmployeeName,
      statusMessage: statusMessage ?? this.statusMessage,
    );
  }
}

class EntranceKioskNotifier extends StateNotifier<EntranceKioskState> {
  final Ref _ref;
  CameraController? _cameraController;
  late final FaceDetector _faceDetector;

  bool _isProcessing = false;
  DateTime? _faceDetectedSince;
  static const Duration _identificationDelay = Duration(seconds: 2);

  static const Map<DeviceOrientation, int> _orientationMap = {
    DeviceOrientation.portraitUp: 0,
    DeviceOrientation.landscapeLeft: 90,
    DeviceOrientation.portraitDown: 180,
    DeviceOrientation.landscapeRight: 270,
  };

  EntranceKioskNotifier(this._ref) : super(const EntranceKioskState()) {
    _faceDetector = FaceDetector(
      options: FaceDetectorOptions(
        performanceMode: FaceDetectorMode.fast,
        enableTracking: true,
      ),
    );
  }

  CameraController? get cameraController => _cameraController;

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
        error: 'Error al inicializar cámara: $e',
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
    if (_isProcessing || !state.isScanning) return;
    _isProcessing = true;
    _analyzeFrame(image).then((_) {
      _isProcessing = false;
    }).catchError((_) {
      _isProcessing = false;
    });
  }

  Future<void> _analyzeFrame(CameraImage image) async {
    try {
      final inputImage = _buildInputImage(image);
      if (inputImage == null) return;

      final faces = await _faceDetector.processImage(inputImage);

      if (faces.isNotEmpty) {
        if (!state.faceDetected) {
          state = state.copyWith(
            faceDetected: true,
            statusMessage: 'Rostro detectado, analizando...',
          );
          _faceDetectedSince = DateTime.now();
        } else if (_faceDetectedSince != null) {
          final duration = DateTime.now().difference(_faceDetectedSince!);
          if (duration >= _identificationDelay) {
            _identifyEmployee();
          }
        }
      } else {
        if (state.faceDetected) {
          state = state.copyWith(
            faceDetected: false,
            statusMessage: 'Buscando empleado...',
          );
          _faceDetectedSince = null;
        }
      }
    } catch (_) {
      // Ignorar errores de procesamiento de frames
    }
  }

  void _identifyEmployee() async {
    state = state.copyWith(isScanning: false, statusMessage: 'Identificando...');

    // Simulamos un pequeño delay de procesamiento
    await Future.delayed(const Duration(milliseconds: 500));

    final employeesList = _ref.read(employeesStreamProvider).valueOrNull ?? [];
    
    if (employeesList.isNotEmpty) {
      // Mock: seleccionamos un empleado al azar (o el primero)
      final employee = employeesList.first;
      state = state.copyWith(
        identifiedEmployeeId: employee.id,
        identifiedEmployeeName: employee.name,
        statusMessage: '¡Bienvenido, ${employee.name}!',
      );
      
      // Reiniciar después de unos segundos
      Timer(const Duration(seconds: 4), () {
        if (mounted) {
          state = state.copyWith(
            isScanning: true,
            faceDetected: false,
            identifiedEmployeeId: null,
            identifiedEmployeeName: null,
            statusMessage: 'Buscando empleado...',
          );
          _faceDetectedSince = null;
        }
      });
    } else {
      state = state.copyWith(
        statusMessage: 'Empleado no reconocido',
      );
      Timer(const Duration(seconds: 3), () {
        if (mounted) {
          state = state.copyWith(
            isScanning: true,
            faceDetected: false,
            statusMessage: 'Buscando empleado...',
          );
          _faceDetectedSince = null;
        }
      });
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
        rotationCompensation = (sensorOrientation + rotationCompensation) % 360;
      } else {
        rotationCompensation = (sensorOrientation - rotationCompensation + 360) % 360;
      }
      rotation = InputImageRotationValue.fromRawValue(rotationCompensation) ?? InputImageRotation.rotation0deg;
    } else {
      rotation = InputImageRotationValue.fromRawValue(sensorOrientation) ?? InputImageRotation.rotation0deg;
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
    _faceDetector.close();
    super.dispose();
  }
}

final entranceKioskProvider =
    StateNotifierProvider.autoDispose<EntranceKioskNotifier, EntranceKioskState>((ref) {
  return EntranceKioskNotifier(ref);
});
