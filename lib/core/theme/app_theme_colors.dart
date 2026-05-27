import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Theme-aware semantic color palette.
/// Access via [BuildContext.appColors].
class AppThemeColors extends ThemeExtension<AppThemeColors> {
  final Color background;
  final Color surface;
  final Color card;
  final Color textPrimary;
  final Color textSecondary;
  final Color textDisabled;
  final Color divider;

  const AppThemeColors({
    required this.background,
    required this.surface,
    required this.card,
    required this.textPrimary,
    required this.textSecondary,
    required this.textDisabled,
    required this.divider,
  });

  static const dark = AppThemeColors(
    background: AppColors.backgroundDark,
    surface:    AppColors.surfaceDark,
    card:       AppColors.cardDark,
    textPrimary:    AppColors.textPrimaryDark,
    textSecondary:  AppColors.textSecondaryDark,
    textDisabled:   AppColors.textDisabledDark,
    divider:    AppColors.dividerDark,
  );

  static const light = AppThemeColors(
    background: AppColors.backgroundLight,
    surface:    AppColors.surfaceLight,
    card:       AppColors.cardLight,
    textPrimary:    AppColors.textPrimaryLight,
    textSecondary:  AppColors.textSecondaryLight,
    textDisabled:   AppColors.textDisabledLight,
    divider:    AppColors.dividerLight,
  );

  @override
  AppThemeColors copyWith({
    Color? background,
    Color? surface,
    Color? card,
    Color? textPrimary,
    Color? textSecondary,
    Color? textDisabled,
    Color? divider,
  }) =>
      AppThemeColors(
        background:   background   ?? this.background,
        surface:      surface      ?? this.surface,
        card:         card         ?? this.card,
        textPrimary:  textPrimary  ?? this.textPrimary,
        textSecondary: textSecondary ?? this.textSecondary,
        textDisabled: textDisabled ?? this.textDisabled,
        divider:      divider      ?? this.divider,
      );

  @override
  AppThemeColors lerp(ThemeExtension<AppThemeColors>? other, double t) {
    if (other is! AppThemeColors) return this;
    return AppThemeColors(
      background:    Color.lerp(background,    other.background,    t)!,
      surface:       Color.lerp(surface,       other.surface,       t)!,
      card:          Color.lerp(card,          other.card,          t)!,
      textPrimary:   Color.lerp(textPrimary,   other.textPrimary,   t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textDisabled:  Color.lerp(textDisabled,  other.textDisabled,  t)!,
      divider:       Color.lerp(divider,       other.divider,       t)!,
    );
  }
}

/// Convenience accessor: `context.appColors.background` etc.
extension AppThemeColorsX on BuildContext {
  AppThemeColors get appColors =>
      Theme.of(this).extension<AppThemeColors>() ?? AppThemeColors.dark;
}
