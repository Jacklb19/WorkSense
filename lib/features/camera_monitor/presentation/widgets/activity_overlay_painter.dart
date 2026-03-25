import 'package:flutter/material.dart';
import 'package:google_mlkit_face_detection/google_mlkit_face_detection.dart';
import 'package:google_mlkit_pose_detection/google_mlkit_pose_detection.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';

class ActivityOverlayPainter extends CustomPainter {
  final ActivityState state;
  final double confidence;
  final List<Pose> poses;
  final List<Face> faces;

  ActivityOverlayPainter({
    required this.state,
    required this.confidence,
    this.poses = const [],
    this.faces = const [],
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawSkeleton(canvas, size);
    _drawFaceMask(canvas, size);
    _drawConfidenceBar(canvas, size);
    _drawStateBadge(canvas, size);
  }

  void _drawSkeleton(Canvas canvas, Size size) {
    if (poses.isEmpty) return;

    final paint = Paint()
      ..color = state.color.withOpacity(0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.0;

    final pointPaint = Paint()
      ..color = Colors.white.withOpacity(0.8)
      ..style = PaintingStyle.fill;

    for (final pose in poses) {
      // Draw connections
      void drawLine(PoseLandmarkType type1, PoseLandmarkType type2) {
        final p1 = pose.landmarks[type1];
        final p2 = pose.landmarks[type2];
        if (p1 != null && p2 != null) {
          canvas.drawLine(
            Offset(p1.x, p1.y),
            Offset(p2.x, p2.y),
            paint,
          );
        }
      }

      // Shoulders & Arms
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.rightShoulder);
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftElbow);
      drawLine(PoseLandmarkType.leftElbow, PoseLandmarkType.leftWrist);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightElbow);
      drawLine(PoseLandmarkType.rightElbow, PoseLandmarkType.rightWrist);

      // Torso
      drawLine(PoseLandmarkType.leftShoulder, PoseLandmarkType.leftHip);
      drawLine(PoseLandmarkType.rightShoulder, PoseLandmarkType.rightHip);
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.rightHip);

      // Legs
      drawLine(PoseLandmarkType.leftHip, PoseLandmarkType.leftKnee);
      drawLine(PoseLandmarkType.rightHip, PoseLandmarkType.rightKnee);

      // Draw points
      for (final landmark in pose.landmarks.values) {
        canvas.drawCircle(Offset(landmark.x, landmark.y), 4, pointPaint);
      }
    }
  }

  void _drawFaceMask(Canvas canvas, Size size) {
    if (faces.isEmpty) return;

    final paint = Paint()
      ..color = state.color.withOpacity(0.5)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    for (final face in faces) {
      final r = face.boundingBox;
      canvas.drawRect(r, paint);

      // Draw landmarks
      final landmarkPaint = Paint()
        ..color = Colors.white.withOpacity(0.8)
        ..style = PaintingStyle.fill;

      for (final landmark in face.landmarks.values) {
        if (landmark != null) {
          canvas.drawCircle(
            Offset(landmark.position.x.toDouble(), landmark.position.y.toDouble()),
            2,
            landmarkPaint,
          );
        }
      }
    }
  }


  void _drawConfidenceBar(Canvas canvas, Size size) {
    const barHeight = 4.0;
    const barMargin = 16.0;
    final barWidth = size.width - barMargin * 2;
    final barTop = size.height - barHeight - barMargin;

    // Background track
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

    // Filled portion
    final fillPaint = Paint()
      ..color = state.color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(
            barMargin, barTop, barWidth * confidence.clamp(0.0, 1.0), barHeight),
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

    final bgWidth =
        textPainter.width + padding.horizontal;
    final bgHeight = textPainter.height + padding.vertical;
    const margin = 16.0;
    final left = margin;
    final top = margin;

    // Badge background
    final bgPaint = Paint()
      ..color = AppColors.overlayBadgeBg
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, bgWidth, bgHeight),
        const Radius.circular(6),
      ),
      bgPaint,
    );

    // State color indicator strip on left
    final stripPaint = Paint()
      ..color = state.color
      ..style = PaintingStyle.fill;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(left, top, 4, bgHeight),
        const Radius.circular(2),
      ),
      stripPaint,
    );

    // Text
    textPainter.paint(
      canvas,
      Offset(
        left + padding.left + 4,
        top + padding.top,
      ),
    );
  }

  @override
  bool shouldRepaint(ActivityOverlayPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.confidence != confidence ||
        oldDelegate.poses != poses ||
        oldDelegate.faces != faces;
  }

}
