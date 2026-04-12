import 'package:flutter/material.dart';

/// Border radius tokens for consistent rounding throughout WorkSense.
abstract final class AppRadius {
  AppRadius._();

  static const Radius sm  = Radius.circular(4);
  static const Radius md  = Radius.circular(8);
  static const Radius lg  = Radius.circular(12);
  static const Radius xl  = Radius.circular(16);
  static const Radius xxl = Radius.circular(24);
  static const Radius pill = Radius.circular(100);

  // BorderRadius shortcuts
  static final BorderRadius smAll  = BorderRadius.all(sm);
  static final BorderRadius mdAll  = BorderRadius.all(md);
  static final BorderRadius lgAll  = BorderRadius.all(lg);
  static final BorderRadius xlAll  = BorderRadius.all(xl);
  static final BorderRadius xxlAll = BorderRadius.all(xxl);
  static final BorderRadius pillAll = BorderRadius.all(pill);
}
