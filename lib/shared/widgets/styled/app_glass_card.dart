import 'dart:ui' show ImageFilter;

import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_theme_colors.dart';

class AppGlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final List<BoxShadow>? boxShadow;
  final VoidCallback? onTap;
  final double? height;
  final double? width;

  const AppGlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.backgroundColor,
    this.borderColor,
    this.boxShadow,
    this.onTap,
    this.height,
    this.width,
  });

  @override
  Widget build(BuildContext context) {
    // ✅ La decoración exterior (sombra, borde) vive en Container.
    // ✅ ClipRRect recorta tanto el BackdropFilter como el InkWell,
    //    así el ripple queda confinado a las esquinas redondeadas.
    return Container(
      width: width,
      height: height,
      margin: margin,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(
          color: borderColor ?? AppColors.glassBorder,
          width: 1.0,
        ),
        boxShadow: boxShadow ??
            [
              BoxShadow(
                color: AppColors.primary.withAlpha(8),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(borderRadius),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Builder(
            builder: (context) => Material(
              // El color va aquí, dentro del ClipRRect, para que el ripple lo respete.
              color: backgroundColor ?? context.appColors.card,
              child: InkWell(
                onTap: onTap, // null → InkWell sin respuesta, ningún impacto de perf
                borderRadius: BorderRadius.circular(borderRadius),
                child: Padding(
                  padding: padding ?? const EdgeInsets.all(20.0),
                  child: child,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
