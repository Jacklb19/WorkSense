import 'package:flutter/material.dart';

abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────
  static const Color primary      = Color(0xFF4F8EF7); // Electric blue
  static const Color primaryDark  = Color(0xFF2563EB); // Deep blue
  static const Color primaryLight = Color(0xFF93C5FD); // Soft blue

  static const Color accent       = Color(0xFF8B5CF6); // Violet
  static const Color accentLight  = Color(0xFFC4B5FD);

  static const Color secondary      = Color(0xFF06B6D4); // Cyan
  static const Color secondaryDark  = Color(0xFF0891B2);
  static const Color secondaryLight = Color(0xFF67E8F9);

  // ── Fondos (Dark) ─────────────────────────────────────────
  static const Color backgroundDark = Color(0xFF080C18); // Deep space
  static const Color surfaceDark    = Color(0xFF0F1525); // Card surface
  static const Color cardDark       = Color(0xFF141E30); // Inner card

  // ── Fondos (Light) ────────────────────────────────────────
  static const Color backgroundLight = Color(0xFFF0F4FF);
  static const Color surfaceLight    = Color(0xFFFFFFFF);
  static const Color cardLight       = Color(0xFFFFFFFF);

  // ── Texto ─────────────────────────────────────────────────
  static const Color textPrimaryDark    = Color(0xFFF1F5FF);
  static const Color textSecondaryDark  = Color(0xFF94A3B8);
  static const Color textDisabledDark   = Color(0xFF475569);

  static const Color textPrimaryLight   = Color(0xFF0F172A);
  static const Color textSecondaryLight = Color(0xFF334155);
  static const Color textDisabledLight  = Color(0xFF94A3B8);

  // ── Divider ───────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFE2E8F0);
  static const Color dividerDark  = Color(0xFF1E2A3D);

  // ── Gradients ─────────────────────────────────────────────
  static const List<Color> mainGradient    = [primary, accent];
  static const List<Color> surfaceGradient = [cardDark, backgroundDark];
  static const List<Color> primaryGradient = [Color(0xFF4F8EF7), Color(0xFF7C3AED)];
  static const List<Color> cyanGradient    = [Color(0xFF06B6D4), Color(0xFF4F8EF7)];
  static const List<Color> successGradient = [Color(0xFF10B981), Color(0xFF059669)];
  static const List<Color> warningGradient = [Color(0xFFF59E0B), Color(0xFFD97706)];
  static const List<Color> errorGradient   = [Color(0xFFEF4444), Color(0xFFDC2626)];

  // ── Estado AI ─────────────────────────────────────────────
  static const Color stateWorking       = Color(0xFF10B981);
  static const Color stateInactive      = Color(0xFF64748B);
  static const Color stateAbsent        = Color(0xFFEF4444);
  static const Color stateDistracted    = Color(0xFFF59E0B);
  static const Color stateFatigue       = Color(0xFFF97316);
  static const Color stateOutsideArea   = Color(0xFF06B6D4);
  static const Color stateNotIdentified = Color(0xFF64748B);

  // ── Neutros ───────────────────────────────────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  static const Color grey50  = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);

  // ── Feedback ─────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error   = Color(0xFFEF4444);
  static const Color info    = Color(0xFF4F8EF7);

  static Color successSoft = success.withValues(alpha: 0.12);
  static Color warningSoft = warning.withValues(alpha: 0.12);
  static Color errorSoft   = error.withValues(alpha: 0.12);
  static Color infoSoft    = info.withValues(alpha: 0.12);

  // ── Glassmorphism ─────────────────────────────────────────
  static const Color glassWhite        = Color(0x0DFFFFFF);
  static const Color glassBlack        = Color(0x80000000);
  static const Color glassBorder       = Color(0x1AFFFFFF);
  static const Color glassBorderBright = Color(0x33FFFFFF);
  static const Color overlayBadgeBg   = Color(0xCC0F1525);

  // ── Scan ──────────────────────────────────────────────────
  static const Color feedbackDetected  = Color(0xFF10B981);
  static const Color feedbackError     = Color(0xFFEF4444);
  static const Color feedbackCapturing = Color(0xFF4F8EF7);
  static const Color feedbackSearching = Color(0xFFF59E0B);

  // ── Identity ─────────────────────────────────────────────
  static const Color identityHigh   = Color(0xFF10B981);
  static const Color identityMedium = Color(0xFFF59E0B);
  static const Color identityLow    = Color(0xFFEF4444);

  // ── Overlay Painter ───────────────────────────────────────
  static const Color overlayCyanDot  = Color(0xFF06B6D4);
  static const Color overlayCyanLine = Color(0xFF0891B2);
  static const Color overlayRedDot   = Color(0xFFEF4444);
  static const Color overlayRedLine  = Color(0xFFDC2626);
  static const Color overlayBlueFill = Color(0xFF4F8EF7);
  static const Color overlayFaceRect = Color(0xFF06B6D4);

  // ── Sync ─────────────────────────────────────────────────
  static const Color syncOffline   = Color(0xFF64748B);
  static const Color syncUploading = Color(0xFFF59E0B);
  static const Color syncOk        = Color(0xFF10B981);
  static const Color syncPending   = Color(0xFFF59E0B);
  static const Color badgeRed      = Color(0xFFEF4444);

  // ── Error bg ──────────────────────────────────────────────
  static const Color errorBg = Color(0x1AEF4444);

  // ── Alerts ───────────────────────────────────────────────
  static const Color alertAbsent     = Color(0xFFEF4444);
  static const Color alertDistracted = Color(0xFFF97316);
  static const Color orangeWarning   = Color(0xFFF97316);

  AppColors._();
}
