import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';

/// Linear progress bar that auto-colors based on the confidence value.
class ConfidenceBar extends StatelessWidget {
  final double value;
  final double height;

  const ConfidenceBar({
    super.key,
    required this.value,
    this.height = 4,
  });

  Color _colorForValue(double v) {
    if (v > 0.85) return AppColors.stateWorking;
    if (v >= 0.60) return AppColors.stateInactive;
    return AppColors.stateDistracted;
  }

  @override
  Widget build(BuildContext context) {
    final color = _colorForValue(value);
    return ClipRRect(
      borderRadius: BorderRadius.circular(2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: color.withValues(alpha: 0.15),
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}
