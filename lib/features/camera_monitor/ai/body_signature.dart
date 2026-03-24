import 'dart:math' as math;

import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';

/// Firma corporal única del empleado basada en proporciones relativas del esqueleto.
/// Las proporciones son independientes de posición, distancia a la cámara y ropa.
class BodySignature {
  final double shoulderToHipRatio;
  final double torsoToLegRatio;
  final double armSpanRatio;
  final double headToShoulderRatio;
  final double neckLength;

  const BodySignature({
    required this.shoulderToHipRatio,
    required this.torsoToLegRatio,
    required this.armSpanRatio,
    required this.headToShoulderRatio,
    required this.neckLength,
  });

  static const BodySignature zero = BodySignature(
    shoulderToHipRatio: 0,
    torsoToLegRatio: 0,
    armSpanRatio: 0,
    headToShoulderRatio: 0,
    neckLength: 0,
  );

  bool get isValid {
    return shoulderToHipRatio > 0 &&
        torsoToLegRatio > 0 &&
        armSpanRatio > 0 &&
        headToShoulderRatio > 0 &&
        neckLength > 0 &&
        !shoulderToHipRatio.isNaN &&
        !torsoToLegRatio.isNaN &&
        !armSpanRatio.isNaN &&
        !headToShoulderRatio.isNaN &&
        !neckLength.isNaN;
  }

  static double _dist(double x1, double y1, double x2, double y2) {
    final dx = x2 - x1;
    final dy = y2 - y1;
    return math.sqrt(dx * dx + dy * dy);
  }

  /// Crea una BodySignature desde un Pose de ML Kit.
  /// Retorna null si los landmarks clave tienen baja confianza.
  static BodySignature? fromPose(Pose pose) {
    final lm = pose.landmarks;

    final leftShoulder = lm[PoseLandmarkType.leftShoulder];
    final rightShoulder = lm[PoseLandmarkType.rightShoulder];
    final leftHip = lm[PoseLandmarkType.leftHip];
    final rightHip = lm[PoseLandmarkType.rightHip];
    final leftAnkle = lm[PoseLandmarkType.leftAnkle];
    final rightAnkle = lm[PoseLandmarkType.rightAnkle];
    final leftWrist = lm[PoseLandmarkType.leftWrist];
    final rightWrist = lm[PoseLandmarkType.rightWrist];
    final nose = lm[PoseLandmarkType.nose];

    // Verificar que los landmarks esenciales existen con confianza suficiente
    const minConfidence = 0.5;
    final essentials = [leftShoulder, rightShoulder, leftHip, rightHip];
    if (essentials.any((l) => l == null || l.likelihood < minConfidence)) {
      return null;
    }
    if (leftAnkle == null || rightAnkle == null || nose == null) return null;
    if (leftWrist == null || rightWrist == null) return null;

    // Puntos medios
    final shoulderMidX = (leftShoulder!.x + rightShoulder!.x) / 2;
    final shoulderMidY = (leftShoulder.y + rightShoulder.y) / 2;
    final hipMidX = (leftHip!.x + rightHip!.x) / 2;
    final hipMidY = (leftHip.y + rightHip.y) / 2;
    final ankleMidY = (leftAnkle.y + rightAnkle.y) / 2;

    // shoulderToHipRatio: ancho de hombros / ancho de caderas
    final shoulderWidth = _dist(leftShoulder.x, leftShoulder.y,
        rightShoulder.x, rightShoulder.y);
    final hipWidth = _dist(leftHip.x, leftHip.y, rightHip.x, rightHip.y);
    final shoulderToHipRatio = shoulderWidth / (hipWidth + 0.001);

    // torsoToLegRatio: largo torso / largo piernas
    final torsoLength = (hipMidY - shoulderMidY).abs();
    final legLength = (ankleMidY - hipMidY).abs();
    final torsoToLegRatio = torsoLength / (legLength + 0.001);

    // armSpanRatio: envergadura de brazos / altura total
    final armSpan = _dist(leftWrist.x, leftWrist.y, rightWrist.x, rightWrist.y);
    final totalHeight = (ankleMidY - nose.y).abs();
    final armSpanRatio = armSpan / (totalHeight + 0.001);

    // headToShoulderRatio: largo cabeza-cuello / ancho hombros
    final headLength = (shoulderMidY - nose.y).abs();
    final headToShoulderRatio = headLength / (shoulderWidth + 0.001);

    // neckLength: proporción cuello/cabeza respecto a altura total
    final neckLen = headLength / (totalHeight + 0.001);

    return BodySignature(
      shoulderToHipRatio: shoulderToHipRatio,
      torsoToLegRatio: torsoToLegRatio,
      armSpanRatio: armSpanRatio,
      headToShoulderRatio: headToShoulderRatio,
      neckLength: neckLen,
    );
  }

  /// Similaridad entre 0.0 y 1.0 respecto a otra firma corporal.
  /// Basado en diferencia absoluta promedio de proporciones.
  double similarityTo(BodySignature other) {
    if (!isValid || !other.isValid) return 0.0;

    final diffs = [
      (shoulderToHipRatio - other.shoulderToHipRatio).abs(),
      (torsoToLegRatio - other.torsoToLegRatio).abs(),
      (armSpanRatio - other.armSpanRatio).abs(),
      (headToShoulderRatio - other.headToShoulderRatio).abs(),
      (neckLength - other.neckLength).abs(),
    ];

    final avgDiff = diffs.reduce((a, b) => a + b) / diffs.length;
    return (1.0 - avgDiff * 4.0).clamp(0.0, 1.0);
  }

  /// Retorna una nueva firma adaptada usando EMA (Exponential Moving Average).
  /// [alpha] cercano a 1.0 = adaptación lenta y conservadora.
  BodySignature adaptedWith(BodySignature live, {double alpha = 0.97}) {
    if (!live.isValid) return this;
    return BodySignature(
      shoulderToHipRatio:
          alpha * shoulderToHipRatio + (1 - alpha) * live.shoulderToHipRatio,
      torsoToLegRatio:
          alpha * torsoToLegRatio + (1 - alpha) * live.torsoToLegRatio,
      armSpanRatio: alpha * armSpanRatio + (1 - alpha) * live.armSpanRatio,
      headToShoulderRatio:
          alpha * headToShoulderRatio + (1 - alpha) * live.headToShoulderRatio,
      neckLength: alpha * neckLength + (1 - alpha) * live.neckLength,
    );
  }

  Map<String, double> toJson() => {
        'shoulderToHipRatio': shoulderToHipRatio,
        'torsoToLegRatio': torsoToLegRatio,
        'armSpanRatio': armSpanRatio,
        'headToShoulderRatio': headToShoulderRatio,
        'neckLength': neckLength,
      };

  factory BodySignature.fromJson(Map<String, double> json) => BodySignature(
        shoulderToHipRatio: json['shoulderToHipRatio'] ?? 0,
        torsoToLegRatio: json['torsoToLegRatio'] ?? 0,
        armSpanRatio: json['armSpanRatio'] ?? 0,
        headToShoulderRatio: json['headToShoulderRatio'] ?? 0,
        neckLength: json['neckLength'] ?? 0,
      );
}
