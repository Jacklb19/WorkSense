import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';

/// A circular loading indicator with Semantics for accessibility.
///
/// Wraps [CircularProgressIndicator] with a semantic label so screen
/// readers announce "Cargando" (or a custom label) instead of silence.
class AppLoadingIndicator extends StatelessWidget {
  const AppLoadingIndicator({
    super.key,
    this.label = 'Cargando',
    this.color,
    this.size = AppDimensions.progressIndicatorSize,
    this.strokeWidth = AppDimensions.progressStrokeWidth,
  });

  final String label;
  final Color? color;
  final double size;
  final double strokeWidth;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: label,
      child: SizedBox(
        width: size,
        height: size,
        child: CircularProgressIndicator(
          strokeWidth: strokeWidth,
          color: color ?? AppColors.primary,
        ),
      ),
    );
  }
}