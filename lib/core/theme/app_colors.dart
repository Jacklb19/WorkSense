import 'package:flutter/material.dart';

/// Paleta de colores centralizada de WorkSense.
/// NUNCA usar colores hardcodeados en widgets — siempre referenciar esta clase.
abstract final class AppColors {
  // ── Brand ────────────────────────────────────────────────
  static const Color primary = Color(0xFF1A73E8);
  static const Color primaryDark = Color(0xFF1557B0);
  static const Color primaryLight = Color(0xFF4A9EF4);

  static const Color secondary = Color(0xFF00BFA5);
  static const Color secondaryDark = Color(0xFF008C78);
  static const Color secondaryLight = Color(0xFF4DD9C9);

  // ── Estados de Actividad (AI Pipeline) ───────────────────
  static const Color stateWorking = Color(0xFF34A853);    // Verde
  static const Color stateInactive = Color(0xFF9E9E9E);   // Gris
  static const Color stateAbsent = Color(0xFFEA4335);     // Rojo
  static const Color stateDistracted = Color(0xFFFBBC04); // Amarillo
  static const Color stateFatigue = Color(0xFFFF6D00);    // Naranja
  static const Color stateOutsideArea = Color(0xFF2196F3);  // Azul
  static const Color stateNotIdentified = Color(0xFF607D8B); // Gris azulado

  // ── Sincronizacion ────────────────────────────────────────
  static const Color syncOk = Color(0xFF34A853);
  static const Color syncPending = Color(0xFFFBBC04);
  static const Color syncOffline = Color(0xFFEA4335);
  static const Color syncError = Color(0xFFD32F2F);

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
  static const Color backgroundLight = Color(0xFFF8F9FA);
  static const Color surfaceLight = Color(0xFFFFFFFF);
  static const Color cardLight = Color(0xFFFFFFFF);

  // ── Fondo y superficies (Dark) ────────────────────────────
  static const Color backgroundDark = Color(0xFF121212);
  static const Color surfaceDark = Color(0xFF1E1E1E);
  static const Color cardDark = Color(0xFF2C2C2C);

  // ── Texto ─────────────────────────────────────────────────
  static const Color textPrimaryLight = Color(0xFF212121);
  static const Color textSecondaryLight = Color(0xFF757575);
  static const Color textDisabledLight = Color(0xFFBDBDBD);

  static const Color textPrimaryDark = Color(0xFFE0E0E0);
  static const Color textSecondaryDark = Color(0xFF9E9E9E);
  static const Color textDisabledDark = Color(0xFF616161);

  // ── Feedback ─────────────────────────────────────────────
  static const Color success = Color(0xFF34A853);
  static const Color warning = Color(0xFFFBBC04);
  static const Color error = Color(0xFFEA4335);
  static const Color info = Color(0xFF1A73E8);

  static const Color successBg = Color(0xFFE6F4EA);
  static const Color warningBg = Color(0xFFFEF7E0);
  static const Color errorBg = Color(0xFFFCE8E6);
  static const Color infoBg = Color(0xFFE8F0FE);

  // ── Overlay de IA (Kiosk Mode) ────────────────────────────
  static const Color overlayFaceRect = Color(0xFF00E5FF);
  static const Color overlayPoseSkeleton = Color(0xFF76FF03);
  static const Color overlayBadgeBg = Color(0xCC000000);

  // ── Divider ───────────────────────────────────────────────
  static const Color dividerLight = Color(0xFFE0E0E0);
  static const Color dividerDark = Color(0xFF424242);

  // ── Overlay Kiosk ──────────────────────────────────────────
  static const Color overlayBlack70 = Color(0xB3000000);
  static const Color overlayBlack85 = Color(0xD9000000);

  // ── Scan Feedback ──────────────────────────────────────────
  static const Color feedbackDetected = Color(0xFF69F0AE);   // greenAccent
  static const Color feedbackError = Color(0xFFFF5252);       // redAccent
  static const Color feedbackCapturing = Color(0xFF40C4FF);   // lightBlueAccent
  static const Color feedbackSearching = Color(0xFFFFFF00);   // yellow

  // ── Identity Confidence ────────────────────────────────────
  static const Color identityHigh = Color(0xFF69F0AE);   // greenAccent
  static const Color identityMedium = Color(0xFFFFFF00);  // yellowAccent
  static const Color identityLow = Color(0xFFFF5252);     // redAccent

  // ── Alert Colors ───────────────────────────────────────────
  static const Color alertAbsent = Color(0xFFEA4335);
  static const Color alertDistracted = Color(0xFFFFC107);

  // ── Sync Specific ──────────────────────────────────────────
  static const Color syncUploading = Color(0xFFFF6D00);

  // ── Badge ──────────────────────────────────────────────────
  static const Color badgeRed = Color(0xFFF44336);

  // ── Overlay Painter ────────────────────────────────────────
  static const Color overlayCyanDot = Color(0xFF00E5FF);
  static const Color overlayCyanLine = Color(0xFF0099CC);
  static const Color overlayRedDot = Color(0xFFFF3333);
  static const Color overlayRedLine = Color(0xFFCC1111);
  static const Color overlayBlueFill = Color(0xFF2196F3);

  // ── Misc ───────────────────────────────────────────────────
  static const Color amber = Color(0xFFFFC107);
  static const Color orangeWarning = Color(0xFFFF9800);

  AppColors._();
}