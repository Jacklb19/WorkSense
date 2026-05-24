import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand (Electric Blue) ────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1D4ED8);
  static const Color primaryLight = Color(0xFF93C5FD);
  static const Color accent = Color(0xFF60A5FA);
  static const Color accentCyan = Color(0xFF22D3EE);

  // ── Secondary (Cyan) ─────────────────────────────────────────
  static const Color secondary = Color(0xFF06B6D4);
  static const Color secondaryDark = Color(0xFF0891B2);
  static const Color secondaryLight = Color(0xFF67E8F9);

  // ── Texto ────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF475569);
  static const Color textOnAccent = Color(0xFF0F172A);

  // ── Divider ──────────────────────────────────────────────────
  static const Color divider = Color(0xFF1E293B);
  static const Color dividerSubtle = Color(0xFF334155);

  // ── Surfaces ─────────────────────────────────────────────────
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF1E293B);
  static const Color elevated = Color(0xFF273247);

  // ── Glassmorphism ────────────────────────────────────────────
  static const Color glassSurface = Color(0x0DFFFFFF);
  static const Color glassBorder = Color(0x14FFFFFF);
  static const Color glassHighlight = Color(0x1AFFFFFF);

  // ── Base ─────────────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // ── Neutral Scale ────────────────────────────────────────────
  static const Color neutral50 = Color(0xFFF8FAFC);
  static const Color neutral100 = Color(0xFFF1F5F9);
  static const Color neutral200 = Color(0xFFE2E8F0);
  static const Color neutral300 = Color(0xFFCBD5E1);
  static const Color neutral400 = Color(0xFF94A3B8);
  static const Color neutral500 = Color(0xFF64748B);
  static const Color neutral600 = Color(0xFF475569);
  static const Color neutral700 = Color(0xFF334155);
  static const Color neutral800 = Color(0xFF1E293B);
  static const Color neutral900 = Color(0xFF0F172A);

  // ── Neutral aliases (backward compatibility) ─────────────────
  static const Color grey50 = neutral50;
  static const Color grey100 = neutral100;
  static const Color grey200 = neutral200;
  static const Color grey300 = neutral300;
  static const Color grey400 = neutral400;
  static const Color grey500 = neutral500;
  static const Color grey600 = neutral600;
  static const Color grey700 = neutral700;
  static const Color grey800 = neutral800;
  static const Color grey900 = neutral900;

  // ── Backward compatibility aliases ───────────────────────────
  static const Color backgroundDark = background;
  static const Color surfaceDark = surface;
  static const Color cardDark = card;

  // ── Feedback ─────────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // ── Feedback Soft ────────────────────────────────────────────
  static const Color successSoft = Color(0x1A22C55E);
  static const Color warningSoft = Color(0x1AF59E0B);
  static const Color errorSoft = Color(0x1AEF4444);
  static const Color infoSoft = Color(0x1A3B82F6);

  // ── Shimmer / Skeleton ───────────────────────────────────────
  static const Color shimmerBase = Color(0xFF1E293B);
  static const Color shimmerHighlight = Color(0xFF334155);

  // ── Gradients ────────────────────────────────────────────────
  static const List<Color> gradientBackground = [
    Color(0xFF0A0E17),
    Color(0xFF111827),
    Color(0xFF0A0E17),
  ];
  static const List<Color> gradientCard = [card, elevated];
  static const List<Color> gradientButton = [primary, primaryDark];
  static const List<Color> gradientAccent = [accent, accentCyan];
  static const List<Color> gradientOverlay = [
    Color(0x000A0E17),
    Color(0xFF0A0E17),
  ];

  // ── Actividad (AI Pipeline) ──────────────────────────────────
  static const Color stateWorking = Color(0xFF4CAF50);
  static const Color stateInactive = Color(0xFF9E9E9E);
  static const Color stateAbsent = Color(0xFFF44336);
  static const Color stateDistracted = Color(0xFFFFB300);
  static const Color stateFatigue = Color(0xFFFF7043);
  static const Color stateOutsideArea = Color(0xFF4FC3F7);
  static const Color stateNotIdentified = Color(0xFF78909C);

  // ── Scan Feedback ────────────────────────────────────────────
  static const Color feedbackDetected = Color(0xFF00E676);
  static const Color feedbackError = Color(0xFFFF1744);
  static const Color feedbackCapturing = Color(0xFF00B0FF);
  static const Color feedbackSearching = Color(0xFFFFEA00);

  // ── Identity Confidence ──────────────────────────────────────
  static const Color identityHigh = Color(0xFF00E676);
  static const Color identityMedium = Color(0xFFFFD600);
  static const Color identityLow = Color(0xFFFF1744);

  // ── Overlay Painter ──────────────────────────────────────────
  static const Color overlayCyanDot = Color(0xFF00E5FF);
  static const Color overlayCyanLine = Color(0xFF00B8D4);
  static const Color overlayRedDot = Color(0xFFFF5252);
  static const Color overlayRedLine = Color(0xFFFF1744);
  static const Color overlayBlueFill = Color(0xFF3B82F6);
  static const Color overlayFaceRect = Color(0xFF00E5FF);
  static const Color overlayBadgeBg = Color(0xCC111827);
  static const double overlayBadgePaddingH = 12.0;
  static const double overlayBadgePaddingV = 6.0;
  static const double overlayBadgeRadius = 6.0;
  static const double overlayBadgeAccentWidth = 4.0;
  static const double overlayIdentityBadgeHeight = 44.0;

  // ── Sync Status ──────────────────────────────────────────────
  static const Color syncOffline = Color(0xFF78909C);
  static const Color syncUploading = Color(0xFFFFB74D);
  static const Color syncOk = Color(0xFF66BB6A);
  static const Color syncPending = Color(0xFFFFB74D);
  static const Color badgeRed = Color(0xFFEF5350);

  // ── Alert Colors ─────────────────────────────────────────────
  static const Color alertAbsent = Color(0xFFF44336);
  static const Color alertDistracted = Color(0xFFFF9800);
  static const Color orangeWarning = Color(0xFFFF9800);

  AppColors._();
}
