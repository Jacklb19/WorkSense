import 'dart:convert';
import 'dart:math' as math;

import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';

/// Perfil biométrico completo del empleado.
/// Combina embedding facial promedio + firma corporal promediada de 5 muestras.
class EmployeeProfile {
  final String employeeId;
  final String workstationId;

  /// Vector facial promediado y normalizado de 5 capturas.
  final List<double> faceEmbedding;

  /// Firma corporal promediada de 5 capturas.
  final BodySignature bodySignature;

  final DateTime capturedAt;
  final int sampleCount;
  final int version;

  static const int currentVersion = 1;
  // Threshold reducido para kiosko de empleado único (0.42).
  // Revisar si se implementa multi-empleado por estación.
  static const double identityThreshold = 0.42;

  const EmployeeProfile({
    required this.employeeId,
    required this.workstationId,
    required this.faceEmbedding,
    required this.bodySignature,
    required this.capturedAt,
    required this.sampleCount,
    this.version = currentVersion,
  });

  /// Calcula el score de identidad combinando cara y cuerpo con pesos distintos.
  /// [faceScore] null si la cara no fue visible en el frame.
  /// [bodyScore] null si la pose no fue detectable en el frame.
  double matchScore({double? faceScore, double? bodyScore}) {
    print('[MATCH] faceScore: $faceScore, bodyScore: $bodyScore');
    if (faceScore != null && bodyScore != null) {
      return faceScore * 0.70 + bodyScore * 0.30;
    } else if (faceScore != null) {
      return faceScore; // Sin penalización si solo hay cara
    } else if (bodyScore != null) {
      return bodyScore; // Sin penalización si solo hay pose
    }
    return 0.0;
  }

  /// Retorna un nuevo perfil con embeddings actualizados por EMA.
  /// Solo llamar cuando la confianza de identificación sea >= 0.85.
  /// [alpha] = 0.95 → ~14 frames de alta confianza para que el nuevo dato pese 50%.
  EmployeeProfile adaptedWith({
    required List<double> liveFaceEmbedding,
    BodySignature? liveBodySignature,
    double alpha = 0.95,
  }) {
    if (liveFaceEmbedding.isEmpty ||
        liveFaceEmbedding.length != faceEmbedding.length) {
      return this;
    }

    final newEmb = List<double>.generate(
      faceEmbedding.length,
      (i) => alpha * faceEmbedding[i] + (1 - alpha) * liveFaceEmbedding[i],
    );

    return EmployeeProfile(
      employeeId: employeeId,
      workstationId: workstationId,
      faceEmbedding: normalizeVector(newEmb),
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
        'faceEmbedding': faceEmbedding,
        'bodySignature': bodySignature.toJson(),
        'capturedAt': capturedAt.millisecondsSinceEpoch,
        'sampleCount': sampleCount,
        'version': version,
      };

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    final embeddingRaw = json['faceEmbedding'] as List<dynamic>;
    final bodyJson = json['bodySignature'] as Map<String, dynamic>;
    return EmployeeProfile(
      employeeId: json['employeeId'] as String,
      workstationId: json['workstationId'] as String,
      faceEmbedding: embeddingRaw.map((e) => (e as num).toDouble()).toList(),
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
