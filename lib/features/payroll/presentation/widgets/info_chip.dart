import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';

class InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  const InfoChip({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: AppDimensions.spacingXxl, color: context.appOnSurfaceSecondary),
        const SizedBox(width: AppDimensions.spacingXs),
        Text(label,
            style: theme.textTheme.bodySmall?.copyWith(color: context.appOnSurfaceSecondary)),
      ],
    );
  }
}
