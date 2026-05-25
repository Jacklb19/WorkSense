import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/constants/app_dimensions.dart';
import '../../../core/theme/app_colors.dart';

class AppGlassCard extends StatelessWidget {
  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius,
    this.borderWidth,
    this.borderColor,
    this.sigmaX = 10.0,
    this.sigmaY = 10.0,
    this.color,
    this.boxShadow,
    this.onTap,
    this.height,
    this.width,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double? borderRadius;
  final double? borderWidth;
  final Color? borderColor;
  final double sigmaX;
  final double sigmaY;
  final Color? color;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  @override
  Widget build(BuildContext context) {
    final radius = borderRadius ?? AppDimensions.radiusRound;
    final card = Container(
      width: width,
      height: height,
      margin: margin ?? const EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(radius),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.03),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(radius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: sigmaX, sigmaY: sigmaY),
          child: Container(
            padding: padding ?? const EdgeInsets.all(AppDimensions.spacingXxl),
            decoration: BoxDecoration(
              color: color ?? AppColors.card.withValues(alpha: 0.6),
              borderRadius: BorderRadius.circular(radius),
              border: Border.all(
                color: borderColor ?? AppColors.glassBorder,
                width: borderWidth ?? 1,
              ),
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [AppColors.white5, AppColors.white10],
              ),
            ),
            child: child,
          ),
        ),
      ),
    );

    if (onTap != null) {
      return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(radius),
        child: card,
      );
    }

    return card;
  }
}
