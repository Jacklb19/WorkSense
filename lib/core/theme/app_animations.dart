import 'package:flutter/animation.dart';

abstract final class AppAnimations {
  AppAnimations._();

  static const Duration fast = Duration(milliseconds: 150);
  static const Duration normal = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 500);
  static const Duration entrance = Duration(milliseconds: 600);
  static const Duration shimmer = Duration(milliseconds: 1500);

  static const Curve defaultCurve = Curves.easeInOutCubic;
  static const Curve emphasis = Curves.easeOutCubic;
  static const Curve decelerate = Curves.easeOut;
  static const Curve overshoot = Curves.elasticOut;
  static const Curve entranceCurve = Curves.easeOutCubic;

  static const int staggerDelayMs = 50;
}