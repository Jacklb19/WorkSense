import 'dart:math' as math;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image/image.dart' as img;
import 'package:tflite_flutter/tflite_flutter.dart';
import 'package:worksense_app/core/constants/ai_thresholds.dart';

/// Provider que expone el servicio estructural y gestiona su ciclo de vida.
/// Usamos Provider simple para permitir llamadas a initialize() en la capa de pipeline o app_startup.
final faceEmbeddingServiceProvider = Provider<FaceEmbeddingService>((ref) {
  final service = FaceEmbeddingService();
  ref.onDispose(() => service.dispose());
  return service;
});

class FaceEmbeddingService {
  Interpreter? _interpreter;
  bool _isInitialized = false;

  Future<void> initialize() async {
    if (_isInitialized) return;
    try {
      final options = InterpreterOptions()..threads = 2;
      _interpreter = await Interpreter.fromAsset(
        'assets/models/mobile_face_net.tflite',
        options: options,
      );
      _isInitialized = true;
      debugPrint('[FaceEmbeddingService] MobileFaceNet inicializado.');
    } catch (e) {
      debugPrint('[FaceEmbeddingService] Límite de carga: $e');
      rethrow;
    }
  }

  /// Genera y devuelve un embedding espacial de AiThresholds.embeddingDimension dimensiones.
  Future<List<double>> generateEmbedding(img.Image croppedFace) async {
    if (!_isInitialized || _interpreter == null) {
      await initialize();
      if (!_isInitialized || _interpreter == null) {
        throw Exception('El modelo biométrico no pudo ser inicializado o el archivo de TFLite está dañado.');
      }
    }

    final squaredFace = _squarePadFace(croppedFace);

    // 1. Resize estricto
    final resizedImage = img.copyResize(
      squaredFace,
      width: AiThresholds.faceInputSize, 
      height: AiThresholds.faceInputSize,
    );

    // 2. Extracción a tensor pre-procesado
    final input = _toFloatMatrix(resizedImage);

    // 3. Tensor [1, Dimensiones] -> Salida
    var output = List.generate(1, (i) => List.filled(AiThresholds.embeddingDimension, 0.0));
    _interpreter!.run(input, output);

    // 4. L2 Normalization OBLIGATORIA
    return _normalizeL2(output[0]);
  }

  /// Extrae la matriz tridimensional normalizada usando (p - avg) / std
  List<List<List<List<double>>>> _toFloatMatrix(img.Image resizedImage) {
    const int size = AiThresholds.faceInputSize;
    const mean = AiThresholds.faceColorMean;
    const std = AiThresholds.faceColorStd;

    final rows = <List<List<double>>>[];
    for (int y = 0; y < size; y++) {
      final row = <List<double>>[];
      for (int x = 0; x < size; x++) {
        final pixel = resizedImage.getPixel(x, y);
        row.add([
          (pixel.r - mean) / std,
          (pixel.g - mean) / std,
          (pixel.b - mean) / std,
        ]);
      }
      rows.add(row);
    }
    return [rows];
  }

  /// Normaliza el vector en el espacio L2
  List<double> _normalizeL2(List<double> vector) {
    double sumSq = 0.0;
    for (var v in vector) {
      sumSq += v * v;
    }
    final norm = math.sqrt(sumSq);
    if (norm == 0.0) return vector; // Evitar división por cero
    
    return vector.map((v) => v / norm).toList();
  }

  img.Image _squarePadFace(img.Image source) {
    final size = math.max(source.width, source.height);
    final square = img.Image(width: size, height: size);
    img.fill(square, color: img.ColorRgb8(0, 0, 0));
    final offsetX = ((size - source.width) / 2).round();
    final offsetY = ((size - source.height) / 2).round();
    img.compositeImage(square, source, dstX: offsetX, dstY: offsetY);
    return square;
  }

  /// Libera los recursos C/C++ del intérprete de TFLite
  void dispose() {
    debugPrint('[FaceEmbeddingService] Liberando modelo MobileFaceNet.');
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
