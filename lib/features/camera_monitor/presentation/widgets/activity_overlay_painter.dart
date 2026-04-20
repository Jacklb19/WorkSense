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

  @override
  void paint(Canvas canvas, Size size) {
    if (state == ActivityState.fueraDelArea) {
      _drawOutsideAreaOverlay(canvas, size);
    } else {
      _drawPose(canvas, size);
      _drawFaceMesh(canvas, size);
      _drawFaceRect(canvas, size);
    }

    if (identificationMethod != null && identityConfidence > 0) {
      _drawIdentityHUD(canvas, size);
    }
  }

  void _drawPose(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final linePaint = Paint()
      ..color = _cyanLine.withOpacity(0.4)
      ..strokeWidth = 1.5
      ..strokeCap = StrokeCap.round;

    final dotPaint = Paint()
      ..color = _cyanDot
      ..style = PaintingStyle.fill;

    const connections = [
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
      [PoseLandmarkType.leftElbow,    PoseLandmarkType.leftWrist],
      [PoseLandmarkType.rightShoulder,PoseLandmarkType.rightElbow],
      [PoseLandmarkType.rightElbow,   PoseLandmarkType.rightWrist],
      [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
      [PoseLandmarkType.rightShoulder,PoseLandmarkType.rightHip],
      [PoseLandmarkType.leftHip,      PoseLandmarkType.rightHip],
    ];

    for (final pose in poses) {
      for (final conn in connections) {
        final a = pose.landmarks[conn[0]];
        final b = pose.landmarks[conn[1]];
        if (a == null || b == null) continue;
        if (a.likelihood < 0.5 || b.likelihood < 0.5) continue;
        canvas.drawLine(_toScreen(a.x, a.y, size), _toScreen(b.x, b.y, size), linePaint);
      }

      for (final lm in pose.landmarks.values) {
        if (lm.likelihood < 0.5) continue;
        final pt = _toScreen(lm.x, lm.y, size);
        canvas.drawCircle(pt, 3.0, dotPaint);
      }
    }
  }

  void _drawFaceMesh(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final linePaint = Paint()
      ..color = _redLine.withOpacity(0.3)
      ..strokeWidth = 1.0;

    final dotPaint = Paint()
      ..color = _redDot.withOpacity(0.6)
      ..style = PaintingStyle.fill;

    for (final face in faces) {
      final landmarks = face.landmarks.values;
      for (final lm in landmarks) {
        final pos = lm?.position;
        if (pos == null) continue;
        final pt = _toScreenInt(pos.x, pos.y, size);
        canvas.drawCircle(pt, 2.0, dotPaint);
      }
    }
  }

  void _drawFaceRect(Canvas canvas, Size size) {
    if (faces.isEmpty) return;
    final face = faces.first;
    final rect = face.boundingBox;

    final paint = Paint()
      ..color = AppColors.overlayCyanDot
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    const L = 30.0;
    // Mirror X
    final left   = size.width - (rect.right * (size.width / imageSize.width));
    final right  = size.width - (rect.left * (size.width / imageSize.width));
    final top    = rect.top * (size.height / imageSize.height);
    final bottom = rect.bottom * (size.height / imageSize.height);

    final paths = [
      Path()..moveTo(left, top + L)..lineTo(left, top)..lineTo(left + L, top),
      Path()..moveTo(right - L, top)..lineTo(right, top)..lineTo(right, top + L),
      Path()..moveTo(left, bottom - L)..lineTo(left, bottom)..lineTo(left + L, bottom),
      Path()..moveTo(right - L, bottom)..lineTo(right, bottom)..lineTo(right, bottom - L),
    ];

    for (final p in paths) canvas.drawPath(p, paint);
  }

  void _drawOutsideAreaOverlay(Canvas canvas, Size size) {
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = Colors.black45);
    _drawCenteredText(canvas, 'EMPLEADO FUERA DE CÁMARA', Offset(size.width/2, size.height/2), const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w900, letterSpacing: 2), size);
  }

  void _drawIdentityHUD(Canvas canvas, Size size) {
    final (icon, label) = _identityLabel(identificationMethod);
    final color = _identityColor(identityConfidence);
    
    final tp = TextPainter(
      text: TextSpan(
        children: [
          TextSpan(text: '$icon $label  ', style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.normal)),
          TextSpan(text: '${(identityConfidence*100).toInt()}%', style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w900)),
        ],
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final w = tp.width + 24;
    final h = tp.height + 12;
    final left = size.width - w - 24;
    const top = 110.0;

    canvas.drawRRect(RRect.fromRectAndRadius(Rect.fromLTWH(left, top, w, h), const Radius.circular(8)), Paint()..color = AppColors.overlayBadgeBg);
    tp.paint(canvas, Offset(left + 12, top + 6));
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

  void _drawCenteredText(Canvas canvas, String text, Offset center, TextStyle style, Size size) {
    final tp = TextPainter(text: TextSpan(text: text, style: style), textDirection: TextDirection.ltr, textAlign: TextAlign.center)..layout(maxWidth: size.width * 0.8);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy));
  }

  (String, String) _identityLabel(String? method) {
    switch (method?.toUpperCase()) {
      case 'FACEEMBEDDING': return ('👁️', 'BIO-FACE');
      case 'BODY':          return ('🧍', 'BODY-SCAN');
      case 'COMBINED':      return ('🔍', 'HYBRID');
      default:              return ('🔍', 'BUSCANDO');
    }
  }

  Color _identityColor(double confidence) {
    if (confidence >= 0.8) return AppColors.identityHigh;
    if (confidence >= 0.6) return AppColors.identityMedium;
    return AppColors.identityLow;
  }

  @override
  bool shouldRepaint(ActivityOverlayPainter old) => true;
}