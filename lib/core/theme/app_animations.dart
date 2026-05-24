import 'package:flutter/animation.dart';

abstract final class AppAnimations {
  AppAnimations._();

  // ── Durations ────────────────────────────────────────────────
  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration entrance = Duration(milliseconds: 600);
  static const Duration shimmer = Duration(milliseconds: 1000);

  // ── Curves ───────────────────────────────────────────────────
  static const Curve entranceCurve = Curves.easeOutCubic;
  static const Curve exitCurve = Curves.easeInCubic;
  static const Curve emphasizeCurve = Curves.elasticOut;
  static const Curve bouncyEntrance = Curves.easeOutBack;

  // ── Easing presets ───────────────────────────────────────────
  static const Curve easeOut = Curves.fastOutSlowIn;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve decelerate = Curves.decelerate;
}
