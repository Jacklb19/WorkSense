import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Theme-aware color helpers for presentation layer (replaces `*Dark` aliases).
///
/// Usage: `context.appCard` instead of `AppColors.cardDark`,
///        `context.appOnSurface` instead of `AppColors.textPrimaryDark`, etc.
extension AppThemeContext on BuildContext {
  ColorScheme get cs => Theme.of(this).colorScheme;

  bool get isDark => Theme.of(this).brightness == Brightness.dark;

  // ── Surfaces ──────────────────────────────────────────────────
  Color get appBackground => cs.surfaceContainerLowest;

  Color get appSurface => cs.surface;

  Color get appCard => cs.surfaceContainer;

  Color get appSurfaceContainerHigh => cs.surfaceContainerHigh;

  Color get appSurfaceContainerHighest => cs.surfaceContainerHighest;

  // ── Text ──────────────────────────────────────────────────────
  Color get appOnSurface => cs.onSurface;

  Color get appOnSurfaceSecondary =>
      Theme.of(this).textTheme.bodySmall?.color ?? cs.onSurface.withValues(alpha: 0.62);

  Color get appOnSurfaceDisabled => cs.onSurface.withValues(alpha: 0.38);

  Color get appOnPrimary => cs.onPrimary;

  // ── Borders & Overlays ────────────────────────────────────────
  Color get appGlassBorder => isDark
      ? AppColors.glassBorder
      : AppColors.lightGlassBorder;

  Color get appDivider => cs.outline;

  // ── Semantic ──────────────────────────────────────────────────
  Color get appError => cs.error;

  Color get appPrimary => cs.primary;

  Color tabUnselectedLabelColor() =>
      cs.onSurface.withValues(alpha: 0.38);
}