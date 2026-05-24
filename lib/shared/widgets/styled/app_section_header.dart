import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

class AppSectionHeader extends StatelessWidget {
  final String title;
  final IconData? icon;
  final Color? accentColor;

  const AppSectionHeader({
    super.key,
    required this.title,
    this.icon,
    this.accentColor,
  });

  @override
  Widget build(BuildContext context) {
    final color = accentColor ?? AppColors.primary;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppDimensions.spacingMd),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: color),
            const SizedBox(width: AppDimensions.spacingSm),
          ],
          Container(
            width: 3,
            height: 14,
            margin: const EdgeInsets.only(right: AppDimensions.spacingMd),
            decoration: BoxDecoration(
              color: color,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          Flexible(
            child: Text(
              title,
              style: Theme.of(context).textTheme.labelMedium?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
