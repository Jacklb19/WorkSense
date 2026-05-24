import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';

class AppAvatar extends StatelessWidget {
  const AppAvatar({
    super.key,
    this.imageUrl,
    this.initials,
    this.radius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 2.0,
    this.showGlow = false,
  });

  final String? imageUrl;
  final String? initials;
  final double? radius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final bool showGlow;

  @override
  Widget build(BuildContext context) {
    final r = radius ?? AppDimensions.avatarRadiusMd;
    return Container(
      decoration: showGlow
          ? BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: (borderColor ?? AppColors.primary).withValues(alpha: 0.4),
                  blurRadius: r * 0.5,
                  spreadRadius: r * 0.1,
                ),
              ],
            )
          : null,
      child: CircleAvatar(
        radius: r,
        backgroundColor: borderColor ?? AppColors.primary,
        child: CircleAvatar(
          radius: r - borderWidth,
          backgroundColor: backgroundColor ?? AppColors.surfaceContainerHigh,
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  initials ?? '?',
                  style: TextStyle(
                    fontSize: r * 0.7,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}