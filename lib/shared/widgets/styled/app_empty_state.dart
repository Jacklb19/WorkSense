import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/theme/app_theme_extensions.dart';

class AppEmptyState extends StatelessWidget {
  const AppEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.action,
    this.actionLabel,
    this.actionIcon,
    this.onAction,
    this.iconColor,
    this.titleStyle,
    this.subtitleStyle,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final Widget? action;
  final String? actionLabel;
  final IconData? actionIcon;
  final VoidCallback? onAction;
  final Color? iconColor;
  final TextStyle? titleStyle;
  final TextStyle? subtitleStyle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final onSurface = context.appOnSurface;
    final onSurfaceSecondary = context.appOnSurfaceSecondary;
    final color = iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.38);

    return Semantics(
      label: '$title${subtitle != null ? '. $subtitle' : ''}',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing48),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(AppDimensions.spacing24),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                  border: Border.all(color: color.withValues(alpha: 0.16)),
                ),
                child: Icon(
                  icon,
                  size: AppDimensions.iconEmptyStateLg,
                  color: color.withValues(alpha: 0.47),
                ),
              )
                  .animate()
                  .fadeIn(duration: AppAnimations.fast, curve: AppAnimations.entranceCurve)
                  .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1)),
              const SizedBox(height: AppDimensions.spacingXxl),
              Text(
                title,
                style: titleStyle ??
                    theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                textAlign: TextAlign.center,
              ).animate().fadeIn(
                    delay: AppAnimations.fast,
                    duration: AppAnimations.normal,
                  ),
              if (subtitle != null) ...[
                const SizedBox(height: AppDimensions.spacingMd),
                Text(
                  subtitle!,
                  style: subtitleStyle ??
                      theme.textTheme.bodySmall?.copyWith(
                        color: onSurfaceSecondary,
                      ),
                  textAlign: TextAlign.center,
                ).animate().fadeIn(
                      delay: AppAnimations.normal,
                      duration: AppAnimations.normal,
                    ),
              ],
              if (action != null) ...[
                const SizedBox(height: AppDimensions.spacingXxl),
                action!,
              ] else if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: AppDimensions.spacing24),
                FilledButton.icon(
                  onPressed: onAction,
                  icon: Icon(actionIcon ?? Icons.add),
                  label: Text(actionLabel!),
                ).animate().fadeIn(
                      delay: AppAnimations.slow,
                      duration: AppAnimations.normal,
                    ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
