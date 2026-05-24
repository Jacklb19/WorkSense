import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';

class AppAvatar extends StatelessWidget {
  final double radius;
  final String? letter;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? foregroundColor;
  final Color? borderColor;
  final Color? glowColor;
  final double borderWidth;

  const AppAvatar({
    super.key,
    this.radius = 24.0,
    this.letter,
    this.icon,
    this.backgroundColor,
    this.foregroundColor,
    this.borderColor,
    this.glowColor,
    this.borderWidth = 2.0,
  }) : assert(letter != null || icon != null);

  @override
  Widget build(BuildContext context) {
    final bg = backgroundColor ?? AppColors.primary.withAlpha(30);
    final fg = foregroundColor ?? AppColors.primary;

    return Container(
      width: radius * 2 + borderWidth * 2,
      height: radius * 2 + borderWidth * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: glowColor != null
            ? [
                BoxShadow(
                  color: glowColor!.withAlpha(50),
                  blurRadius: 12,
                  spreadRadius: 2,
                ),
              ]
            : null,
      ),
      child: CircleAvatar(
        radius: radius,
        backgroundColor: bg,
        child: icon != null
            ? Icon(icon, size: radius, color: fg)
            : Text(
                letter!.toUpperCase(),
                style: TextStyle(
                  color: fg,
                  fontWeight: FontWeight.bold,
                  fontSize: radius * 0.85,
                ),
              ),
      ),
    );
  }
}
