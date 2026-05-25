import 'package:flutter/widgets.dart';

import '../../core/constants/app_dimensions.dart';

abstract final class AppSpacing {
  AppSpacing._();

  static double _screenWidth(BuildContext context) =>
      MediaQuery.sizeOf(context).width;

  static bool isMobile(BuildContext context) =>
      _screenWidth(context) < AppDimensions.tabletBreakpoint;

  static bool isTablet(BuildContext context) =>
      _screenWidth(context) >= AppDimensions.tabletBreakpoint &&
      _screenWidth(context) < AppDimensions.desktopBreakpoint;

  static bool isDesktop(BuildContext context) =>
      _screenWidth(context) >= AppDimensions.desktopBreakpoint;

  static EdgeInsets screenPadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingDesktop,
      );
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(
        horizontal: AppDimensions.screenPaddingTablet,
      );
    }
    return const EdgeInsets.symmetric(
      horizontal: AppDimensions.screenPaddingMobile,
    );
  }

  static EdgeInsets cardPadding(BuildContext context) =>
      const EdgeInsets.all(AppDimensions.cardInnerPadding);

  static EdgeInsets formPadding(BuildContext context) =>
      const EdgeInsets.symmetric(
        horizontal: AppDimensions.formHorizontalPadding,
        vertical: AppDimensions.formVerticalPadding,
      );

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return AppDimensions.contentMaxWidthDesktop;
    if (isTablet(context)) return AppDimensions.contentMaxWidthTablet;
    return AppDimensions.contentMaxWidthMobile;
  }
}
