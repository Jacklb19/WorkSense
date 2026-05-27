import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';

class ActivityOverlayPainter extends CustomPainter {
  final ActivityState state;
  final double confidence;
  final Rect? faceRect;
  final List<Pose> poses;
  final List<Face> faces;
  final Size imageSize;
  final String? identificationMethod;
  final double identityConfidence;

  ActivityOverlayPainter({
    required this.state,
    required this.confidence,
    this.faceRect,
    this.poses = const [],
    this.faces = const [],
    this.imageSize = Size.zero,
    this.identificationMethod,
    this.identityConfidence = 0.0,
  });

  // ─── COLORS ─────────────────────────────────────────────────────────────────
  // Use state-driven colors for both skeleton and face frame
  Color get _accentColor {
    switch (state) {
      case ActivityState.trabajando:    return AppColors.stateWorking;
      case ActivityState.distraido:     return AppColors.stateDistracted;
      case ActivityState.fatiga:        return AppColors.stateFatigue;
      case ActivityState.ausente:       return AppColors.stateAbsent;
      case ActivityState.fueraDelArea:  return AppColors.stateOutsideArea;
      default:                          return AppColors.primary;
    }
  }

  @override
  void paint(Canvas canvas, Size size) {
    if (state == ActivityState.fueraDelArea) {
      _drawOutsideAreaOverlay(canvas, size);
      return;
    }

    // Draw clean skeleton lines (no dots)
    _drawPoseSkeleton(canvas, size);

    // Draw face corner frame
    _drawFaceFrame(canvas, size);

    // Draw identity HUD badge
    if (identificationMethod != null && identityConfidence > 0) {
      _drawIdentityHUD(canvas, size);
    }
  }

  /// Draws only the skeleton LINES connecting major joints — no landmark dots.
  void _drawPoseSkeleton(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final color = _accentColor;
    final linePaint = Paint()
      ..color = color.withValues(alpha: 0.55)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round;

    const connections = [
      // Upper body only — visible and meaningful in kiosk context
      [PoseLandmarkType.leftShoulder,  PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow,     PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow,    PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip,       PoseLandmarkType.rightHip],
    ];

    for (final pose in poses) {
      for (final conn in connections) {
        final a = pose.landmarks[conn[0]];
        final b = pose.landmarks[conn[1]];
        if (a == null || b == null) continue;
        if (a.likelihood < 0.5 || b.likelihood < 0.5) continue;
        canvas.drawLine(
          _toScreen(a.x, a.y, size),
          _toScreen(b.x, b.y, size),
          linePaint,
        );
      }
    }
  }

  /// Draws the 4-corner frame around the face bounding box — no dots.
  void _drawFaceFrame(Canvas canvas, Size size) {
    if (faces.isEmpty || imageSize == Size.zero) return;
    final face = faces.first;
    final rect = face.boundingBox;

    final color = _accentColor;
    final paint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    // Mirror X (front camera)
    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;
    final left   = size.width - rect.right  * scaleX;
    final right  = size.width - rect.left   * scaleX;
    final top    = rect.top    * scaleY;
    final bottom = rect.bottom * scaleY;

    // Adaptive corner length — 20% of the shorter dimension
    final cornerLen = ((right - left) * 0.20).clamp(12.0, 36.0);

    final corners = <Path>[
      Path()..moveTo(left, top + cornerLen)..lineTo(left, top)..lineTo(left + cornerLen, top),
      Path()..moveTo(right - cornerLen, top)..lineTo(right, top)..lineTo(right, top + cornerLen),
      Path()..moveTo(left, bottom - cornerLen)..lineTo(left, bottom)..lineTo(left + cornerLen, bottom),
      Path()..moveTo(right - cornerLen, bottom)..lineTo(right, bottom)..lineTo(right, bottom - cornerLen),
    ];
    for (final p in corners) {
      canvas.drawPath(p, paint);
    }

    // Subtle tinted fill — just a hint of color
    canvas.drawRect(
      Rect.fromLTRB(left, top, right, bottom),
      Paint()..color = color.withValues(alpha: 0.04),
    );
  }

  void _drawOutsideAreaOverlay(Canvas canvas, Size size) {
    canvas.drawRect(
      Rect.fromLTWH(0, 0, size.width, size.height),
      Paint()..color = Colors.black45,
    );
    _drawCenteredText(
      canvas,
      'EMPLEADO FUERA DE ÁREA',
      Offset(size.width / 2, size.height / 2),
      const TextStyle(
        color: Colors.white,
        fontSize: 13,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
      ),
      size,
    );
  }

  void _drawIdentityHUD(Canvas canvas, Size size) {
    final (icon, label) = _identityLabel(identificationMethod);
    final color = _identityColor(identityConfidence);

    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(
            text: '$icon $label  ',
            style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.normal),
          ),
          TextSpan(
            text: '${(identityConfidence * 100).toInt()}%',
            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900),
          ),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    const top = 110.0;
    final w   = tp.width + 24;
    final h   = tp.height + 12;
    final left = size.width - w - 24;

    canvas.drawRRect(
      RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), const Radius.circular(8)),
      Paint()..color = AppColors.overlayBadgeBg,
    );
    tp.paint(canvas, Offset(left + 12, top + 6));
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────────

  Offset _toScreen(double x, double y, Size canvasSize) {
    if (imageSize == Size.zero) return Offset(x, y);
    final mirroredX = (imageSize.width - x) * (canvasSize.width / imageSize.width);
    final scaledY   = y * (canvasSize.height / imageSize.height);
    return Offset(mirroredX, scaledY);
  }

  void _drawCenteredText(Canvas canvas, String text, Offset center, TextStyle style, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * 0.8);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy));
  }

  (String, String) _identityLabel(String? method) {
    switch (method?.toUpperCase()) {
      case 'FACEEMBEDDING': return ('👁️', 'BIO-FACE');
      case 'BODY':          return ('🧍', 'BODY-SCAN');
      case 'COMBINED':      return ('🔍', 'HÍBRIDO');
      case 'TRACKING':      return ('🎯', 'TRACKING');
      default:              return ('🔍', 'BUSCANDO');
    }
  }

  Color _identityColor(double confidence) {
    if (confidence >= 0.8) return AppColors.identityHigh;
    if (confidence >= 0.6) return AppColors.identityMedium;
    return AppColors.identityLow;
  }

  @override
  bool shouldRepaint(ActivityOverlayPainter old) =>
      old.state != state ||
      old.faces != faces ||
      old.poses != poses ||
      old.identityConfidence != identityConfidence;
}
