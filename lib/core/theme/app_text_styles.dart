import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

/// Text styles centralizados de WorkSense — Inter font family.
/// Usar siempre a través de Theme.of(context).textTheme o directamente.
abstract final class AppTextStyles {
  AppTextStyles._();

  /// Base Inter text style — all other styles derive from this.
  static TextStyle get _inter => GoogleFonts.inter();

  // ── Display ───────────────────────────────────────────────
  static TextStyle get displayLarge => _inter.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get displayMedium => _inter.copyWith(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get displaySmall => _inter.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  // ── Headline ──────────────────────────────────────────────
  static TextStyle get headlineLarge => _inter.copyWith(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineMedium => _inter.copyWith(
    fontSize: 22,
    fontWeight: FontWeight.w700,
    color: AppColors.textPrimary,
  );

  static TextStyle get headlineSmall => _inter.copyWith(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Title ─────────────────────────────────────────────────
  static TextStyle get titleLarge => _inter.copyWith(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleMedium => _inter.copyWith(
    fontSize: 17,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get titleSmall => _inter.copyWith(
    fontSize: 15,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  // ── Body ──────────────────────────────────────────────────
  static TextStyle get bodyLarge => _inter.copyWith(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodyMedium => _inter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimary,
  );

  static TextStyle get bodySmall => _inter.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    color: AppColors.textSecondary,
  );

  // ── Label ─────────────────────────────────────────────────
  static TextStyle get labelLarge => _inter.copyWith(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelMedium => _inter.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static TextStyle get labelSmall => _inter.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.textSecondary,
  );

  // ── WorkSense-specific styles ─────────────────────────────

  /// Badge de estado del AI (TRABAJANDO, AUSENTE, etc.)
  static TextStyle get stateBadge => _inter.copyWith(
    fontSize: 10,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.5,
    color: AppColors.white,
  );

  /// Porcentaje grande en tarjetas de productividad
  static TextStyle get productivityScore => _inter.copyWith(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  /// Etiqueta de rol de usuario (chip)
  static TextStyle get roleChip => _inter.copyWith(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.white,
  );

  /// Contador de sync pendientes
  static TextStyle get syncCounter => _inter.copyWith(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}