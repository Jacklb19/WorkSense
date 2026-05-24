import 'dart:convert';
import 'dart:math' as math;

import 'package:worksense_app/core/constants/ai_thresholds.dart';
import 'package:worksense_app/features/camera_monitor/ai/body_signature.dart';

class BiometricSampleMetadata {
  final double qualityScore;
  final double yaw;
  final double pitch;
  final DateTime capturedAt;

  const BiometricSampleMetadata({
    required this.qualityScore,
    required this.yaw,
    required this.pitch,
    required this.capturedAt,
  });

  Map<String, dynamic> toJson() => {
        'qualityScore': qualityScore,
        'yaw': yaw,
        'pitch': pitch,
        'capturedAt': capturedAt.millisecondsSinceEpoch,
      };

  factory BiometricSampleMetadata.fromJson(Map<String, dynamic> json) {
    return BiometricSampleMetadata(
      qualityScore: (json['qualityScore'] as num?)?.toDouble() ?? 0.0,
      yaw: (json['yaw'] as num?)?.toDouble() ?? 0.0,
      pitch: (json['pitch'] as num?)?.toDouble() ?? 0.0,
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        json['capturedAt'] as int? ?? 0,
      ),
    );
  }
}

/// Perfil biometrico completo del empleado.
/// Contiene multiples muestras faciales de enrolamiento y una firma corporal.
class EmployeeProfile {
  final String employeeId;
  final String workstationId;
  final List<List<double>> faceEmbeddings;
  final BodySignature bodySignature;
  final DateTime capturedAt;
  final int sampleCount;
  final int version;
  final int profileSchemaVersion;
  final String embeddingModelVersion;
  final DateTime? lastReenrollmentAt;
  final List<BiometricSampleMetadata> sampleMetadata;

  static const int currentVersion = 1;
  static const int currentProfileSchemaVersion = 2;
  static const String currentEmbeddingModelVersion = 'mobile_face_net_v1';
  static const double identityThreshold = AiThresholds.minEmbeddingMatchScore;

  const EmployeeProfile({
    required this.employeeId,
    required this.workstationId,
    required this.faceEmbeddings,
    required this.bodySignature,
    required this.capturedAt,
    required this.sampleCount,
    this.version = currentVersion,
    this.profileSchemaVersion = currentProfileSchemaVersion,
    this.embeddingModelVersion = currentEmbeddingModelVersion,
    this.lastReenrollmentAt,
    this.sampleMetadata = const [],
  });

  double matchScore({double? faceScore, double? bodyScore}) {
    if (faceScore != null && bodyScore != null) {
      return faceScore * 0.95 + bodyScore * 0.05;
    } else if (faceScore != null) {
      return faceScore;
    } else if (bodyScore != null) {
      return bodyScore * 0.30;
    }
    return 0.0;
  }

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
      profileSchemaVersion: profileSchemaVersion,
      embeddingModelVersion: embeddingModelVersion,
      lastReenrollmentAt: lastReenrollmentAt,
      sampleMetadata: sampleMetadata,
    );
  }

  Map<String, dynamic> toJson() => {
        'employeeId': employeeId,
        'workstationId': workstationId,
        'faceEmbedding': faceEmbeddings,
        'bodySignature': bodySignature.toJson(),
        'capturedAt': capturedAt.millisecondsSinceEpoch,
        'sampleCount': sampleCount,
        'version': version,
        'profileSchemaVersion': profileSchemaVersion,
        'embeddingModelVersion': embeddingModelVersion,
        'lastReenrollmentAt': lastReenrollmentAt?.millisecondsSinceEpoch,
        'sampleMetadata': sampleMetadata.map((entry) => entry.toJson()).toList(),
      };

  factory EmployeeProfile.fromJson(Map<String, dynamic> json) {
    final dynamic embeddingRaw = json['faceEmbedding'];
    List<List<double>> parsedEmbeddings = [];
    if (embeddingRaw is List) {
      if (embeddingRaw.isNotEmpty && embeddingRaw.first is num) {
        parsedEmbeddings = [
          embeddingRaw.map((e) => (e as num).toDouble()).toList(),
        ];
      } else {
        parsedEmbeddings = embeddingRaw.map((e) {
          final list = e as List;
          return list.map((v) => (v as num).toDouble()).toList();
        }).toList();
      }
    }

    final bodyJson = json['bodySignature'] as Map<String, dynamic>;
    final metadataRaw = json['sampleMetadata'] as List<dynamic>? ?? const [];

    return EmployeeProfile(
      employeeId: json['employeeId'] as String,
      workstationId: json['workstationId'] as String,
      faceEmbeddings: parsedEmbeddings,
      bodySignature: BodySignature.fromJson(
        bodyJson.map((k, v) => MapEntry(k, (v as num).toDouble())),
      ),
      capturedAt: DateTime.fromMillisecondsSinceEpoch(
        json['capturedAt'] as int,
      ),
      sampleCount: json['sampleCount'] as int,
      version: json['version'] as int? ?? currentVersion,
      profileSchemaVersion:
          json['profileSchemaVersion'] as int? ?? currentProfileSchemaVersion,
      embeddingModelVersion: json['embeddingModelVersion'] as String? ??
          currentEmbeddingModelVersion,
      lastReenrollmentAt: json['lastReenrollmentAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(
              json['lastReenrollmentAt'] as int,
            )
          : null,
      sampleMetadata: metadataRaw
          .whereType<Map<String, dynamic>>()
          .map(BiometricSampleMetadata.fromJson)
          .toList(),
    );
  }

  String toJsonString() => jsonEncode(toJson());

  factory EmployeeProfile.fromJsonString(String s) =>
      EmployeeProfile.fromJson(jsonDecode(s) as Map<String, dynamic>);

  static double cosineSimilarity(List<double> a, List<double> b) {
    if (a.isEmpty || b.isEmpty || a.length != b.length) return 0.0;
    double dot = 0;
    double normA = 0;
    double normB = 0;
    for (int i = 0; i < a.length; i++) {
      dot += a[i] * b[i];
      normA += a[i] * a[i];
      normB += b[i] * b[i];
    }
    if (normA == 0 || normB == 0) return 0.0;
    return dot / (math.sqrt(normA) * math.sqrt(normB));
  }

  static List<double> normalizeVector(List<double> v) {
    final magnitude = math.sqrt(v.fold(0.0, (sum, e) => sum + e * e));
    if (magnitude == 0) return v;
    return v.map((e) => e / magnitude).toList();
  }
}
