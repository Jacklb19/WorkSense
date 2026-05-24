import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_gradients.dart';
import '../../../core/theme/app_animations.dart';
import '../../../core/constants/app_dimensions.dart';

class AppGradientButton extends StatefulWidget {
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
  State<AppGradientButton> createState() => _AppGradientButtonState();
}

class _AppGradientButtonState extends State<AppGradientButton> {
  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppGradients.primaryButton,
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
          onTap: widget.isLoading ? null : widget.onPressed,
          borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
          child: SizedBox(
            height: AppDimensions.buttonMinHeight,
            child: Center(
              child: widget.isLoading
                  ? const SizedBox(
                      width: AppDimensions.progressIndicatorSize, height: AppDimensions.progressIndicatorSize,
                      child: CircularProgressIndicator(
                        strokeWidth: AppDimensions.progressStrokeWidth,
                        color: AppColors.white,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.icon != null) ...[
                          Icon(widget.icon, size: AppDimensions.iconMd, color: AppColors.white),
                          const SizedBox(width: AppDimensions.spacingMd),
                        ],
                        Text(
                          widget.label,
                          style: const TextStyle(
                            fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white,
                          ),
                        ),
                      ],
                    ),
            ),
          ),
        ),
      ),
    )
    .animate()
    .fadeIn(duration: AppAnimations.fast);
  }
}