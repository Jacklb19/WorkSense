import 'package:flutter/material.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  // ── Display ──────────────────────────────────────────────────
  static const TextStyle displayLarge = TextStyle(
    fontSize: 48,
    fontWeight: FontWeight.w800,
    letterSpacing: -1.0,
    fontFamily: 'SpaceGrotesk',
  );
  static const TextStyle displayMedium = TextStyle(
    fontSize: 40,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.5,
    fontFamily: 'SpaceGrotesk',
  );
  static const TextStyle displaySmall = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.w700,
    fontFamily: 'SpaceGrotesk',
  );

  // ── Headline ─────────────────────────────────────────────────
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );
  static const TextStyle headlineMedium = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );
  static const TextStyle headlineSmall = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );

  // ── Title ────────────────────────────────────────────────────
  static const TextStyle titleLarge = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );
  static const TextStyle titleMedium = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );
  static const TextStyle titleSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    fontFamily: 'Inter',
  );

  // ── Body ─────────────────────────────────────────────────────
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
  );
  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
  );
  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w400,
    fontFamily: 'Inter',
  );

  // ── Label ────────────────────────────────────────────────────
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    fontFamily: 'Inter',
  );
  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    fontFamily: 'Inter',
  );
  static const TextStyle labelSmall = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    fontFamily: 'Inter',
  );

  // ── Seccion ──────────────────────────────────────────────────
  static const TextStyle sectionLabel = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.5,
    color: AppColors.primary,
    fontFamily: 'Inter',
  );

  // ── Card ─────────────────────────────────────────────────────
  static const TextStyle cardTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    fontFamily: 'Inter',
  );
  static const TextStyle cardSubtitle = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
    fontFamily: 'Inter',
  );

  // ── Nav ──────────────────────────────────────────────────────
  static const TextStyle navBarLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    fontFamily: 'Inter',
  );

  // ── Stats ────────────────────────────────────────────────────
  static const TextStyle statValue = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.w800,
    color: AppColors.primary,
    fontFamily: 'SpaceGrotesk',
  );
  static const TextStyle statLabel = TextStyle(
    fontSize: 10,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    letterSpacing: 0.8,
    fontFamily: 'Inter',
  );

  // ── Badges ───────────────────────────────────────────────────
  static const TextStyle badgeText = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.8,
    color: AppColors.white,
    fontFamily: 'Inter',
  );

  // ── Kiosk ────────────────────────────────────────────────────
  static const TextStyle kioskTitle = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w900,
    letterSpacing: 2.0,
    color: AppColors.white,
    fontFamily: 'SpaceGrotesk',
  );
  static const TextStyle kioskSubtitle = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textSecondary,
    fontFamily: 'Inter',
  );

  // ── Botones ──────────────────────────────────────────────────
  static const TextStyle buttonText = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 1.0,
    color: AppColors.white,
    fontFamily: 'Inter',
  );

  // ── Empty State ──────────────────────────────────────────────
  static const TextStyle emptyTitle = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w700,
    color: AppColors.textSecondary,
    fontFamily: 'Inter',
  );
  static const TextStyle emptySubtitle = TextStyle(
    fontSize: 13,
    fontWeight: FontWeight.w400,
    color: AppColors.textDisabled,
    fontFamily: 'Inter',
  );

  AppTextStyles._();
}
