import 'dart:ui' show Size;

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

  // ─── COLORES ────────────────────────────────────────────────────────────────
  static const Color _cyanDot  = AppColors.overlayCyanDot;
  static const Color _cyanLine = AppColors.overlayCyanLine;
  static const Color _redDot   = AppColors.overlayRedDot;
  static const Color _redLine  = AppColors.overlayRedLine;

  // ─── ESQUELETO (conexiones) ──────────────────────────────────────────────
  static const List<List<PoseLandmarkType>> _skeletonConnections = [
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip,       PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow,     PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow,    PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftHip,       PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee,      PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip,      PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee,     PoseLandmarkType.rightAnkle],
    [PoseLandmarkType.leftShoulder,  PoseLandmarkType.nose],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.nose],
  ];

  static const List<PoseLandmarkType> _keyDots = [
    PoseLandmarkType.nose,
    PoseLandmarkType.leftShoulder,  PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,     PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,     PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,       PoseLandmarkType.rightHip,
    PoseLandmarkType.leftKnee,      PoseLandmarkType.rightKnee,
    PoseLandmarkType.leftAnkle,     PoseLandmarkType.rightAnkle,
  ];

  // ─── TRIANGULACIÓN FACIAL ────────────────────────────────────────────────
  static const List<List<FaceLandmarkType>> _faceTriangles = [
    [FaceLandmarkType.leftEar,   FaceLandmarkType.leftEye,   FaceLandmarkType.rightEye],
    [FaceLandmarkType.leftEye,   FaceLandmarkType.rightEye,  FaceLandmarkType.noseBase],
    [FaceLandmarkType.leftEar,   FaceLandmarkType.rightEar,  FaceLandmarkType.rightEye],
    [FaceLandmarkType.leftEar,   FaceLandmarkType.leftCheek, FaceLandmarkType.leftEye],
    [FaceLandmarkType.rightEar,  FaceLandmarkType.rightCheek,FaceLandmarkType.rightEye],
    [FaceLandmarkType.noseBase,  FaceLandmarkType.leftMouth, FaceLandmarkType.rightMouth],
    [FaceLandmarkType.leftCheek, FaceLandmarkType.leftMouth, FaceLandmarkType.noseBase],
    [FaceLandmarkType.rightCheek,FaceLandmarkType.rightMouth,FaceLandmarkType.noseBase],
    [FaceLandmarkType.leftCheek, FaceLandmarkType.leftMouth, FaceLandmarkType.bottomMouth],
    [FaceLandmarkType.rightCheek,FaceLandmarkType.rightMouth,FaceLandmarkType.bottomMouth],
    [FaceLandmarkType.leftMouth, FaceLandmarkType.rightMouth,FaceLandmarkType.bottomMouth],
  ];

  // ─── PAINT ──────────────────────────────────────────────────────────────────
  @override
  void paint(Canvas canvas, Size size) {
    if (state == ActivityState.fueraDelArea) {
      _drawOutsideAreaOverlay(canvas, size);
    } else {
      _drawPose(canvas, size);
      _drawFaceMesh(canvas, size);
      _drawFaceRect(canvas, size);
    }

    _drawConfidenceBar(canvas, size);
    _drawStateBadge(canvas, size);

    if (identificationMethod != null && identityConfidence > 0) {
      _drawIdentityBadge(canvas, size);
    }
  }

  // ─── ESQUELETO CORPORAL (cyan con halo) ─────────────────────────────────
  void _drawPose(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final linePaint = Paint()
      ..color = _cyanLine
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round;

    final haloPaint = Paint()
      ..color = _cyanDot.withOpacity(0.25)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = _cyanDot
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      for (final conn in _skeletonConnections) {
        final a = pose.landmarks[conn[0]];
        final b = pose.landmarks[conn[1]];
        if (a == null || b == null) continue;
        canvas.drawLine(_toScreen(a.x, a.y, size), _toScreen(b.x, b.y, size), linePaint);
      }

      for (final type in _keyDots) {
        final lm = pose.landmarks[type];
        if (lm == null) continue;
        final pt = _toScreen(lm.x, lm.y, size);
        canvas.drawCircle(pt, 9.0, haloPaint);
        canvas.drawCircle(pt, 5.0, dotPaint);
      }
    }
  }

  // ─── MALLA TRIANGULAR FACIAL (rojo con halo) ─────────────────────────────
  void _drawFaceMesh(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final linePaint = Paint()
      ..color = _redLine.withOpacity(0.7)
      ..strokeWidth = 1.2
      ..strokeCap = StrokeCap.round;

    final haloPaint = Paint()
      ..color = _redDot.withOpacity(0.30)
      ..style = PaintingStyle.fill;

    final dotPaint = Paint()
      ..color = _redDot
      ..style = PaintingStyle.fill;

    for (final face in faces) {
      for (final tri in _faceTriangles) {
        final a = face.landmarks[tri[0]];
        final b = face.landmarks[tri[1]];
        final c = face.landmarks[tri[2]];
        if (a == null || b == null || c == null) continue;

        final pa = _toScreenInt(a.position.x, a.position.y, size);
        final pb = _toScreenInt(b.position.x, b.position.y, size);
        final pc = _toScreenInt(c.position.x, c.position.y, size);

        canvas.drawLine(pa, pb, linePaint);
        canvas.drawLine(pb, pc, linePaint);
        canvas.drawLine(pc, pa, linePaint);
      }

      for (final lm in face.landmarks.values) {
        if (lm == null) continue;
        final pt = _toScreenInt(lm.position.x, lm.position.y, size);
        canvas.drawCircle(pt, 6.5, haloPaint);
        canvas.drawCircle(pt, 3.5, dotPaint);
      }
    }
  }

  // ─── OVERLAY FUERA DEL ÁREA ──────────────────────────────────────────────
  void _drawOutsideAreaOverlay(Canvas canvas, Size size) {
    final tintPaint = Paint()
      ..color = AppColors.overlayBlueFill.withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tintPaint);

    const iconSize = 64.0;
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;

    final iconPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    canvas.drawCircle(Offset(cx, cy - iconSize * 0.3), iconSize * 0.2, iconPaint);
    canvas.drawLine(
      Offset(cx, cy - iconSize * 0.1),
      Offset(cx, cy + iconSize * 0.3),
      iconPaint,
    );

    final xPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.9)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    const xOff = 14.0;
    canvas.drawLine(Offset(cx - xOff, cy - iconSize * 0.55),
        Offset(cx + xOff, cy - iconSize * 0.35), xPaint);
    canvas.drawLine(Offset(cx + xOff, cy - iconSize * 0.55),
        Offset(cx - xOff, cy - iconSize * 0.35), xPaint);

    _drawCenteredText(
      canvas,
      'El empleado no está en el área',
      Offset(cx, cy + iconSize * 0.55),
      const TextStyle(
        color: Colors.white,
        fontSize: 15,
        fontWeight: FontWeight.w600,
        shadows: [Shadow(color: Colors.black54, blurRadius: 4)],
      ),
      size,
    );
  }

  // ─── FACE RECT (esquinas) ────────────────────────────────────────────────
  void _drawFaceRect(Canvas canvas, Size size) {
    if (faceRect == null) return;

    final paint = Paint()
      ..color = AppColors.overlayFaceRect
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const cornerLength = 20.0;
    final r = faceRect!;

    final left   = _toScreenX(r.right, size); // Swapped due to mirroring
    final right  = _toScreenX(r.left,  size);
    final top    = _toScreenY(r.top,   size);
    final bottom = _toScreenY(r.bottom, size);

    final paths = [
      Path()
        ..moveTo(left, top + cornerLength)
        ..lineTo(left, top)
        ..lineTo(left + cornerLength, top),
      Path()
        ..moveTo(right - cornerLength, top)
        ..lineTo(right, top)
        ..lineTo(right, top + cornerLength),
      Path()
        ..moveTo(left, bottom - cornerLength)
        ..lineTo(left, bottom)
        ..lineTo(left + cornerLength, bottom),
      Path()
        ..moveTo(right - cornerLength, bottom)
        ..lineTo(right, bottom)
        ..lineTo(right, bottom - cornerLength),
    ];

    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  // ─── CONFIDENCE BAR ──────────────────────────────────────────────────────
  void _drawConfidenceBar(Canvas canvas, Size size) {
    const barHeight = 4.0;
    const barMargin = 16.0;
    final barWidth = size.width - barMargin * 2;
    final barTop = size.height - barHeight - barMargin;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barMargin, barTop, barWidth, barHeight),
          const Radius.circular(2)),
      Paint()
        ..color = Colors.white.withOpacity(0.3)
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(barMargin, barTop,
              barWidth * confidence.clamp(0.0, 1.0), barHeight),
          const Radius.circular(2)),
      Paint()
        ..color = state.color
        ..style = PaintingStyle.fill,
    );
  }

  // ─── STATE BADGE ─────────────────────────────────────────────────────────
  void _drawStateBadge(Canvas canvas, Size size) {
    const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);

    final textPainter = TextPainter(
      text: TextSpan(
        text: '${state.emoji}  ${state.label}',
        style: const TextStyle(
          color: Colors.white,
          fontSize: 13,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final bgWidth  = textPainter.width  + padding.horizontal;
    final bgHeight = textPainter.height + padding.vertical;
    const margin = 16.0;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(margin, margin, bgWidth, bgHeight),
          const Radius.circular(6)),
      Paint()
        ..color = AppColors.overlayBadgeBg
        ..style = PaintingStyle.fill,
    );

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(margin, margin, 4, bgHeight),
          const Radius.circular(2)),
      Paint()
        ..color = state.color
        ..style = PaintingStyle.fill,
    );

    textPainter.paint(
        canvas, Offset(margin + padding.left + 4, margin + padding.top));
  }

  // ─── IDENTITY BADGE ──────────────────────────────────────────────────────
  void _drawIdentityBadge(Canvas canvas, Size size) {
    const margin = 16.0;

    final (icon, label) = _identityLabel(identificationMethod);
    final pct = (identityConfidence * 100).toStringAsFixed(0);

    final badgeStyle = TextStyle(
      color: _identityColor(identityConfidence),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    final tp1 = TextPainter(
      text: TextSpan(text: '$icon $label', style: badgeStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final tp2 = TextPainter(
      text: TextSpan(text: 'Certeza: $pct%', style: badgeStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeW =
        [tp1.width, tp2.width].reduce((a, b) => a > b ? a : b) + 20;
    const badgeH = 44.0;
    final left = size.width - badgeW - margin;
    const top = margin;

    canvas.drawRRect(
      RRect.fromRectAndRadius(
          Rect.fromLTWH(left, top, badgeW, badgeH),
          const Radius.circular(6)),
      Paint()
        ..color = AppColors.overlayBadgeBg
        ..style = PaintingStyle.fill,
    );

    tp1.paint(canvas, Offset(left + 10, top + 5));
    tp2.paint(canvas, Offset(left + 10, top + 24));
  }

  // ─── HELPERS ─────────────────────────────────────────────────────────────

  double _toScreenX(double x, Size canvasSize) {
    if (imageSize == Size.zero) return x;
    return (imageSize.width - x) * (canvasSize.width / imageSize.width);
  }

  double _toScreenY(double y, Size canvasSize) {
    if (imageSize == Size.zero) return y;
    return y * (canvasSize.height / imageSize.height);
  }

  Offset _toScreen(double x, double y, Size canvasSize) =>
      Offset(_toScreenX(x, canvasSize), _toScreenY(y, canvasSize));

  Offset _toScreenInt(int x, int y, Size size) =>
      _toScreen(x.toDouble(), y.toDouble(), size);

  void _drawCenteredText(
      Canvas canvas, String text, Offset center, TextStyle style, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * 0.8);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy));
  }

  (String, String) _identityLabel(String? method) {
    switch (method?.toUpperCase()) {
      case 'TRACKINGID':    return ('🔒', 'Tracking activo');
      case 'FACEEMBEDDING': return ('👁️', 'ID por cara');
      case 'BODY':          return ('🧍', 'ID por cuerpo');
      case 'COMBINED':      return ('🔍', 'ID combinada');
      default:              return ('🔍', 'Buscando...');
    }
  }

  Color _identityColor(double confidence) {
    if (confidence >= 0.85) return Colors.greenAccent;
    if (confidence >= 0.68) return Colors.yellowAccent;
    return Colors.redAccent;
  }

  @override
  bool shouldRepaint(ActivityOverlayPainter old) =>
      old.state != state ||
      old.confidence != confidence ||
      old.faceRect != faceRect ||
      old.poses != poses ||
      old.faces != faces ||
      old.identificationMethod != identificationMethod ||
      old.identityConfidence != identityConfidence;
}