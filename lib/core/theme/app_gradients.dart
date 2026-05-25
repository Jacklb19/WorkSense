import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppGradients {
  AppGradients._();

  // ── Dark theme gradients ──────────────────────────────────
  static const LinearGradient background = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.background, AppColors.surface],
  );

  static const LinearGradient card = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.card, AppColors.surfaceContainer],
  );

  static const LinearGradient primaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primary, AppColors.secondary],
  );

  static const LinearGradient accentGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primary10, AppColors.background],
  );

  static const LinearGradient kioskOverlay = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.black12, AppColors.black45],
  );

  static const LinearGradient shimmer = LinearGradient(
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
    colors: [AppColors.surface, AppColors.surfaceContainerHigh, AppColors.surface],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient glassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.white10, AppColors.white5],
  );

  static const LinearGradient successGlow = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.successDark, AppColors.success],
  );

  // ── Light theme gradients ─────────────────────────────────
  static const LinearGradient lightBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.lightBackground, AppColors.lightSurface],
  );

  static const LinearGradient lightCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.lightCard, AppColors.lightSurfaceContainer],
  );

  static const LinearGradient lightPrimaryButton = LinearGradient(
    begin: Alignment.centerLeft,
    end: Alignment.centerRight,
    colors: [AppColors.primaryDark, AppColors.primary],
  );

  static const LinearGradient lightAccentGlow = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [AppColors.primary5, AppColors.lightBackground],
  );

  static const LinearGradient lightShimmer = LinearGradient(
    begin: Alignment(-1.0, 0.0),
    end: Alignment(1.0, 0.0),
    colors: [AppColors.lightSurface, AppColors.lightSurfaceContainerHigh, AppColors.lightSurface],
    stops: [0.0, 0.5, 1.0],
  );

  static const LinearGradient lightGlassCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [AppColors.white, AppColors.grey100],
  );
}