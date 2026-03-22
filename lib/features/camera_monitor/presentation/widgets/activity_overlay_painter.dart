import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/domain/entities/activity_state.dart';

class ActivityOverlayPainter extends CustomPainter {
  final ActivityState state;
  final double confidence;
  final Rect? faceRect;

  ActivityOverlayPainter({
    required this.state,
    required this.confidence,
    this.faceRect,
  });

  @override
  void paint(Canvas canvas, Size size) {
    _drawFaceRect(canvas, size);
    _drawConfidenceBar(canvas, size);
    _drawStateBadge(canvas, size);
  }

  void _drawFaceRect(Canvas canvas, Size size) {
    if (faceRect == null) return;

    final paint = Paint()
      ..color = AppColors.overlayFaceRect
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;

    const cornerLength = 20.0;
    final r = faceRect!;

    // Draw corner brackets instead of full rectangle
    final paths = [
      // Top-left
      Path()
        ..moveTo(r.left, r.top + cornerLength)
        ..lineTo(r.left, r.top)
        ..lineTo(r.left + cornerLength, r.top),
      // Top-right
      Path()
        ..moveTo(r.right - cornerLength, r.top)
        ..lineTo(r.right, r.top)
        ..lineTo(r.right, r.top + cornerLength),
      // Bottom-left
      Path()
        ..moveTo(r.left, r.bottom - cornerLength)
        ..lineTo(r.left, r.bottom)
        ..lineTo(r.left + cornerLength, r.bottom),
      // Bottom-right
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
        oldDelegate.faceRect != faceRect;
  }
}
