import 'dart:math' as math;
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
      print('[FaceEmbeddingService] MobileFaceNet inicializado.');
    } catch (e) {
      print('[FaceEmbeddingService] Límite de carga: $e');
      rethrow;
    }
  }

  /// Genera y devuelve un embedding espacial de AiThresholds.embeddingDimension dimensiones.
  List<double> generateEmbedding(img.Image croppedFace) {
    if (!_isInitialized || _interpreter == null) {
      throw Exception('FaceEmbeddingService no ha sido inicializado.');
    }

    // 1. Resize estricto
    final resizedImage = img.copyResize(
      croppedFace, 
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
    return List.generate(
      1,
      (i) => List.generate(
        AiThresholds.faceInputSize,
        (y) => List.generate(
          AiThresholds.faceInputSize,
          (x) {
            final pixel = resizedImage.getPixel(x, y);
            return [
              (pixel.r - AiThresholds.faceColorMean) / AiThresholds.faceColorStd, // Canal R
              (pixel.g - AiThresholds.faceColorMean) / AiThresholds.faceColorStd, // Canal G
              (pixel.b - AiThresholds.faceColorMean) / AiThresholds.faceColorStd, // Canal B
            ];
          },
        ),
      ),
    );
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

  /// Libera los recursos C/C++ del intérprete de TFLite
  void dispose() {
    print('[FaceEmbeddingService] Liberando modelo MobileFaceNet.');
    _interpreter?.close();
    _interpreter = null;
    _isInitialized = false;
  }
}
