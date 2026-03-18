import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';

/// Temas de la aplicación WorkSense (claro y oscuro).
/// Uso en MaterialApp:
///   theme: AppTheme.light,
///   darkTheme: AppTheme.dark,
abstract final class AppTheme {
  // ─────────────────────────────────────────────────────────
  // TEMA CLARO
  // ─────────────────────────────────────────────────────────
  static ThemeData get light => ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    colorScheme: _lightColorScheme,
    textTheme: _textTheme(dark: false),
    appBarTheme: _appBarTheme(dark: false),
    cardTheme: _cardTheme(dark: false),
    elevatedButtonTheme: _elevatedButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    inputDecorationTheme: _inputDecorationTheme(dark: false),
    dividerTheme: _dividerTheme(dark: false),
    chipTheme: _chipTheme(dark: false),
    navigationBarTheme: _navigationBarTheme(dark: false),
    scaffoldBackgroundColor: AppColors.backgroundLight,
    dialogTheme: _dialogTheme(dark: false),
    snackBarTheme: _snackBarTheme,
    floatingActionButtonTheme: _fabTheme,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
    ),
  );

  // ─────────────────────────────────────────────────────────
  // TEMA OSCURO
  // ─────────────────────────────────────────────────────────
  static ThemeData get dark => ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    colorScheme: _darkColorScheme,
    textTheme: _textTheme(dark: true),
    appBarTheme: _appBarTheme(dark: true),
    cardTheme: _cardTheme(dark: true),
    elevatedButtonTheme: _elevatedButtonTheme,
    outlinedButtonTheme: _outlinedButtonTheme,
    textButtonTheme: _textButtonTheme,
    inputDecorationTheme: _inputDecorationTheme(dark: true),
    dividerTheme: _dividerTheme(dark: true),
    chipTheme: _chipTheme(dark: true),
    navigationBarTheme: _navigationBarTheme(dark: true),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    dialogTheme: _dialogTheme(dark: true),
    snackBarTheme: _snackBarTheme,
    floatingActionButtonTheme: _fabTheme,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primaryLight,
    ),
  );

  // ─────────────────────────────────────────────────────────
  // COLOR SCHEMES
  // ─────────────────────────────────────────────────────────
  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.infoBg,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: Color(0xFFB2EBE0),
    onSecondaryContainer: AppColors.secondaryDark,
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorBg,
    onErrorContainer: Color(0xFFB00020),
    outline: AppColors.grey300,
    outlineVariant: AppColors.grey200,
    shadow: AppColors.black,
    surfaceContainerHighest: AppColors.grey100,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryLight,
    onPrimary: AppColors.black,
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: AppColors.primaryLight,
    secondary: AppColors.secondaryLight,
    onSecondary: AppColors.black,
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: AppColors.secondaryLight,
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    error: Color(0xFFCF6679),
    onError: AppColors.black,
    errorContainer: Color(0xFF93000A),
    onErrorContainer: Color(0xFFFFDAD6),
    outline: AppColors.grey700,
    outlineVariant: AppColors.grey800,
    shadow: AppColors.black,
    surfaceContainerHighest: AppColors.grey800,
  );

  // ─────────────────────────────────────────────────────────
  // TEXT THEME
  // ─────────────────────────────────────────────────────────
  static TextTheme _textTheme({required bool dark}) {
    final color =
    dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: color),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: color),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: color),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: color),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: color),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: color),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: color),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: color),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: color),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: color),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: color),
      bodySmall: AppTextStyles.bodySmall.copyWith(
        color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: color),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: color),
      labelSmall: AppTextStyles.labelSmall.copyWith(
        color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  // ─────────────────────────────────────────────────────────
  // COMPONENTES
  // ─────────────────────────────────────────────────────────
  static AppBarTheme _appBarTheme({required bool dark}) => AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 1,
    centerTitle: false,
    backgroundColor:
    dark ? AppColors.surfaceDark : AppColors.surfaceLight,
    foregroundColor:
    dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    systemOverlayStyle: dark
        ? SystemUiOverlayStyle.light
        : SystemUiOverlayStyle.dark,
    titleTextStyle: AppTextStyles.titleLarge.copyWith(
      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    ),
  );

  static CardThemeData _cardTheme({required bool dark}) => CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: BorderSide(
        color: dark ? AppColors.dividerDark : AppColors.dividerLight,
      ),
    ),
    color: dark ? AppColors.cardDark : AppColors.cardLight,
    margin: const EdgeInsets.symmetric(vertical: 4),
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme =
  ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16),
      elevation: 0,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme =
  OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      side: const BorderSide(color: AppColors.primary),
      textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16),
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: AppTextStyles.labelLarge,
    ),
  );

  static InputDecorationTheme _inputDecorationTheme({required bool dark}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: dark ? AppColors.grey800 : AppColors.grey100,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: dark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error),
        ),
        contentPadding:
        const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: dark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
        ),
      );

  static DividerThemeData _dividerTheme({required bool dark}) =>
      DividerThemeData(
        color: dark ? AppColors.dividerDark : AppColors.dividerLight,
        thickness: 1,
        space: 1,
      );

  static ChipThemeData _chipTheme({required bool dark}) => ChipThemeData(
    backgroundColor: dark ? AppColors.grey800 : AppColors.grey100,
    selectedColor: AppColors.infoBg,
    labelStyle: AppTextStyles.labelMedium,
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
  );

  static NavigationBarThemeData _navigationBarTheme({required bool dark}) =>
      NavigationBarThemeData(
        backgroundColor: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
        indicatorColor: AppColors.infoBg,
        labelTextStyle: WidgetStateProperty.all(AppTextStyles.labelSmall),
        elevation: 0,
      );

  static DialogThemeData _dialogTheme({required bool dark}) => DialogThemeData(
    backgroundColor: dark ? AppColors.cardDark : AppColors.cardLight,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
    ),
    titleTextStyle: AppTextStyles.titleLarge.copyWith(
      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    ),
  );

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(10)),
    ),
  );

  static const FloatingActionButtonThemeData _fabTheme =
  FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 2,
  );

  AppTheme._();
}