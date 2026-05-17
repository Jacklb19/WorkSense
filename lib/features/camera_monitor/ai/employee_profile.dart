import 'dart:convert';
import 'dart:math' as math;

import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';

/// Perfil biométrico completo del empleado.
/// Contiene múltiples muestras faciales de enrolamiento y una firma corporal.
class EmployeeProfile {
  final String employeeId;
  final String workstationId;

  /// Lista de embeddings capturados durante el enrolamiento (múltiples muestras).
  final List<List<double>> faceEmbeddings;

  /// Firma corporal promediada de las capturas.
  final BodySignature bodySignature;

  final DateTime capturedAt;
  final int sampleCount;
  final int version;

  static const int currentVersion = 1;
  static const double identityThreshold = AiThresholds.minEmbeddingMatchScore;

  const EmployeeProfile({
    required this.employeeId,
    required this.workstationId,
    required this.faceEmbeddings,
    required this.bodySignature,
    required this.capturedAt,
    required this.sampleCount,
    this.version = currentVersion,
  });

  /// Calcula el score de identidad combinando cara y cuerpo con pesos distintos.
  double matchScore({double? faceScore, double? bodyScore}) {
    print('[MATCH] faceScore: , bodyScore: ');
    if (faceScore != null && bodyScore != null) {
      return faceScore * 0.95 + bodyScore * 0.05;
    } else if (faceScore != null) {
      return faceScore;
    } else if (bodyScore != null) {
      return bodyScore * 0.30;
    }
    return 0.0;
  }

  /// Retorna un nuevo perfil con firmas corporales actualizadas.
  /// NOTA: La actualización continua de los embeddings faciales (ej. EMA)
  /// no se mezcla en esta fase de múltiples muestras estáticas.
  EmployeeProfile adaptedWith({
    required List<double> liveFaceEmbedding,
    BodySignature? liveBodySignature,
    double alpha = 0.95,
  }) {
    return EmployeeProfile(
      employeeId: employeeId,
      workstationId: workstationId,
      faceEmbeddings: faceEmbeddings,
      bodySignature: liveBodySignature != null
          ? bodySignature.adaptedWith(liveBodySignature)
          : bodySignature,
      capturedAt: capturedAt,
      sampleCount: sampleCount + 1,
      version: version,
    );
  }

  // ── Serialización ──────────────────────────────────────────────────────────

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'workstationId': workstationId,
        'faceEmbedding': faceEmbeddings, // Clave original por retrocompatibilidad
        'bodySignature': bodySignature.toJson(),
        'capturedAt': capturedAt.millisecondsSinceEpoch,
        'sampleCount': sampleCount,
        'version': version,
      };

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    final dynamic embeddingRaw = json['faceEmbedding'];
    List<List<double>> parsedEmbeddings = [];
    if (embeddingRaw is List) {
      if (embeddingRaw.isNotEmpty && embeddingRaw.first is num) {
        parsedEmbeddings = [embeddingRaw.map((e) => (e as num).toDouble()).toList()];
      } else {
        parsedEmbeddings = embeddingRaw.map((e) {
          final list = e as List;
          return list.map((v) => (v as num).toDouble()).toList();
        }).toList();
      }
    }

    final bodyJson = json['bodySignature'] as Map<String, dynamic>;
    return EmployeeProfile(
      employeeId: json['employeeId'] as String,
      workstationId: json['workstationId'] as String,
      faceEmbeddings: parsedEmbeddings,
      bodySignature: BodySignature.fromJson(
        bodyJson.map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      capturedAt: DateTime.fromMillisecondsSinceEpoch(json['capturedAt'] as int),
      sampleCount: json['sampleCount'] as int,
      version: json['version'] as int? ?? currentVersion,
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory EmployeeProfile.fromJsonString(String s) =>
      EmployeeProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);

  // ── Similitud coseno entre embeddings faciales ─────────────────────────────

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    double dot = 0, normA = 0, normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  /// Normaliza un vector a magnitud 1.0.
  static List<double> normalizeVector(List<double> v) {
    final magnitude = math.sqrt(v.fold(0.0, (sum, e) => sum + e * e));
    if (magnitude == 0) return v;
    return v.map((e) => e / magnitude).toList();
  }
}
