import 'package:flutter/material.dart';

abstract final class AppColors {
  AppColors._();

  // ── Brand ────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF2563EB);
  static const Color primaryLight = Color(0xFF60A5FA);

  static const Color secondary = Color(0xFF8B5CF6);
  static const Color secondaryDark = Color(0xFF7C3AED);
  static const Color secondaryLight = Color(0xFFA78BFA);

  // ── Background & Surfaces (Dark-first) ────────────────────
  static const Color background = Color(0xFF0A0E17);
  static const Color surface = Color(0xFF111827);
  static const Color card = Color(0xFF1E293B);
  static const Color surfaceContainer = Color(0xFF1A2332);
  static const Color surfaceContainerHigh = Color(0xFF253247);
  static const Color surfaceContainerHighest = Color(0xFF334155);

  // ── Legacy alias (backward-compat) ────────────────────────
  static const Color backgroundDark = background;
  static const Color surfaceDark = surface;
  static const Color cardDark = card;
  static const Color backgroundLight = Color(0xFFF8F9FD);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Text ──────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFF1F5F9);
  static const Color textSecondary = Color(0xFF94A3B8);
  static const Color textDisabled = Color(0xFF64748B);
  static const Color textHint = Color(0xFF475569);

  // ── Legacy text alias (backward-compat) ────────────────────
  static const Color textPrimaryLight = Color(0xFF1A1C1E);
  static const Color textSecondaryLight = Color(0xFF42474E);
  static const Color textDisabledLight = Color(0xFF72777F);
  static const Color textPrimaryDark = textPrimary;
  static const Color textSecondaryDark = textSecondary;
  static const Color textDisabledDark = textDisabled;

  // ── Dividers ──────────────────────────────────────────────
  static const Color divider = Color(0xFF334155);
  static const Color dividerLight = Color(0xFFC4C7D0);
  static const Color dividerDark = divider;

  // ── Neutrals ──────────────────────────────────────────────
  static const Color transparent = Color(0x00000000);
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);

  // White opacity variants (for overlays on dark backgrounds)
  static const Color white5 = Color(0x0DFFFFFF);
  static const Color white10 = Color(0x1AFFFFFF);
  static const Color white12 = Color(0x1FFFFFFF);
  static const Color white24 = Color(0x3DFFFFFF);
  static const Color white30 = Color(0x4DFFFFFF);
  static const Color white38 = Color(0x61FFFFFF);
  static const Color white54 = Color(0x8AFFFFFF);
  static const Color white60 = Color(0x99FFFFFF);
  static const Color white70 = Color(0xB3FFFFFF);

  // Black opacity variants (for overlays on light backgrounds)
  static const Color black12 = Color(0x1F000000);
  static const Color black26 = Color(0x42000000);
  static const Color black38 = Color(0x61000000);
  static const Color black45 = Color(0x73000000);
  static const Color black54 = Color(0x8A000000);

  // Grey scale
  static const Color grey50 = Color(0xFFF8FAFC);
  static const Color grey100 = Color(0xFFF1F5F9);
  static const Color grey200 = Color(0xFFE2E8F0);
  static const Color grey300 = Color(0xFFCBD5E1);
  static const Color grey400 = Color(0xFF94A3B8);
  static const Color grey500 = Color(0xFF64748B);
  static const Color grey600 = Color(0xFF475569);
  static const Color grey700 = Color(0xFF334155);
  static const Color grey800 = Color(0xFF1E293B);
  static const Color grey900 = Color(0xFF0F172A);

  // ── Gradients ─────────────────────────────────────────────
  static const List<Color> mainGradient = [primary, secondary];
  static const List<Color> surfaceGradient = [card, surface];

  // ── Activity (AI Pipeline) ────────────────────────────────
  static const Color stateWorking = Color(0xFF22C55E);
  static const Color stateInactive = Color(0xFF94A3B8);
  static const Color stateAbsent = Color(0xFFEF4444);
  static const Color stateDistracted = Color(0xFFF59E0B);
  static const Color stateFatigue = Color(0xFFF97316);
  static const Color stateOutsideArea = Color(0xFF38BDF8);
  static const Color stateNotIdentified = Color(0xFF64748B);

  // ── Feedback ──────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);
  static const Color successDark = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static Color successSoft = success.withValues(alpha: 0.15);
  static Color warningSoft = warning.withValues(alpha: 0.15);
  static Color errorSoft = error.withValues(alpha: 0.15);
  static Color infoSoft = info.withValues(alpha: 0.15);

  // ── Glassmorphism & Overlays ──────────────────────────────
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassBlack = Color(0x66000000);
  static const Color overlayBadgeBg = Color(0xCC111827);
  static const Color glassBorder = Color(0x33FFFFFF);

  // ── Scan Feedback ─────────────────────────────────────────
  static const Color feedbackDetected = Color(0xFF22C55E);
  static const Color feedbackError = Color(0xFFEF4444);
  static const Color feedbackCapturing = Color(0xFF3B82F6);
  static const Color feedbackSearching = Color(0xFFF59E0B);

  // ── Identity Confidence ────────────────────────────────────
  static const Color identityHigh = Color(0xFF22C55E);
  static const Color identityMedium = Color(0xFFF59E0B);
  static const Color identityLow = Color(0xFFEF4444);

  // ── Overlay Painter ────────────────────────────────────────
  static const Color overlayCyanDot = Color(0xFF00E5FF);
  static const Color overlayCyanLine = Color(0xFF00B8D4);
  static const Color overlayRedDot = Color(0xFFFF5252);
  static const Color overlayRedLine = Color(0xFFEF4444);
  static const Color overlayBlueFill = Color(0xFF3B82F6);
  static const Color overlayFaceRect = Color(0xFF00E5FF);

  // ── Sync Status ────────────────────────────────────────────
  static const Color syncOffline = Color(0xFF64748B);
  static const Color syncUploading = Color(0xFFF59E0B);
  static const Color syncOk = Color(0xFF22C55E);
  static const Color syncPending = Color(0xFFF59E0B);
  static const Color badgeRed = Color(0xFFEF4444);

  // ── Error Background ──────────────────────────────────────
  static const Color errorBg = Color(0x1AEF4444);

  // ── Alert Colors ──────────────────────────────────────────
  static const Color alertAbsent = Color(0xFFEF4444);
  static const Color alertDistracted = Color(0xFFF97316);
  static const Color orangeWarning = Color(0xFFF97316);

  // ── Primary Opacity Variants ──────────────────────────────
  static Color primary5 = primary.withValues(alpha: 0.05);
  static Color primary10 = primary.withValues(alpha: 0.10);
  static Color primary15 = primary.withValues(alpha: 0.15);
  static Color primary20 = primary.withValues(alpha: 0.20);
  static Color primary25 = primary.withValues(alpha: 0.25);
}