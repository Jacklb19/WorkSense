import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

abstract final class AppSpacing {
  AppSpacing._();

  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return const EdgeInsets.symmetric(horizontal: 80);
    if (width > 800) return const EdgeInsets.symmetric(horizontal: 48);
    return const EdgeInsets.symmetric(horizontal: 16);
  }

  static EdgeInsets cardPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return const EdgeInsets.all(24);
    if (width > 800) return const EdgeInsets.all(20);
    return const EdgeInsets.all(16);
  }

  static EdgeInsets formPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return const EdgeInsets.symmetric(horizontal: 80, vertical: 32);
    if (width > 800) return const EdgeInsets.symmetric(horizontal: 48, vertical: 24);
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }

  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > 1200) return 900;
    if (width > 800) return 600;
    return width;
  }

  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < 600;
  static bool isTablet(BuildContext context) =>
      MediaQuery.of(context).size.width >= 600 &&
      MediaQuery.of(context).size.width < 1200;
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= 1200;

  static const EdgeInsets paddingXs = EdgeInsets.all(AppDimensions.spacingXs);
  static const EdgeInsets paddingSm = EdgeInsets.all(AppDimensions.spacingSm);
  static const EdgeInsets paddingMd = EdgeInsets.all(AppDimensions.spacingMd);
  static const EdgeInsets paddingLg = EdgeInsets.all(AppDimensions.spacingLg);
  static const EdgeInsets paddingXl = EdgeInsets.all(AppDimensions.spacingXl);
  static const EdgeInsets paddingXxl = EdgeInsets.all(AppDimensions.spacingXxl);

  static const SizedBox gapXs = SizedBox(height: AppDimensions.spacingXs);
  static const SizedBox gapSm = SizedBox(height: AppDimensions.spacingSm);
  static const SizedBox gapMd = SizedBox(height: AppDimensions.spacingMd);
  static const SizedBox gapLg = SizedBox(height: AppDimensions.spacingLg);
  static const SizedBox gapXl = SizedBox(height: AppDimensions.spacingXl);
  static const SizedBox gapXxl = SizedBox(height: AppDimensions.spacingXxl);
}