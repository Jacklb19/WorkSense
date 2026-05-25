import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import '../constants/app_dimensions.dart';

abstract final class AppTheme {
  // ── Dark theme ──────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    textTheme: AppTextStyles.dark,
    appBarTheme: _darkAppBarTheme,
    cardTheme: _darkCardTheme,
    elevatedButtonTheme: _darkElevatedButtonTheme,
    outlinedButtonTheme: _darkOutlinedButtonTheme,
    textButtonTheme: _darkTextButtonTheme,
    filledButtonTheme: _darkFilledButtonTheme,
    inputDecorationTheme: _darkInputDecorationTheme,
    dividerTheme: _darkDividerTheme,
    chipTheme: _darkChipTheme,
    navigationBarTheme: _darkNavigationBarTheme,
    scaffoldBackgroundColor: AppColors.background,
    dialogTheme: _darkDialogTheme,
    snackBarTheme: _darkSnackBarTheme,
    floatingActionButtonTheme: _darkFabTheme,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryLight,
      linearTrackColor: AppColors.grey800,
    ),
  );

  // ── Light theme ─────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    textTheme: AppTextStyles.light,
    appBarTheme: _lightAppBarTheme,
    cardTheme: _lightCardTheme,
    elevatedButtonTheme: _lightElevatedButtonTheme,
    outlinedButtonTheme: _lightOutlinedButtonTheme,
    textButtonTheme: _lightTextButtonTheme,
    filledButtonTheme: _lightFilledButtonTheme,
    inputDecorationTheme: _lightInputDecorationTheme,
    dividerTheme: _lightDividerTheme,
    chipTheme: _lightChipTheme,
    navigationBarTheme: _lightNavigationBarTheme,
    scaffoldBackgroundColor: AppColors.lightBackground,
    dialogTheme: _lightDialogTheme,
    snackBarTheme: _lightSnackBarTheme,
    floatingActionButtonTheme: _lightFabTheme,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.grey200,
    ),
  );

  AppTheme._();

  // ═══════════════════════════════════════════════════════════
  // DARK COLOR SCHEME
  // ═══════════════════════════════════════════════════════════
  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.secondaryLight,
    surface: AppColors.surface,
    onSurface: AppColors.textPrimary,
    surfaceContainerLowest: AppColors.background,
    surfaceContainerLow: AppColors.surface,
    surfaceContainer: AppColors.card,
    surfaceContainerHigh: AppColors.surfaceContainerHigh,
    surfaceContainerHighest: AppColors.surfaceContainerHighest,
    error: AppColors.error,
    onError: AppColors.white,
    outline: AppColors.divider,
  );

  // ═══════════════════════════════════════════════════════════
  // LIGHT COLOR SCHEME
  // ═══════════════════════════════════════════════════════════
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primaryLight,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.secondaryLight,
    onSecondaryContainer: AppColors.secondaryDark,
    surface: AppColors.lightSurface,
    onSurface: AppColors.lightTextPrimary,
    surfaceContainerLowest: AppColors.lightBackground,
    surfaceContainerLow: AppColors.lightSurface,
    surfaceContainer: AppColors.lightSurfaceContainer,
    surfaceContainerHigh: AppColors.lightSurfaceContainerHigh,
    surfaceContainerHighest: AppColors.lightSurfaceContainerHighest,
    error: AppColors.error,
    onError: AppColors.white,
    outline: AppColors.dividerLight,
  );

  // ═══════════════════════════════════════════════════════════
  // DARK COMPONENT THEMES
  // ═══════════════════════════════════════════════════════════
  static const AppBarTheme _darkAppBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    backgroundColor: AppColors.transparent,
    foregroundColor: AppColors.textPrimary,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    titleTextStyle: TextStyle(
      fontSize: AppDimensions.fontHeadlineLg, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    ),
  );

  static const CardThemeData _darkCardTheme = CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusRound)),
      side: BorderSide(color: AppColors.glassBorder, width: 1),
    ),
    color: AppColors.card,
    margin: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
  );

  static final FilledButtonThemeData _darkFilledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusRound)),
      textStyle: const TextStyle(fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w700),
      elevation: 0,
    ),
  );

  static final ElevatedButtonThemeData _darkElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusRound)),
      textStyle: const TextStyle(fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w700),
      elevation: 2,
      shadowColor: AppColors.primary25,
    ),
  );

  static final OutlinedButtonThemeData _darkOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusRound)),
      side: BorderSide(color: AppColors.primary20, width: 1.5),
      textStyle: const TextStyle(fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w700),
    ),
  );

  static final TextButtonThemeData _darkTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      textStyle: const TextStyle(fontSize: AppDimensions.fontBodyMd, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
    ),
  );

  static InputDecorationTheme get _darkInputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.surface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      borderSide: const BorderSide(color: AppColors.divider, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24, vertical: AppDimensions.spacing20),
    hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: AppDimensions.fontBodyMd),
    prefixIconColor: AppColors.textSecondary,
    suffixIconColor: AppColors.textSecondary,
  );

  static const DividerThemeData _darkDividerTheme = DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 1,
  );

  static ChipThemeData get _darkChipTheme => ChipThemeData(
    backgroundColor: AppColors.surfaceContainerHigh,
    selectedColor: AppColors.primary15,
    labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: AppDimensions.fontCaption),
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
    side: BorderSide.none,
  );

  static NavigationBarThemeData get _darkNavigationBarTheme => NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.primary10,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final style = TextStyle(fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w600);
      if (states.contains(WidgetState.selected)) {
        return style.copyWith(color: AppColors.primary);
      }
      return style.copyWith(color: AppColors.textSecondary);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.primary, size: AppDimensions.iconLg);
      }
      return const IconThemeData(color: AppColors.textSecondary, size: AppDimensions.iconDefault);
    }),
    elevation: 0,
    height: AppDimensions.spacing64 + AppDimensions.spacingXxl,
  );

  static const DialogThemeData _darkDialogTheme = DialogThemeData(
    backgroundColor: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusPill)),
    ),
    elevation: 8,
    titleTextStyle: TextStyle(fontSize: AppDimensions.fontDisplayXs, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    contentTextStyle: TextStyle(fontSize: AppDimensions.fontBodyMd, color: AppColors.textSecondary),
  );

  static const SnackBarThemeData _darkSnackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusRound))),
    elevation: 4,
  );

  static const FloatingActionButtonThemeData _darkFabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusPill))),
  );

  // ═══════════════════════════════════════════════════════════
  // LIGHT COMPONENT THEMES
  // ═══════════════════════════════════════════════════════════
  static const AppBarTheme _lightAppBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    backgroundColor: AppColors.lightSurface,
    foregroundColor: AppColors.lightTextPrimary,
    systemOverlayStyle: SystemUiOverlayStyle.dark,
    titleTextStyle: TextStyle(
      fontSize: AppDimensions.fontHeadlineLg, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary,
    ),
  );

  static const CardThemeData _lightCardTheme = CardThemeData(
    elevation: 1,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusRound)),
      side: BorderSide(color: AppColors.lightGlassBorder, width: 1),
    ),
    color: AppColors.lightCard,
    margin: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
    surfaceTintColor: AppColors.transparent,
  );

  static final FilledButtonThemeData _lightFilledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusRound)),
      textStyle: const TextStyle(fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w700),
      elevation: 1,
    ),
  );

  static final ElevatedButtonThemeData _lightElevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusRound)),
      textStyle: const TextStyle(fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w700),
      elevation: 2,
      shadowColor: AppColors.black12,
    ),
  );

  static final OutlinedButtonThemeData _lightOutlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusRound)),
      side: const BorderSide(color: AppColors.primary, width: 1.5),
      textStyle: const TextStyle(fontSize: AppDimensions.fontTitle, fontWeight: FontWeight.w700),
    ),
  );

  static final TextButtonThemeData _lightTextButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryDark,
      textStyle: const TextStyle(fontSize: AppDimensions.fontBodyMd, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
    ),
  );

  static InputDecorationTheme get _lightInputDecorationTheme => InputDecorationTheme(
    filled: true,
    fillColor: AppColors.lightSurface,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      borderSide: const BorderSide(color: AppColors.grey300, width: 1),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(AppDimensions.radiusRound),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacing24, vertical: AppDimensions.spacing20),
    hintStyle: const TextStyle(color: AppColors.lightTextDisabled, fontSize: AppDimensions.fontBodyMd),
    prefixIconColor: AppColors.lightTextSecondary,
    suffixIconColor: AppColors.lightTextSecondary,
  );

  static const DividerThemeData _lightDividerTheme = DividerThemeData(
    color: AppColors.dividerLight,
    thickness: 1,
    space: 1,
  );

  static ChipThemeData get _lightChipTheme => ChipThemeData(
    backgroundColor: AppColors.lightSurfaceContainer,
    selectedColor: AppColors.primary5,
    labelStyle: const TextStyle(color: AppColors.lightTextPrimary, fontWeight: FontWeight.w600, fontSize: AppDimensions.fontCaption),
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
    side: BorderSide.none,
  );

  static NavigationBarThemeData get _lightNavigationBarTheme => NavigationBarThemeData(
    backgroundColor: AppColors.lightSurface,
    indicatorColor: AppColors.primary5,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final style = TextStyle(fontSize: AppDimensions.fontSm, fontWeight: FontWeight.w600);
      if (states.contains(WidgetState.selected)) {
        return style.copyWith(color: AppColors.primary);
      }
      return style.copyWith(color: AppColors.lightTextSecondary);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.primary, size: AppDimensions.iconLg);
      }
      return const IconThemeData(color: AppColors.lightTextSecondary, size: AppDimensions.iconDefault);
    }),
    elevation: 0,
    height: AppDimensions.spacing64 + AppDimensions.spacingXxl,
  );

  static const DialogThemeData _lightDialogTheme = DialogThemeData(
    backgroundColor: AppColors.lightCard,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusPill)),
    ),
    elevation: 8,
    titleTextStyle: TextStyle(fontSize: AppDimensions.fontDisplayXs, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary),
    contentTextStyle: TextStyle(fontSize: AppDimensions.fontBodyMd, color: AppColors.lightTextSecondary),
  );

  static const SnackBarThemeData _lightSnackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusRound))),
    elevation: 4,
  );

  static const FloatingActionButtonThemeData _lightFabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusPill))),
  );
}