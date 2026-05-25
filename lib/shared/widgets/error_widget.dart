import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';
import 'package:worksense_app/core/constants/app_strings.dart';

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
    return Semantics(
      liveRegion: true,
      label: '${AppStrings.somethingWentWrong}. $message',
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(AppDimensions.spacing24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: AppColors.error, size: AppDimensions.iconEmptyState),
              const SizedBox(height: AppDimensions.spacingXxl),
              Text(
                AppStrings.somethingWentWrong,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: AppDimensions.spacingMd),
              Text(
                message,
                style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.grey500),
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
    return Semantics(
      liveRegion: true,
      label: message,
      child: Container(
        margin: const EdgeInsets.all(AppDimensions.spacingXxl),
        padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingLg),
        decoration: BoxDecoration(
          color: AppColors.errorBg,
          borderRadius: BorderRadius.circular(AppDimensions.radiusLg),
          border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: AppColors.error, size: AppDimensions.iconSm),
            const SizedBox(width: AppDimensions.spacingMd),
            Expanded(child: Text(message, style: const TextStyle(color: AppColors.error, fontSize: AppDimensions.fontBody))),
            if (onDismiss != null)
              IconButton(
                tooltip: 'Cerrar',
                icon: const Icon(Icons.close, size: AppDimensions.iconMd),
                color: AppColors.error,
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