import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

/// Overlay widget for the camera scanner screens.
/// Shows 4 corner L-shapes and an animated horizontal scan line.
class ScannerOverlay extends StatefulWidget {
  final Color overlayColor;

  const ScannerOverlay({
    super.key,
    this.overlayColor = AppColors.violet,
  });

  @override
  State<ScannerOverlay> createState() => _ScannerOverlayState();
}

class _ScannerOverlayState extends State<ScannerOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final w = constraints.maxWidth;
        final h = constraints.maxHeight;
        final cornerLen = 24.0;
        final strokeWidth = 2.0;
        final color = widget.overlayColor;

        return Stack(
          children: [
            // 4 corner L-shapes
            ..._buildCorners(w, h, cornerLen, strokeWidth, color),

            // Animated scan line
            AnimatedBuilder(
              animation: _animation,
              builder: (context, child) {
                final y = _animation.value * (h - 2);
                return Positioned(
                  left: 16,
                  right: 16,
                  top: y,
                  child: Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          color.withValues(alpha: 0.0),
                          color.withValues(alpha: 0.8),
                          color.withValues(alpha: 0.0),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        );
      },
    );
  }

  List<Widget> _buildCorners(
    double w, double h, double len, double stroke, Color color,
  ) {
    return [
      // Top-left
      Positioned(
        left: 0,
        top: 0,
        child: _Corner(
          width: len,
          height: stroke,
          bottomWidth: stroke,
          bottomHeight: len,
          color: color,
        ),
      ),
      // Top-right
      Positioned(
        right: 0,
        top: 0,
        child: _Corner(
          width: len,
          height: stroke,
          bottomWidth: stroke,
          bottomHeight: len,
          color: color,
          flipHorizontal: true,
        ),
      ),
      // Bottom-left
      Positioned(
        left: 0,
        bottom: 0,
        child: _Corner(
          width: len,
          height: stroke,
          bottomWidth: stroke,
          bottomHeight: len,
          color: color,
          flipVertical: true,
        ),
      ),
      // Bottom-right
      Positioned(
        right: 0,
        bottom: 0,
        child: _Corner(
          width: len,
          height: stroke,
          bottomWidth: stroke,
          bottomHeight: len,
          color: color,
          flipHorizontal: true,
          flipVertical: true,
        ),
      ),
    ];
  }
}

class _Corner extends StatelessWidget {
  final double width;
  final double height;
  final double bottomWidth;
  final double bottomHeight;
  final Color color;
  final bool flipHorizontal;
  final bool flipVertical;

  const _Corner({
    required this.width,
    required this.height,
    required this.bottomWidth,
    required this.bottomHeight,
    required this.color,
    this.flipHorizontal = false,
    this.flipVertical = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width,
      height: bottomHeight,
      child: CustomPaint(
        painter: _CornerPainter(
          color: color,
          strokeWidth: height,
          cornerLength: width,
          verticalLength: bottomHeight,
          flipH: flipHorizontal,
          flipV: flipVertical,
        ),
      ),
    );
  }
}

class _CornerPainter extends CustomPainter {
  final Color color;
  final double strokeWidth;
  final double cornerLength;
  final double verticalLength;
  final bool flipH;
  final bool flipV;

  _CornerPainter({
    required this.color,
    required this.strokeWidth,
    required this.cornerLength,
    required this.verticalLength,
    required this.flipH,
    required this.flipV,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final startX = flipH ? size.width : 0.0;
    final startY = flipV ? size.height : 0.0;
    final hDir = flipH ? -1.0 : 1.0;
    final vDir = flipV ? -1.0 : 1.0;

    // Horizontal line
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX + hDir * cornerLength, startY),
      paint,
    );
    // Vertical line
    canvas.drawLine(
      Offset(startX, startY),
      Offset(startX, startY + vDir * verticalLength),
      paint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
