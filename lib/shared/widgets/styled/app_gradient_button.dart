import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

class AppGradientButton extends StatelessWidget {
  final String label;
  final IconData? icon;
  final VoidCallback? onPressed;
  final bool isLoading;
  final List<Color>? gradient;
  final double height;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const AppGradientButton({
    super.key,
    required this.label,
    this.icon,
    this.onPressed,
    this.isLoading = false,
    this.gradient,
    this.height = 56.0,
    this.borderRadius = 16.0,
    this.padding,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    final grad = gradient ?? AppColors.gradientButton;

    return Container(
      width: double.infinity,
      height: height,
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: grad),
        borderRadius: BorderRadius.circular(borderRadius),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withAlpha(60),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Padding(
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 24),
            child: Center(
              child: AnimatedSwitcher(
                duration: AppDimensions.animNormal,
                child: isLoading
                    ? SizedBox(
                        key: const ValueKey('loading'),
                        width: 24,
                        height: 24,
                        child: const CircularProgressIndicator(
                          strokeWidth: 2,
                          color: AppColors.white,
                        ),
                      )
                    : Row(
                        key: const ValueKey('content'),
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, color: AppColors.white, size: 20),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            style: textStyle ??
                                Theme.of(context).textTheme.labelLarge?.copyWith(
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: 1.0,
                                    ),
                          ),
                        ],
                      ),
              ),
            ),
          ),
        ),
      ),
    ).animate(target: onPressed == null ? 0 : 1).shimmer(
          duration: 1000.ms,
          color: AppColors.white.withAlpha(8),
        );
  }
}
