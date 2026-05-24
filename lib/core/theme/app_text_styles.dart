import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  static TextTheme get light => GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -0.25,
      color: AppColors.textPrimaryLight,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: -0.5,
      color: AppColors.textPrimaryLight,
    ),
    displaySmall: GoogleFonts.spaceGrotesk(
      fontSize: 36, fontWeight: FontWeight.w400,
      color: AppColors.textPrimaryLight,
    ),
    headlineLarge: GoogleFonts.spaceGrotesk(
      fontSize: 32, fontWeight: FontWeight.w800,
      color: AppColors.textPrimaryLight,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 28, fontWeight: FontWeight.w700,
      color: AppColors.textPrimaryLight,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: 24, fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w600,
      color: AppColors.textPrimaryLight,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15,
      color: AppColors.textPrimaryLight,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: AppColors.textPrimaryLight,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5,
      color: AppColors.textPrimaryLight,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25,
      color: AppColors.textPrimaryLight,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4,
      color: AppColors.textSecondaryLight,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: AppColors.textPrimaryLight,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: AppColors.textPrimaryLight,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: AppColors.textSecondaryLight,
    ),
  );

  static TextTheme get dark => GoogleFonts.interTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  ).copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 57, fontWeight: FontWeight.w400, letterSpacing: -1,
      color: AppColors.textPrimary,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: 45, fontWeight: FontWeight.w400, letterSpacing: -0.5,
      color: AppColors.textPrimary,
    ),
    displaySmall: GoogleFonts.spaceGrotesk(
      fontSize: 36, fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    headlineLarge: GoogleFonts.spaceGrotesk(
      fontSize: 32, fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: 28, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: 24, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 22, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w600, letterSpacing: 0.15,
      color: AppColors.textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: AppColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16, fontWeight: FontWeight.w400, letterSpacing: 0.5,
      color: AppColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w400, letterSpacing: 0.25,
      color: AppColors.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w400, letterSpacing: 0.4,
      color: AppColors.textSecondary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: AppColors.textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: AppColors.textPrimary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: AppColors.textSecondary,
    ),
  );

  // ── Domain-specific (dark theme) ──────────────────────────
  static const TextStyle stateBadge = TextStyle(
    fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 1.2,
    color: AppColors.white,
  );

  static const TextStyle productivityScore = TextStyle(
    fontSize: 48, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle roleChip = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
    color: AppColors.white,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 1.5,
    color: AppColors.primary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: 15, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: 22, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.5,
    color: AppColors.white,
  );

  static const TextStyle kioskTitle = TextStyle(
    fontSize: 28, fontWeight: FontWeight.w800, letterSpacing: 2,
    color: AppColors.white,
  );

  static const TextStyle syncCounter = TextStyle(
    fontSize: 12, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}