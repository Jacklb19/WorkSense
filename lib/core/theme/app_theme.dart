import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../constants/app_dimensions.dart';
import 'app_colors.dart';

abstract final class AppTheme {
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    textTheme: _textTheme,
    primaryTextTheme: _textTheme,
    appBarTheme: _appBarTheme,
    cardTheme: _cardTheme,
    elevatedButtonTheme: _elevatedButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    filledButtonTheme: _filledButtonTheme,
    inputDecorationTheme: _inputDecorationTheme,
    dividerTheme: _dividerTheme,
    chipTheme: _chipTheme,
    navigationBarTheme: _navigationBarTheme,
    dialogTheme: _dialogTheme,
    snackBarTheme: _snackBarTheme,
    floatingActionButtonTheme: _fabTheme,
    progressIndicatorTheme: _progressIndicatorTheme,
    sliderTheme: _sliderTheme,
    listTileTheme: _listTileTheme,
    popupMenuTheme: _popupMenuTheme,
    iconButtonTheme: _iconButtonTheme,
    iconTheme: _iconTheme,
    bottomSheetTheme: _bottomSheetTheme,
    tooltipTheme: _tooltipTheme,
    switchTheme: _switchTheme,
    dropdownMenuTheme: _dropdownMenuTheme,
  );

  static const ColorScheme _colorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.white,
    secondary: AppColors.accentCyan,
    onSecondary: AppColors.textOnAccent,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.white,
    tertiary: AppColors.accent,
    onTertiary: AppColors.textOnAccent,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.card,
    surfaceContainerHigh: AppColors.elevated,
    surfaceContainerHighest: AppColors.neutral700,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorSoft,
    onErrorContainer: AppColors.error,
    outline: AppColors.divider,
    outlineVariant: AppColors.dividerSubtle,
  );

  static TextTheme get _textTheme => GoogleFonts.interTextTheme().copyWith(
    displayLarge: GoogleFonts.spaceGrotesk(
      fontSize: 48,
      fontWeight: FontWeight.w800,
      letterSpacing: -1.0,
      color: AppColors.textPrimary,
    ),
    displayMedium: GoogleFonts.spaceGrotesk(
      fontSize: 40,
      fontWeight: FontWeight.w800,
      letterSpacing: -0.5,
      color: AppColors.textPrimary,
    ),
    displaySmall: GoogleFonts.spaceGrotesk(
      fontSize: 32,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineLarge: GoogleFonts.inter(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineMedium: GoogleFonts.inter(
      fontSize: 24,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    headlineSmall: GoogleFonts.inter(
      fontSize: 20,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleLarge: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleMedium: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    titleSmall: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
    ),
    bodyLarge: GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodyMedium: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
    ),
    bodySmall: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
    labelLarge: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.textPrimary,
    ),
    labelMedium: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.textPrimary,
    ),
    labelSmall: GoogleFonts.inter(
      fontSize: 10,
      fontWeight: FontWeight.w600,
      letterSpacing: 0.5,
      color: AppColors.textSecondary,
    ),
  );

  static AppBarTheme get _appBarTheme => AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    backgroundColor: Colors.transparent,
    surfaceTintColor: Colors.transparent,
    foregroundColor: AppColors.textPrimary,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
  );

  static CardThemeData get _cardTheme => CardThemeData(
    elevation: AppDimensions.cardElevation,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusCard),
      side: BorderSide(
        color: AppColors.glassBorder,
        width: AppDimensions.glassBorderWidth,
      ),
    ),
    color: AppColors.card,
    margin: const EdgeInsets.symmetric(vertical: 8),
  );

  static const double _buttonRadius = 16.0;

  static FilledButtonThemeData get _filledButtonTheme => FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(_buttonRadius)),
      textStyle: GoogleFonts.inter(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        letterSpacing: 1.0,
      ),
      elevation: 0,
    ),
  );

  static ElevatedButtonThemeData get _elevatedButtonTheme =>
      ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.white,
          minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
          elevation: 0,
        ),
      );

  static OutlinedButtonThemeData get _outlinedButtonTheme =>
      OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.textPrimary,
          minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(_buttonRadius),
          ),
          side: BorderSide(color: AppColors.glassBorder),
          textStyle: GoogleFonts.inter(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
      );

  static TextButtonThemeData get _textButtonTheme => TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: GoogleFonts.inter(
        fontWeight: FontWeight.w600,
      ),
    ),
  );

  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_buttonRadius),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_buttonRadius),
      borderSide: BorderSide(color: AppColors.divider),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_buttonRadius),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_buttonRadius),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    focusedErrorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(_buttonRadius),
      borderSide: const BorderSide(color: AppColors.error, width: 2),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    hintStyle: GoogleFonts.inter(
      color: AppColors.textDisabled,
      fontSize: 14,
    ),
    prefixIconColor: AppColors.textSecondary,
    suffixIconColor: AppColors.textSecondary,
    labelStyle: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    ),
    floatingLabelStyle: GoogleFonts.inter(
      color: AppColors.primary,
      fontSize: 14,
      fontWeight: FontWeight.w600,
    ),
  );

  static DividerThemeData get _dividerTheme => DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 1,
  );

  static ChipThemeData get _chipTheme => ChipThemeData(
    backgroundColor: AppColors.surface,
    selectedColor: AppColors.primary.withAlpha(40),
    labelStyle: GoogleFonts.inter(
      color: AppColors.textSecondary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    secondaryLabelStyle: GoogleFonts.inter(
      color: AppColors.primary,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
    ),
    side: BorderSide.none,
  );

  static NavigationBarThemeData get _navigationBarTheme =>
      NavigationBarThemeData(
        backgroundColor: AppColors.surface,
        indicatorColor: AppColors.primary.withAlpha(40),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            );
          }
          return GoogleFonts.inter(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: AppColors.textSecondary,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 26);
          }
          return const IconThemeData(
            color: AppColors.textSecondary,
            size: 24,
          );
        }),
        elevation: 0,
        height: 72,
      );

  static DialogThemeData get _dialogTheme => DialogThemeData(
    backgroundColor: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusModal),
    ),
    elevation: 8,
    titleTextStyle: GoogleFonts.inter(
      fontSize: 18,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
    ),
    contentTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
  );

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusRound)),
    ),
    elevation: 4,
  );

  static const FloatingActionButtonThemeData _fabTheme =
      FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusRound)),
        ),
      );

  static ProgressIndicatorThemeData get _progressIndicatorTheme =>
      const ProgressIndicatorThemeData(
        color: AppColors.primary,
        linearTrackColor: AppColors.surface,
      );

  static SliderThemeData get _sliderTheme => SliderThemeData(
    activeTrackColor: AppColors.primary,
    inactiveTrackColor: AppColors.surface,
    thumbColor: AppColors.primary,
    overlayColor: AppColors.primary.withAlpha(40),
    valueIndicatorColor: AppColors.primary,
    valueIndicatorTextStyle: GoogleFonts.inter(
      color: AppColors.white,
      fontSize: 12,
      fontWeight: FontWeight.w600,
    ),
  );

  static ListTileThemeData get _listTileTheme => ListTileThemeData(
    contentPadding: const EdgeInsets.symmetric(
      horizontal: AppDimensions.formHorizontalPadding,
      vertical: 4,
    ),
    titleTextStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
    subtitleTextStyle: GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: AppColors.textSecondary,
    ),
  );

  static PopupMenuThemeData get _popupMenuTheme => PopupMenuThemeData(
    color: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusXxl),
    ),
    textStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
  );

  static IconButtonThemeData get _iconButtonTheme => IconButtonThemeData(
    style: IconButton.styleFrom(
      foregroundColor: AppColors.textSecondary,
    ),
  );

  static const IconThemeData _iconTheme = IconThemeData(
    color: AppColors.textPrimary,
    size: 24,
  );

  static BottomSheetThemeData get _bottomSheetTheme => BottomSheetThemeData(
    backgroundColor: AppColors.card,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(AppDimensions.radiusModal),
      ),
    ),
  );

  static TooltipThemeData get _tooltipTheme => TooltipThemeData(
    decoration: BoxDecoration(
      color: AppColors.elevated,
      borderRadius: BorderRadius.circular(AppDimensions.radiusMd),
    ),
    textStyle: GoogleFonts.inter(
      color: AppColors.textPrimary,
      fontSize: 12,
    ),
  );

  static SwitchThemeData get _switchTheme => SwitchThemeData(
    thumbColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) return AppColors.primary;
      return AppColors.textDisabled;
    }),
    trackColor: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return AppColors.primary.withAlpha(80);
      }
      return AppColors.divider;
    }),
  );

  static DropdownMenuThemeData get _dropdownMenuTheme => DropdownMenuThemeData(
    inputDecorationTheme: _inputDecorationTheme,
    textStyle: GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
    ),
  );

  static final ThemeData light = dark;

  AppTheme._();
}
