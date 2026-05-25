import 'package:flutter/painting.dart';
import 'app_colors.dart';

abstract final class AppGradients {
  AppGradients._();

  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: AppColors.gradientBackground,
  );

  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.gradientCard,
  );

  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.gradientButton,
  );

  static const LinearGradient accentGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: AppColors.gradientAccent,
  );

  static const LinearGradient kioskOverlayTop = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: AppColors.gradientOverlay,
  );

  static const LinearGradient kioskOverlayBottom = LinearGradient(
    begin: Alignment.bottomCenter,
    end: Alignment.topCenter,
    colors: AppColors.gradientOverlay,
  );

  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [
      AppColors.shimmerBase,
      AppColors.shimmerHighlight,
      AppColors.shimmerBase,
    ],
  );

  static const LinearGradient glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.glassHighlight,
      AppColors.glassSurface,
    ],
  );

  static const LinearGradient successGlow = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [
      AppColors.success,
      Color(0xFF16A34A),
    ],
  );
}
