import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import '../constants/app_dimensions.dart';

abstract final class AppTheme {
  static ThemeData get light => dark;

  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    textTheme: AppTextStyles.dark,
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
    scaffoldBackgroundColor: AppColors.background,
    dialogTheme: _dialogTheme,
    snackBarTheme: _snackBarTheme,
    floatingActionButtonTheme: _fabTheme,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryLight,
      linearTrackColor: AppColors.grey800,
    ),
  );

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

  static const AppBarTheme _appBarTheme = AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    backgroundColor: AppColors.transparent,
    foregroundColor: AppColors.textPrimary,
    systemOverlayStyle: SystemUiOverlayStyle.light,
    titleTextStyle: TextStyle(
      fontSize: 22, fontWeight: FontWeight.w700, color: AppColors.textPrimary,
    ),
  );

  static const CardThemeData _cardTheme = CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusRound)),
      side: BorderSide(color: AppColors.glassBorder, width: 1),
    ),
    color: AppColors.card,
    margin: EdgeInsets.symmetric(vertical: AppDimensions.spacingMd),
  );

  static final FilledButtonThemeData _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusRound)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      elevation: 0,
    ),
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusRound)),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
      elevation: 2,
      shadowColor: AppColors.primary25,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      minimumSize: const Size(double.infinity, AppDimensions.buttonMinHeight),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusRound)),
      side: BorderSide(color: AppColors.primary20, width: 1.5),
      textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primaryLight,
      textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
    ),
  );

  static InputDecorationTheme get _inputDecorationTheme => InputDecorationTheme(
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
    hintStyle: const TextStyle(color: AppColors.textDisabled, fontSize: 14),
    prefixIconColor: AppColors.textSecondary,
    suffixIconColor: AppColors.textSecondary,
  );

  static const DividerThemeData _dividerTheme = DividerThemeData(
    color: AppColors.divider,
    thickness: 1,
    space: 1,
  );

  static ChipThemeData get _chipTheme => ChipThemeData(
    backgroundColor: AppColors.surfaceContainerHigh,
    selectedColor: AppColors.primary15,
    labelStyle: const TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w600, fontSize: 12),
    padding: const EdgeInsets.symmetric(horizontal: AppDimensions.spacingXxl, vertical: AppDimensions.spacingMd),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppDimensions.radiusXxl)),
    side: BorderSide.none,
  );

  static NavigationBarThemeData get _navigationBarTheme => NavigationBarThemeData(
    backgroundColor: AppColors.surface,
    indicatorColor: AppColors.primary10,
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      const style = TextStyle(fontSize: 11, fontWeight: FontWeight.w600);
      if (states.contains(WidgetState.selected)) {
        return style.copyWith(color: AppColors.primary);
      }
      return style.copyWith(color: AppColors.textSecondary);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return const IconThemeData(color: AppColors.primary, size: 26);
      }
      return const IconThemeData(color: AppColors.textSecondary, size: 24);
    }),
    elevation: 0,
    height: 72,
  );

  static const DialogThemeData _dialogTheme = DialogThemeData(
    backgroundColor: AppColors.card,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusPill)),
    ),
    elevation: 8,
    titleTextStyle: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
    contentTextStyle: TextStyle(fontSize: 14, color: AppColors.textSecondary),
  );

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusRound))),
    elevation: 4,
  );

  static const FloatingActionButtonThemeData _fabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(AppDimensions.radiusPill))),
  );

  AppTheme._();
}