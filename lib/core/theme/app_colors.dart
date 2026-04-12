import 'package:flutter/material.dart';

/// Paleta de colores centralizada de WorkSense — Dark Design System.
/// NUNCA usar colores hardcodeados en widgets — siempre referenciar esta clase.
abstract final class AppColors {
  AppColors._();

  // ── Backgrounds ───────────────────────────────────────────────
  static const Color bgBase = Color(0xFF0D1117);
  static const Color surface = Color(0xFF161B22);
  static const Color elevated = Color(0xFF21262D);
  static const Color borderPlus = Color(0xFF2D333B);
  static const Color borderColor = Color(0xFF30363D);
  static const Color focusColor = Color(0xFF388BFD);

  // ── Brand ─────────────────────────────────────────────────────
  static const Color primary = Color(0xFF3B82F6);
  static const Color primaryDark = Color(0xFF1E40AF);
  static const Color primaryLight = Color(0xFF93C5FD);

  // ── Violet (scanner / biometric) ──────────────────────────────
  static const Color violet = Color(0xFF8B5CF6);
  static const Color violetLight = Color(0xFFC4B5FD);

  // ── Activity States ───────────────────────────────────────────
  static const Color stateWorking = Color(0xFF10B981);
  static const Color stateInactive = Color(0xFFF59E0B);
  static const Color stateDistracted = Color(0xFFEF4444);
  static const Color stateFatigue = Color(0xFFF97316);
  static const Color stateAbsent = Color(0xFF6B7280);
  static const Color stateOutsideArea = Color(0xFF3B82F6);
  static const Color stateNotIdentified = Color(0xFF8B5CF6);

  // ── Texto ─────────────────────────────────────────────────────
  static const Color textPrimary = Color(0xFFE6EDF3);
  static const Color textSecondary = Color(0xFF8B949E);
  static const Color textMuted = Color(0xFF6E7681);

  // ── Feedback ──────────────────────────────────────────────────
  static const Color success = Color(0xFF10B981);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  static const Color errorBg = Color(0xFF451A1A);
  static const Color successBg = Color(0xFF052E16);
  static const Color warningBg = Color(0xFF451A03);
  static const Color infoBg = Color(0xFF0F2040);

  // ── Overlay de IA (Kiosk Mode) ────────────────────────────────
  static const Color overlayFaceRect = Color(0xFF00E5FF);
  static const Color overlayPoseSkeleton = Color(0xFF76FF03);
  static const Color overlayBadgeBg = Color(0xCC000000);

  // ── Overlay Painter ───────────────────────────────────────────
  static const Color overlayCyanDot = Color(0xFF00E5FF);
  static const Color overlayCyanLine = Color(0xFF0099CC);
  static const Color overlayRedDot = Color(0xFFFF3333);
  static const Color overlayRedLine = Color(0xFFCC1111);
  static const Color overlayBlueFill = Color(0xFF3B82F6);

  // ── Scan Feedback ─────────────────────────────────────────────
  static const Color feedbackDetected = Color(0xFF69F0AE);
  static const Color feedbackError = Color(0xFFFF5252);
  static const Color feedbackCapturing = Color(0xFF40C4FF);
  static const Color feedbackSearching = Color(0xFFFFFF00);

  // ── Identity Confidence ───────────────────────────────────────
  static const Color identityHigh = Color(0xFF69F0AE);
  static const Color identityMedium = Color(0xFFFFFF00);
  static const Color identityLow = Color(0xFFFF5252);

  // ── Sync ──────────────────────────────────────────────────────
  static const Color syncOk = Color(0xFF10B981);
  static const Color syncPending = Color(0xFFF59E0B);
  static const Color syncOffline = Color(0xFFEF4444);
  static const Color syncError = Color(0xFFEF4444);

  // ── Accent Cards (special bg) ─────────────────────────────────
  static const Color accentCardBg = Color(0xFF0F2040);
  static const Color violetCardBg = Color(0xFF1E1040);
  static const Color dangerCardBg = Color(0xFF7F1D1D);
  static const Color dangerCardFg = Color(0xFFFCA5A5);

  // ── Legacy aliases (backward compatibility) ───────────────────
  static const Color white = Color(0xFFFFFFFF);
  static const Color black = Color(0xFF000000);
  static const Color grey300 = Color(0xFF30363D);
  static const Color grey400 = Color(0xFF6E7681);
  static const Color grey500 = Color(0xFF8B949E);
  static const Color grey600 = Color(0xFF8B949E);
  static const Color grey700 = Color(0xFF6E7681);
  static const Color grey800 = Color(0xFF21262D);
  static const Color backgroundDark = Color(0xFF0D1117);
  static const Color surfaceDark = Color(0xFF161B22);
  static const Color cardDark = Color(0xFF161B22);
  static const Color textPrimaryDark = Color(0xFFE6EDF3);
  static const Color textSecondaryDark = Color(0xFF8B949E);
  static const Color dividerDark = Color(0xFF30363D);
  static const Color amber = Color(0xFFF59E0B);
}