import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'app_colors.dart';
import '../constants/app_dimensions.dart';

abstract final class AppTextStyles {
  AppTextStyles._();

  static TextTheme get light => GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplayLg, fontWeight: FontWeight.w400, letterSpacing: -0.25,
      color: AppColors.lightTextPrimary,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplay, fontWeight: FontWeight.w400, letterSpacing: -0.5,
      color: AppColors.lightTextPrimary,
    ),
    displaySmall: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplaySm, fontWeight: FontWeight.w400,
      color: AppColors.lightTextPrimary,
    ),
    headlineLarge: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplay, fontWeight: FontWeight.w800,
      color: AppColors.lightTextPrimary,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplaySm, fontWeight: FontWeight.w700,
      color: AppColors.lightTextPrimary,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplayXs, fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: AppDimensions.fontHeadlineLg, fontWeight: FontWeight.w600,
      color: AppColors.lightTextPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w600, letterSpacing: 0.15,
      color: AppColors.lightTextPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: AppDimensions.fontBodyMd, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: AppColors.lightTextPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w400, letterSpacing: 0.5,
      color: AppColors.lightTextPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: AppDimensions.fontBodyMd, fontWeight: FontWeight.w400, letterSpacing: 0.25,
      color: AppColors.lightTextPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: AppDimensions.fontCaption, fontWeight: FontWeight.w400, letterSpacing: 0.4,
      color: AppColors.lightTextSecondary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: AppDimensions.fontBodyMd, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: AppColors.lightTextPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: AppDimensions.fontCaption, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: AppColors.lightTextPrimary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: AppColors.lightTextSecondary,
    ),
  );

  static TextTheme get dark => GoogleFonts.interTextTheme(
    ThemeData(brightness: Brightness.dark).textTheme,
  ).copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplayLg, fontWeight: FontWeight.w400, letterSpacing: -1,
      color: AppColors.textPrimary,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplay, fontWeight: FontWeight.w400, letterSpacing: -0.5,
      color: AppColors.textPrimary,
    ),
    displaySmall: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplaySm, fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    headlineLarge: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplay, fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplaySm, fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.spaceGrotesk(
      fontSize: AppDimensions.fontDisplayXs, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: AppDimensions.fontHeadlineLg, fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w600, letterSpacing: 0.15,
      color: AppColors.textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: AppDimensions.fontBodyMd, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: AppColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w400, letterSpacing: 0.5,
      color: AppColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: AppDimensions.fontBodyMd, fontWeight: FontWeight.w400, letterSpacing: 0.25,
      color: AppColors.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: AppDimensions.fontCaption, fontWeight: FontWeight.w400, letterSpacing: 0.4,
      color: AppColors.textSecondary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: AppDimensions.fontBodyMd, fontWeight: FontWeight.w600, letterSpacing: 0.1,
      color: AppColors.textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: AppDimensions.fontCaption, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: AppColors.textPrimary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w500, letterSpacing: 0.5,
      color: AppColors.textSecondary,
    ),
  );

  // ── Domain-specific (dark theme) ──────────────────────────
  static const TextStyle stateBadge = TextStyle(
    fontSize: AppDimensions.fontBody, fontWeight: FontWeight.w700, letterSpacing: 1.2,
    color: AppColors.white,
  );

  static const TextStyle productivityScore = TextStyle(
    fontSize: AppDimensions.fontDisplayLg, fontWeight: FontWeight.w700,
    color: AppColors.primary,
  );

  static const TextStyle roleChip = TextStyle(
    fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w600, letterSpacing: 0.8,
    color: AppColors.white,
  );

  static const TextStyle sectionLabel = TextStyle(
    fontSize: AppDimensions.fontCaption, fontWeight: FontWeight.w700, letterSpacing: 1.5,
    color: AppColors.primary,
  );

  static const TextStyle cardTitle = TextStyle(
    fontSize: AppDimensions.fontSubtitle, fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle statValue = TextStyle(
    fontSize: AppDimensions.fontHeadlineLg, fontWeight: FontWeight.w800,
    color: AppColors.textPrimary,
  );

  static const TextStyle badgeText = TextStyle(
    fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w600, letterSpacing: 0.5,
    color: AppColors.white,
  );

  static const TextStyle kioskTitle = TextStyle(
    fontSize: AppDimensions.fontDisplaySm, fontWeight: FontWeight.w800, letterSpacing: 2,
    color: AppColors.white,
  );

  static const TextStyle syncCounter = TextStyle(
    fontSize: AppDimensions.fontCaption, fontWeight: FontWeight.w500,
    color: AppColors.textSecondary,
  );
}