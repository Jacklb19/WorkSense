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

  static const List<List<PoseLandmarkType>> _skeletonConnections = [
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow],
    [PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow],
    [PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist],
    [PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip],
    [PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.rightHip],
    [PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee],
    [PoseLandmarkType.leftKnee, PoseLandmarkType.leftAnkle],
    [PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee],
    [PoseLandmarkType.rightKnee, PoseLandmarkType.rightAnkle],
  ];

  static const List<PoseLandmarkType> _keyDots = [
    PoseLandmarkType.leftShoulder,
    PoseLandmarkType.rightShoulder,
    PoseLandmarkType.leftElbow,
    PoseLandmarkType.rightElbow,
    PoseLandmarkType.leftWrist,
    PoseLandmarkType.rightWrist,
    PoseLandmarkType.leftHip,
    PoseLandmarkType.rightHip,
  ];

  @override
  void paint(Canvas canvas, Size size) {
    // Overlay especial para FUERA DEL ÁREA
    if (state == ActivityState.fueraDelArea) {
      _drawOutsideAreaOverlay(canvas, size);
    } else {
      _drawPose(canvas, size);
      _drawFaceMask(canvas, size);
      _drawFaceRect(canvas, size);
    }

    _drawConfidenceBar(canvas, size);
    _drawStateBadge(canvas, size);

    if (identificationMethod != null && identityConfidence > 0) {
      _drawIdentityBadge(canvas, size);
    }
  }

  Offset _scale(double x, double y, Size canvasSize) {
    if (imageSize == Size.zero) return Offset(x, y);
    return Offset(
      x * canvasSize.width / imageSize.width,
      y * canvasSize.height / imageSize.height,
    );
  }

  void _drawPose(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final linePaint = Paint()
      ..color = Colors.white.withOpacity(0.65)
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    final dotPaint = Paint()
      ..color = const Color(0xFF39FF14).withOpacity(0.85)
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      for (final connection in _skeletonConnections) {
        final a = pose.landmarks[connection[0]];
        final b = pose.landmarks[connection[1]];
        if (a == null || b == null) continue;
        canvas.drawLine(
          _scale(a.x, a.y, size),
          _scale(b.x, b.y, size),
          linePaint,
        );
      }

      for (final type in _keyDots) {
        final lm = pose.landmarks[type];
        if (lm == null) continue;
        canvas.drawCircle(_scale(lm.x, lm.y, size), 4.0, dotPaint);
      }
    }
  }

  void _drawFaceMask(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final dotPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (final face in faces) {
      for (final lm in face.landmarks.values) {
        if (lm == null) continue;
        canvas.drawCircle(
          _scale(lm.position.x.toDouble(), lm.position.y.toDouble(), size),
          3.0,
          dotPaint,
        );
      }
    }
  }

  void _drawOutsideAreaOverlay(Canvas canvas, Size size) {
    // Tinte azul semitransparente en toda la pantalla
    final tintPaint = Paint()
      ..color = const Color(0xFF2196F3).withOpacity(0.25)
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), tintPaint);

    // Icono de persona con X en el centro
    const iconSize = 64.0;
    final cx = size.width / 2;
    final cy = size.height / 2 - 40;

    final iconPaint = Paint()
      ..color = Colors.white.withOpacity(0.9)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;

    // Círculo cabeza
    canvas.drawCircle(Offset(cx, cy - iconSize * 0.3), iconSize * 0.2, iconPaint);

    // Cuerpo
    canvas.drawLine(
      Offset(cx, cy - iconSize * 0.1),
      Offset(cx, cy + iconSize * 0.3),
      iconPaint,
    );

    // X roja encima
    final xPaint = Paint()
      ..color = Colors.redAccent.withOpacity(0.9)
      ..strokeWidth = 4.0
      ..style = PaintingStyle.stroke;
    const xOff = 14.0;
    canvas.drawLine(
        Offset(cx - xOff, cy - iconSize * 0.55),
        Offset(cx + xOff, cy - iconSize * 0.35),
        xPaint);
    canvas.drawLine(
        Offset(cx + xOff, cy - iconSize * 0.55),
        Offset(cx - xOff, cy - iconSize * 0.35),
        xPaint);

    // Texto
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

  void _drawCenteredText(
      Canvas canvas, String text, Offset center, TextStyle style, Size size) {
    final tp = TextPainter(
      text: TextSpan(text: text, style: style),
      textDirection: TextDirection.ltr,
      textAlign: TextAlign.center,
    )..layout(maxWidth: size.width * 0.8);
    tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy));
  }

  void _drawFaceRect(Canvas canvas, Size size) {
    if (faceRect == null) return;

    final paint = Paint()
      ..color = AppColors.overlayFaceRect
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const cornerLength = 20.0;
    final r = faceRect!;

    final paths = [
      Path()
        ..moveTo(r.left, r.top + cornerLength)
        ..lineTo(r.left, r.top)
        ..lineTo(r.left + cornerLength, r.top),
      Path()
        ..moveTo(r.right - cornerLength, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.top + cornerLength),
      Path()
        ..moveTo(r.left, r.bottom - cornerLength)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.left + cornerLength, r.bottom),
      Path()
        ..moveTo(r.right - cornerLength, r.bottom)
        ..lineTo(r.right, r.bottom)
        ..lineTo(r.right, r.bottom - cornerLength),
    ];

    for (final path in paths) {
      canvas.drawPath(path, paint);
    }
  }

  void _drawConfidenceBar(Canvas canvas, Size size) {
    const barHeight = 4.0;
    const barMargin = 16.0;
    final barWidth = size.width - barMargin * 2;
    final barTop = size.height - barHeight - barMargin;

    final bgPaint = Paint()
      ..color = Colors.white.withOpacity(0.3)
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barMargin, barTop, barWidth, barHeight),
        const Radius.circular(2),
      ),
      bgPaint,
    );

    final fillPaint = Paint()
      ..color = state.color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(barMargin, barTop,
            barWidth * confidence.clamp(0.0, 1.0), barHeight),
        const Radius.circular(2),
      ),
      fillPaint,
    );
  }

  void _drawStateBadge(Canvas canvas, Size size) {
    const padding = EdgeInsets.symmetric(horizontal: 12, vertical: 6);
    const fontSize = 13.0;

    final text = '${state.emoji}  ${state.label}';
    final textSpan = TextSpan(
      text: text,
      style: const TextStyle(
        color: Colors.white,
        fontSize: fontSize,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
    );

    final textPainter = TextPainter(
      text: textSpan,
      textDirection: TextDirection.ltr,
    )..layout();

    final bgWidth = textPainter.width + padding.horizontal;
    final bgHeight = textPainter.height + padding.vertical;
    const margin = 16.0;

    final bgPaint = Paint()
      ..color = AppColors.overlayBadgeBg
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, margin, bgWidth, bgHeight),
        const Radius.circular(6),
      ),
      bgPaint,
    );

    final stripPaint = Paint()
      ..color = state.color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(margin, margin, 4, bgHeight),
        const Radius.circular(2),
      ),
      stripPaint,
    );

    textPainter.paint(
      canvas,
      Offset(margin + padding.left + 4, margin + padding.top),
    );
  }

  /// Badge de identidad: cómo fue identificado el empleado.
  void _drawIdentityBadge(Canvas canvas, Size size) {
    const margin = 16.0;

    final (icon, label) = _identityLabel(identificationMethod);
    final text = '$icon $label';

    // Barra de certeza de identidad
    final pct = (identityConfidence * 100).toStringAsFixed(0);
    final certText = 'Certeza: $pct%';

    final badgeStyle = TextStyle(
      color: _identityColor(identityConfidence),
      fontSize: 11,
      fontWeight: FontWeight.w600,
    );

    final tp1 = TextPainter(
      text: TextSpan(text: text, style: badgeStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final tp2 = TextPainter(
      text: TextSpan(text: certText, style: badgeStyle),
      textDirection: TextDirection.ltr,
    )..layout();

    final badgeW = [tp1.width, tp2.width].reduce((a, b) => a > b ? a : b) + 20;
    const badgeH = 44.0;
    final left = size.width - badgeW - margin;
    const top = margin;

    final bgPaint = Paint()
      ..color = AppColors.overlayBadgeBg
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, badgeW, badgeH),
        const Radius.circular(6),
      ),
      bgPaint,
    );

    tp1.paint(canvas, Offset(left + 10, top + 5));
    tp2.paint(canvas, Offset(left + 10, top + 24));
  }

  (String, String) _identityLabel(String? method) {
    switch (method?.toUpperCase()) {
      case 'TRACKINGID':
        return ('🔒', 'Tracking activo');
      case 'FACEEMBEDDING':
        return ('👁️', 'ID por cara');
      case 'BODY':
        return ('🧍', 'ID por cuerpo');
      case 'COMBINED':
        return ('🔍', 'ID combinada');
      default:
        return ('🔍', 'Buscando...');
    }
  }

  Color _identityColor(double confidence) {
    if (confidence >= 0.85) return Colors.greenAccent;
    if (confidence >= 0.68) return Colors.yellowAccent;
    return Colors.redAccent;
  }

  @override
  bool shouldRepaint(ActivityOverlayPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.confidence != confidence ||
        oldDelegate.faceRect != faceRect ||
        oldDelegate.poses != poses ||
        oldDelegate.faces != faces ||
        oldDelegate.identificationMethod != identificationMethod ||
        oldDelegate.identityConfidence != identityConfidence;
  }
}
