import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_theme_extensions.dart';

class AppStatChip extends StatelessWidget {
  const AppStatChip({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    this.iconColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final onSurface = context.appOnSurface;
    final onSurfaceSecondary = context.appOnSurfaceSecondary;

    return Semantics(
      label: '$label: $value',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: AppDimensions.statChipIconSize, color: iconColor ?? AppColors.primary),
          const SizedBox(height: AppDimensions.spacingXs),
          Text(
            value,
            style: TextStyle(
              fontSize: AppDimensions.fontHeadlineLg,
              fontWeight: FontWeight.w800,
              color: onSurface,
            ),
          ),
          const SizedBox(height: AppDimensions.spacingXxs),
          Text(
            label,
            style: TextStyle(
              fontSize: AppDimensions.fontSm,
              fontWeight: FontWeight.w500,
              color: onSurfaceSecondary,
            ),
          ),
        ],
      ),
    );
  }
}