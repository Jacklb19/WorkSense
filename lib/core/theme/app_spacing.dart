import 'package:flutter/material.dart';
import '../constants/app_dimensions.dart';

abstract final class AppSpacing {
  AppSpacing._();

  // ── Responsive screen padding ──────────────────────────────
  static EdgeInsets screenPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > AppDimensions.breakpointDesktop) return const EdgeInsets.symmetric(horizontal: 80);
    if (width > AppDimensions.breakpointMobile) return const EdgeInsets.symmetric(horizontal: 48);
    return const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl);
  }

  static EdgeInsets cardPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > AppDimensions.breakpointDesktop) return const EdgeInsets.all(AppDimensions.spacing24);
    if (width > AppDimensions.breakpointMobile) return const EdgeInsets.all(AppDimensions.spacing20);
    return const EdgeInsets.all(AppDimensions.spacingXxl);
  }

  static EdgeInsets formPadding(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > AppDimensions.breakpointDesktop) return const EdgeInsets.symmetric(horizontal: 80, vertical: AppDimensions.spacing32);
    if (width > AppDimensions.breakpointMobile) return const EdgeInsets.symmetric(horizontal: 48, vertical: AppDimensions.spacing24);
    return const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingXxl);
  }

  // ── Responsive max widths ──────────────────────────────────
  static double contentMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > AppDimensions.breakpointDesktop) return AppDimensions.dashboardMaxWidth;
    if (width > AppDimensions.breakpointMobile) return AppDimensions.listMaxWidth;
    return width;
  }

  static double formMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > AppDimensions.breakpointMobile) return AppDimensions.formMaxWidth;
    return width;
  }

  static double listMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > AppDimensions.breakpointDesktop) return AppDimensions.dashboardMaxWidth;
    if (width > AppDimensions.breakpointMobile) return AppDimensions.listMaxWidth;
    return width;
  }

  static double dashboardMaxWidth(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    if (width > AppDimensions.breakpointDesktop) return AppDimensions.dashboardMaxWidth + 200;
    if (width > AppDimensions.breakpointMobile) return AppDimensions.dashboardMaxWidth;
    return width;
  }

  // ── Responsive grid cross-axis count ────────────────────────
  static int gridCrossAxisCount(BuildContext context, {int mobile = 1, int tablet = 2, int desktop = 3}) {
    final width = MediaQuery.of(context).size.width;
    if (width >= AppDimensions.breakpointDesktop) return desktop;
    if (width >= AppDimensions.breakpointMobile) return tablet;
    return mobile;
  }

  // ── Breakpoint helpers ──────────────────────────────────────
  static bool isMobile(BuildContext context) =>
      MediaQuery.of(context).size.width < AppDimensions.breakpointMobile;
  static bool isTablet(BuildContext context) {
    final width = MediaQuery.of(context).size.width;
    return width >= AppDimensions.breakpointMobile && width < AppDimensions.breakpointDesktop;
  }
  static bool isDesktop(BuildContext context) =>
      MediaQuery.of(context).size.width >= AppDimensions.breakpointDesktop;

  // ── Static spacing constants ───────────────────────────────
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