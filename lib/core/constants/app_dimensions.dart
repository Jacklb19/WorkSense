abstract final class AppDimensions {
  AppDimensions._();

  // ── PADDING & SPACING ────────────────────────────────────────
  static const double spacingXxs = 2.0;
  static const double spacingXs = 4.0;
  static const double spacingSm = 6.0;
  static const double spacingMd = 8.0;
  static const double spacingLg = 12.0;
  static const double spacingXl = 14.0;
  static const double spacingXxl = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing56 = 56.0;
  static const double spacing64 = 64.0;
  static const double spacing80 = 80.0;
  static const double spacing100 = 100.0;
  static const double spacing120 = 120.0;

  // ── RESPONSIVE BREAKPOINTS ───────────────────────────────────
  static const double mobileBreakpoint = 480.0;
  static const double tabletBreakpoint = 768.0;
  static const double desktopBreakpoint = 1024.0;

  // ── SCREEN PADDING ───────────────────────────────────────────
  static const double screenPaddingMobile = 20.0;
  static const double screenPaddingTablet = 40.0;
  static const double screenPaddingDesktop = 64.0;

  // ── CONTENT MAX WIDTH ────────────────────────────────────────
  static const double contentMaxWidthMobile = double.infinity;
  static const double contentMaxWidthTablet = 720.0;
  static const double contentMaxWidthDesktop = 960.0;

  // ── BORDER RADIUS ────────────────────────────────────────────
  static const double radiusXxs = 2.0;
  static const double radiusXs = 3.0;
  static const double radiusSm = 4.0;
  static const double radiusMd = 6.0;
  static const double radiusLg = 8.0;
  static const double radiusXl = 10.0;
  static const double radiusXxl = 12.0;
  static const double radiusRound = 16.0;
  static const double radiusPill = 20.0;
  static const double radiusCard = 20.0;
  static const double radiusModal = 24.0;

  // ── FONT SIZES ───────────────────────────────────────────────
  static const double fontXxs = 8.0;
  static const double fontXs = 10.0;
  static const double fontSm = 11.0;
  static const double fontCaption = 12.0;
  static const double fontBody = 13.0;
  static const double fontBodyMd = 14.0;
  static const double fontSubtitle = 15.0;
  static const double fontTitle = 16.0;
  static const double fontTitleLg = 18.0;
  static const double fontHeadline = 20.0;
  static const double fontHeadlineLg = 22.0;
  static const double fontDisplay = 32.0;
  static const double fontDisplayLg = 48.0;

  // ── ICON SIZES ───────────────────────────────────────────────
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

  // ── AVATAR SIZES ─────────────────────────────────────────────
  static const double avatarXs = 24.0;
  static const double avatarSm = 36.0;
  static const double avatarMd = 44.0;
  static const double avatarLg = 56.0;
  static const double avatarXl = 72.0;

  // ── CARD ─────────────────────────────────────────────────────
  static const double cardElevation = 0.0;
  static const double cardInnerPadding = 20.0;
  static const double cardMaxWidth = 400.0;

  // ── BUTTONS ──────────────────────────────────────────────────
  static const double buttonMinHeight = 52.0;
  static const double buttonMinHeightLg = 60.0;
  static const double buttonPaddingVertical = 16.0;

  // ── FORM ─────────────────────────────────────────────────────
  static const double formFieldHeight = 60.0;
  static const double formHorizontalPadding = 24.0;
  static const double formVerticalPadding = 32.0;

  // ── GLASSMORPHISM ────────────────────────────────────────────
  static const double glassBlur = 10.0;
  static const double glassBorderWidth = 1.0;

  // ── NAVIGATION ───────────────────────────────────────────────
  static const double sliverAppBarHeight = 64.0;
  static const double bottomNavHeight = 72.0;
  static const double fabExtendedHeight = 48.0;

  // ── ANIMATION ────────────────────────────────────────────────
  static const Duration animFast = Duration(milliseconds: 150);
  static const Duration animNormal = Duration(milliseconds: 300);
  static const Duration animSlow = Duration(milliseconds: 500);
  static const Duration animEntrance = Duration(milliseconds: 600);
  static const Duration animShimmer = Duration(milliseconds: 1000);

  // ── LOGIN ────────────────────────────────────────────────────
  static const double loginMaxWidth = 400.0;
  static const double loginLogoSize = 80.0;
  static const double loginLogoRadius = 24.0;

  // ── PROGRESS INDICATORS ──────────────────────────────────────
  static const double progressStrokeWidth = 2.0;
  static const double progressBarHeight = 8.0;
  static const double progressBarHeightSm = 6.0;
  static const double progressIndicatorSize = 20.0;

  // ── KIOSK ────────────────────────────────────────────────────
  static const double kioskGuideFrameWidthFraction = 0.65;
  static const double kioskGuideFrameHeightFraction = 0.55;
  static const double kioskGuideCornerLength = 30.0;
  static const double kioskGuideStrokeWidth = 2.5;

  // ── OVERLAY ──────────────────────────────────────────────────
  static const double overlayDotHaloRadius = 9.0;
  static const double overlayDotRadius = 5.0;
  static const double overlayFaceDotHaloRadius = 6.5;
  static const double overlayFaceDotRadius = 3.5;
  static const double overlayConfidenceBarHeight = 4.0;
  static const double overlayConfidenceBarMargin = 16.0;

  // ── BADGE ────────────────────────────────────────────────────
  static const double badgeMinSize = 14.0;
  static const double badgeRadius = 10.0;
  static const double badgePadding = 2.0;

  // ── STATE INDICATOR ──────────────────────────────────────────
  static const double stateIndicatorSize = 8.0;

  // ── GRID ─────────────────────────────────────────────────────
  static const double gridMaxCrossAxisExtent = 350.0;
  static const double gridMainAxisExtent = 180.0;
  static const double gridMainAxisSpacing = 16.0;
  static const double gridCrossAxisSpacing = 16.0;

  // ── DIVIDER INDENT ───────────────────────────────────────────
  static const double dividerIndent = 72.0;

  // ── STAT BAR ─────────────────────────────────────────────────
  static const double statBarLabelWidth = 80.0;
  static const double statBarValueWidth = 45.0;

  // ── DISTRIBUTION BAR ─────────────────────────────────────────
  static const double distributionBarHeight = 10.0;
  static const double stateBreakdownDotSize = 12.0;
  static const double stateBreakdownPercentageWidth = 80.0;

  // ── STAT CHIP ────────────────────────────────────────────────
  static const double statChipIconSize = 22.0;
}
