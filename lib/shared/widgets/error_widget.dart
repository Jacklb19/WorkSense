import 'package:flutter/material.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_strings.dart';
import 'package:worksense_app/core/theme/app_theme_extensions.dart';

class AppErrorWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  final IconData icon;

  const AppErrorWidget({
    super.key,
    required this.message,
    this.onRetry,
    this.icon = Icons.error_outline,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final errorColor = theme.colorScheme.error;
    return Semantics(
      liveRegion: true,
      label: '${AppStrings.somethingWentWrong}. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: errorColor, size: AppDimensions.iconEmptyState),
              const SizedBox(height: AppDimensions.spacingXxl),
              Text(
                AppStrings.somethingWentWrong,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: context.appOnSurfaceSecondary),
                textAlign: TextAlign.center,
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              if (onRetry != null) ...[
                const SizedBox(height: AppDimensions.spacing20),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text(AppStrings.retryButton),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class ErrorBannerWidget extends StatelessWidget {
  final String message;
  final VoidCallback? onDismiss;

  const ErrorBannerWidget({super.key, required this.message, this.onDismiss});

  @override
  Widget build(BuildContext context) {
    final errorColor = Theme.of(context).colorScheme.error;
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spacingXxl),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: errorColor.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: errorColor.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(Icons.error_outline, color: errorColor, size: AppDimensions.iconSm),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(child: Text(message, style: TextStyle(color: errorColor, fontSize: AppDimensions.fontBody))),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Cerrar',
                icon: Icon(Icons.close, size: AppDimensions.iconMd),
                color: errorColor,
                onPressed: onDismiss,
                padding: const EdgeInsets.all(AppDimensions.spacingXs),
                constraints: const BoxConstraints(minWidth: 48, minHeight: 48),
              ),
          ],
        ),
      ),
    );
  }
}