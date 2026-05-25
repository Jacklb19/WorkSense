/// Dimensiones centralizadas de WorkSense.
/// Padding, spacing, border radius, font sizes, icon sizes.
abstract final class AppDimensions {
  AppDimensions._();

  // ─────────────────────────────────────────────────────────
  // PADDING & SPACING
  // ─────────────────────────────────────────────────────────
  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 6.0;
  static const double spacingMd = 8.0;
  static const double spacingLg = 12.0;
  static const double spacingXl = 14.0;
  static const double spacingXxl = 16.0;
  static const double spacing10 = 10.0;
  static const double spacing18 = 18.0;
  static const double spacing20 = 20.0;
  static const double spacing22 = 22.0;
  static const double spacing24 = 24.0;
  static const double spacing28 = 28.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing44 = 44.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  static const double spacing80 = 80.0;
  static const double spacing92 = 92.0;
  static const double spacing100 = 100.0;

  // ─────────────────────────────────────────────────────────
  // BORDER RADIUS
  // ─────────────────────────────────────────────────────────
  static const double radiusXxs = 2.0;
  static const double radiusXs = 3.0;
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 10.0;
  static const double radiusXxl = 12.0;
  static const double radiusRound = 16.0;
  static const double radiusPill = 20.0;
  static const double radiusCard = 14.0;
  static const double radiusCardLg = 18.0;
  static const double radiusCardXl = 22.0;
  static const double radiusCardXxl = 28.0;
  static const double radiusContainer = 30.0;
  static const double radiusInfinity = 999.0;

  // ─────────────────────────────────────────────────────────
  // FONT SIZES
  // ─────────────────────────────────────────────────────────
  static const double fontXxs = 8.0;
  static const double fontXs = 10.0;
  static const double fontSm = 11.0;
  static const double fontCaption = 12.0;
  static const double fontBody = 13.0;
  static const double fontBodyMd = 14.0;
  static const double fontSubtitle = 15.0;
  static const double fontTitle = 16.0;
  static const double fontBodyLg = 17.0;
  static const double fontTitleLg = 18.0;
  static const double fontHeadline = 20.0;
  static const double fontHeadlineLg = 22.0;
  static const double fontDisplayXs = 24.0;
  static const double fontDisplaySm = 28.0;
  static const double fontDisplay = 32.0;
  static const double fontDisplayLg = 48.0;

  // ─────────────────────────────────────────────────────────
  // ICON SIZES
  // ─────────────────────────────────────────────────────────
  static const double iconXxs = 12.0;
  static const double iconXs = 16.0;
  static const double iconSm = 18.0;
  static const double iconMd = 20.0;
  static const double iconDefault = 22.0;
  static const double iconLg = 24.0;
  static const double iconXl = 32.0;
  static const double iconXxl = 36.0;
  static const double iconHuge = 40.0;
  static const double iconEmptyState = 48.0;
  static const double iconEmptyStateLg = 64.0;
  static const double iconHero = 72.0;
  static const double iconLogo = 80.0;

  // ─────────────────────────────────────────────────────────
  // SPECIFIC UI DIMENSIONS
  // ─────────────────────────────────────────────────────────

  // Login
  static const double loginMaxWidth = 400.0;
  static const double loginLogoPadding = 32.0;
  static const double loginLogoSize = 80.0;
  static const double loginLogoRadius = 20.0;

  // Buttons
  static const double buttonMinHeight = 52.0;
  static const double buttonPaddingVertical = 16.0;
  static const double buttonPaddingVerticalSm = 14.0;

  // Progress indicators
  static const double progressStrokeWidth = 2.0;
  static const double progressBarHeight = 8.0;
  static const double progressBarHeightSm = 6.0;
  static const double progressIndicatorSize = 20.0;

  // Cards
  static const double cardElevation = 2.0;

  // Kiosk
  static const double kioskGuideFrameWidthFraction = 0.65;
  static const double kioskGuideFrameHeightFraction = 0.55;
  static const double kioskGuideCornerLength = 30.0;
  static const double kioskGuideStrokeWidth = 2.5;

  // Overlay
  static const double overlayDotHaloRadius = 9.0;
  static const double overlayDotRadius = 5.0;
  static const double overlayFaceDotHaloRadius = 6.5;
  static const double overlayFaceDotRadius = 3.5;
  static const double overlayConfidenceBarHeight = 4.0;
  static const double overlayConfidenceBarMargin = 16.0;
  static const double overlayBadgePaddingH = 12.0;
  static const double overlayBadgePaddingV = 6.0;
  static const double overlayBadgeRadius = 6.0;
  static const double overlayBadgeAccentWidth = 4.0;
  static const double overlayIdentityBadgeHeight = 44.0;

  // Badge
  static const double badgeMinSize = 14.0;
  static const double badgeRadius = 10.0;
  static const double badgePadding = 2.0;

  // State indicator
  static const double stateIndicatorSize = 8.0;
  static const double stateDotBlurRadius = 4.0;
  static const double stateDotSpreadRadius = 1.0;

  // Grid
  static const double gridMaxCrossAxisExtent = 280.0;
  static const double gridMainAxisExtent = 160.0;
  static const double gridSpacing = 12.0;

  // Avatar
  static const double avatarRadiusSm = 20.0;
  static const double avatarRadiusMd = 24.0;

  // Divider indent
  static const double dividerIndent = 72.0;

  // Stat bar label width
  static const double statBarLabelWidth = 80.0;
  static const double statBarValueWidth = 45.0;

  // Distribution bar
  static const double distributionBarHeight = 10.0;

  // Stat chip icon size
  static const double statChipIconSize = 22.0;

  // State breakdown
  static const double stateBreakdownDotSize = 12.0;
  static const double stateBreakdownPercentageWidth = 80.0;

  // Capture button (scan/kiosk)
  static const double captureButtonSize = 80.0;
  static const double captureButtonInnerSize = 60.0;
  static const double captureButtonBorderWidth = 4.0;
  static const double captureButtonIconSize = 32.0;
  static const double cornerIndicatorSize = 30.0;
  static const double cornerIndicatorWidth = 4.0;
  static const double guideFrameRadius = 32.0;

  // Button heights
  static const double buttonHeightLg = 60.0;
  static const double buttonHeightMd = 50.0;

  // ─────────────────────────────────────────────────────────
  // RESPONSIVE BREAKPOINTS & MAX WIDTHS
  // ─────────────────────────────────────────────────────────
  static const double breakpointMobile = 600.0;
  static const double breakpointTablet = 900.0;
  static const double breakpointDesktop = 1200.0;

  static const double formMaxWidth = 600.0;
  static const double listMaxWidth = 700.0;
  static const double dashboardMaxWidth = 900.0;

  // Icon container sizes (replaces hardcoded values)
  static const double iconContainerSm = 44.0;
  static const double iconContainerLg = 92.0;

  // Slider bounds (workstation geofence)
  static const double geofenceRadiusMin = 50.0;
  static const double geofenceRadiusMax = 500.0;
  static const int geofenceRadiusDivisions = 9;

  // Legend color dot size
  static const double legendDotSize = 16.0;

  // Bottom padding for scroll content (FAB clearance)
  static const double scrollBottomPadding = 80.0;
}
