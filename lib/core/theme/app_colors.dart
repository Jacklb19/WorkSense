import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────
  static const Color primary = Color(0xFF1E88E5);
  static const Color primaryDark = Color(0xFF1565C0);
  static const Color primaryLight = Color(0xFF64B5F6);

  static const Color secondary = Color(0xFF26A69A);
  static const Color secondaryDark = Color(0xFF00796B);
  static const Color secondaryLight = Color(0xFF80CBC4);

  // ── Texto ─────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1C1E);
  static const Color textSecondaryLight = Color(0xFF42474E);
  static const Color textDisabledLight = Color(0xFF72777F);

  static const Color textPrimaryDark = Color(0xFFE2E2E6);
  static const Color textSecondaryDark = Color(0xFFC1C7CE);
  static const Color textDisabledDark = Color(0xFF8B9199);

  // ── Divider ───────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFC4C7D0);
  static const Color dividerDark = Color(0xFF44474E);

  // ── Gradients ───────────────────────────────────────────
  static const List<Color> mainGradient = [primary, Color(0xFF1976D2)];
  static const List<Color> surfaceGradient = [Color(0xFF2C2C2C), Color(0xFF1E1E1E)];

  // ── Actividad (AI Pipeline) ─────────────────────────────
  static const Color stateWorking = Color(0xFF4CAF50);    // Emerald
  static const Color stateInactive = Color(0xFF9E9E9E);   // Steel
  static const Color stateAbsent = Color(0xFFF44336);     // Crimson
  static const Color stateDistracted = Color(0xFFFFB300); // Amber
  static const Color stateFatigue = Color(0xFFFF7043);    // Coral
  static const Color stateOutsideArea = Color(0xFF4FC3F7);  // Sky
  static const Color stateNotIdentified = Color(0xFF78909C); // Slate

  // ── Neutros ───────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color grey50 = Color(0xFFFAFAFA);
  static const Color grey100 = Color(0xFFF5F5F5);
  static const Color grey200 = Color(0xFFEEEEEE);
  static const Color grey300 = Color(0xFFE0E0E0);
  static const Color grey400 = Color(0xFFBDBDBD);
  static const Color grey500 = Color(0xFF9E9E9E);
  static const Color grey600 = Color(0xFF757575);
  static const Color grey700 = Color(0xFF616161);
  static const Color grey800 = Color(0xFF424242);
  static const Color grey900 = Color(0xFF212121);

  // ── Fondo y superficies (Light) ───────────────────────────
  static const Color backgroundLight = Color(0xFFF8F9FD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Fondo y superficies (Dark) ────────────────────────────
  static const Color backgroundDark = Color(0xFF0F1115);
  static const Color surfaceDark = Color(0xFF1A1D24);
  static const Color cardDark = Color(0xFF222831);

  // ── Feedback ─────────────────────────────────────────────
  static const Color success = Color(0xFF43A047);
  static const Color warning = Color(0xFFFFA000);
  static const Color error = Color(0xFFD81B60);
  static const Color info = Color(0xFF1E88E5);

  static Color successSoft = success.withOpacity(0.1);
  static Color warningSoft = warning.withOpacity(0.1);
  static Color errorSoft = error.withOpacity(0.1);
  static Color infoSoft = info.withOpacity(0.1);

  // ── Glassmorphism & Overlays ──────────────────────────────
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBlack = Color(0x66000000);
  static const Color overlayBadgeBg = Color(0xCC1A1D24);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ── Scan Feedback ──────────────────────────────────────────
  static const Color feedbackDetected = Color(0xFF00E676);
  static const Color feedbackError = Color(0xFFFF1744);
  static const Color feedbackCapturing = Color(0xFF00B0FF);
  static const Color feedbackSearching = Color(0xFFFFEA00);

  // ── Identity Confidence ────────────────────────────────────
  static const Color identityHigh = Color(0xFF00E676);
  static const Color identityMedium = Color(0xFFFFD600);
  static const Color identityLow = Color(0xFFFF1744);

  // ── Overlay Painter ────────────────────────────────────────
  static const Color overlayCyanDot = Color(0xFF00E5FF);
  static const Color overlayCyanLine = Color(0xFF00B8D4);
  static const Color overlayRedDot = Color(0xFFFF5252);
  static const Color overlayRedLine = Color(0xFFFF1744);
  static const Color overlayBlueFill = Color(0xFF1E88E5);
  static const Color overlayFaceRect = Color(0xFF00E5FF);

  // ── Sync Status ──────────────────────────────────────────────
  static const Color syncOffline = Color(0xFF78909C);
  static const Color syncUploading = Color(0xFFFFB74D);
  static const Color syncOk = Color(0xFF66BB6A);
  static const Color syncPending = Color(0xFFFFB74D);
  static const Color badgeRed = Color(0xFFEF5350);

  // ── Error Background ────────────────────────────────────────
  static const Color errorBg = Color(0x1AD81B60);

  // ── Alert Colors ────────────────────────────────────────────
  static const Color alertAbsent = Color(0xFFF44336);
  static const Color alertDistracted = Color(0xFFFF9800);
  static const Color orangeWarning = Color(0xFFFF9800);

  AppColors._();
}