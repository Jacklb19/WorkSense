import 'package:flutter/material.dart';
import 'app_colors.dart';

/// Estilos de texto centralizados de WorkSense.
/// Basados en Material 3 TextTheme para compatibilidad con ThemeData.
abstract final class AppTextStyles {
  // ── Display ───────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 57,
    fontWeight: FontWeight.w400,
    letterSpacing: -0.25,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 45,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 36,
    fontWeight: FontWeight.w400,
    color: AppColors.textPrimaryLight,
  );

  // ── Headline ──────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  // ── Title ─────────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    color: AppColors.textPrimaryLight,
  );

  // ── Body ──────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    color: AppColors.textSecondaryLight,
  );

  // ── Label ─────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.1,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textPrimaryLight,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.5,
    color: AppColors.textSecondaryLight,
  );

  // ── Específicos de WorkSense ───────────────────────────────

  /// Badge de estado del AI (TRABAJANDO, AUSENTE, etc.)
  static const TextStyle stateBadge = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.2,
    color: AppColors.white,
  );

  /// Porcentaje grande en tarjetas de productividad
  static const TextStyle productivityScore = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  /// Etiqueta de rol de usuario (chip)
  static const TextStyle roleChip = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.8,
    color: AppColors.white,
  );

  /// Contador de sync pendientes
  static const TextStyle syncCounter = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondaryLight,
  );

  AppTextStyles._();
}