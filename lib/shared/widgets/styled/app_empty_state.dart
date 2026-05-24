import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

class AppEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? iconColor;

  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = iconColor ?? AppColors.textDisabled;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(AppDimensions.spacing32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(AppDimensions.spacing24),
              decoration: BoxDecoration(
                color: color.withAlpha(20),
                shape: BoxShape.circle,
                border: Border.all(color: color.withAlpha(40)),
              ),
              child: Icon(
                icon,
                size: AppDimensions.iconEmptyState,
                color: color.withAlpha(120),
              ),
            ).animate().fadeIn(
                  duration: AppDimensions.animEntrance,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: AppDimensions.spacing24),
            Text(
              title,
              style: theme.textTheme.titleMedium?.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
              textAlign: TextAlign.center,
            ).animate().fadeIn(
                  delay: AppDimensions.animNormal,
                  duration: AppDimensions.animEntrance,
                ),
            if (subtitle != null) ...[
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                subtitle!,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.textDisabled,
                ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(
                    delay: AppDimensions.animSlow,
                    duration: AppDimensions.animEntrance,
                  ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: AppDimensions.spacing32),
              FilledButton.icon(
                onPressed: onAction,
                icon: Icon(actionIcon ?? Icons.add),
                label: Text(actionLabel!),
              ).animate().fadeIn(
                    delay: AppDimensions.animEntrance,
                    duration: AppDimensions.animEntrance,
                  ),
            ],
          ],
        ),
      ),
    );
  }
}
