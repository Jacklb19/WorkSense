import 'package:flutter/material.dart';
import 'package:worksense_app/core/theme/app_colors.dart';
import 'package:worksense_app/core/constants/app_dimensions.dart';

class AppIconCircle extends StatelessWidget {
  const AppIconCircle({
    super.key,
    required this.icon,
    this.color = AppColors.primary,
    this.backgroundColor,
    this.size = AppDimensions.iconEmptyStateLg,
    this.iconSize = AppDimensions.iconLg,
  });

  final IconData icon;
  final Color color;
  final Color? backgroundColor;
  final double size;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: backgroundColor ?? color.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: Icon(icon, size: iconSize, color: color),
    );
  }
}