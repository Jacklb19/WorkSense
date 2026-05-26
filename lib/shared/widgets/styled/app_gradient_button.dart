import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/constants/app_dimensions.dart';

class AppGradientButton extends StatelessWidget {
  const AppGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.isLoading = false,
  });

  final String label;
  final VoidCallback onPressed;
  final IconData? icon;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final gradient = isDark ? AppGradients.primaryButton : AppGradients.lightPrimaryButton;

    return Semantics(
      button: true,
      label: isLoading ? '$label - Cargando' : label,
      enabled: !isLoading,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: gradient,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: AppColors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          child: InkWell(
            onTap: isLoading ? null : onPressed,
            borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
            child: SizedBox(
              height: AppDimensions.buttonMinHeight,
              child: Center(
                child: isLoading
                    ? const SizedBox(
                        width: AppDimensions.progressIndicatorSize,
                        height: AppDimensions.progressIndicatorSize,
                        child: CircularProgressIndicator(
                          strokeWidth: AppDimensions.progressStrokeWidth,
                          color: AppColors.white,
                        ),
                      )
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: AppDimensions.iconMd, color: AppColors.white),
                            const SizedBox(width: AppDimensions.spacingMd),
                          ],
                          Text(
                            label,
                            style: const TextStyle(
                              fontSize: AppDimensions.fontTitle,
                              fontWeight: FontWeight.w700,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}