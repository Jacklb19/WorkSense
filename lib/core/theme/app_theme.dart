import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app_colors.dart';
import 'app_text_styles.dart';
import 'app_theme_colors.dart';

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
    filledButtonTheme: _filledButtonTheme,
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
      linearTrackColor: AppColors.grey100,
    ),
    splashColor: AppColors.primary.withValues(alpha: 0.08),
    highlightColor: AppColors.primary.withValues(alpha: 0.05),
    extensions: const [AppThemeColors.light],
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
    filledButtonTheme: _filledButtonTheme,
    inputDecorationTheme: _inputDecorationTheme(dark: true),
    dividerTheme: _dividerTheme(dark: true),
    chipTheme: _chipTheme(dark: true),
    navigationBarTheme: _navigationBarTheme(dark: true),
    scaffoldBackgroundColor: AppColors.backgroundDark,
    dialogTheme: _dialogTheme(dark: true),
    snackBarTheme: _snackBarTheme,
    floatingActionButtonTheme: _fabTheme,
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: AppColors.primary,
      linearTrackColor: AppColors.dividerDark,
    ),
    splashColor: AppColors.primary.withValues(alpha: 0.08),
    highlightColor: AppColors.primary.withValues(alpha: 0.04),
    extensions: const [AppThemeColors.dark],
  );

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: Color(0xFFDDEBFF),
    onPrimaryContainer: Color(0xFF001D36),
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: Color(0xFFCCF5FF),
    onSecondaryContainer: Color(0xFF001D31),
    surface: AppColors.surfaceLight,
    onSurface: AppColors.textPrimaryLight,
    surfaceContainerLowest: AppColors.white,
    surfaceContainerLow: AppColors.grey50,
    surfaceContainer: AppColors.grey100,
    surfaceContainerHigh: AppColors.grey200,
    surfaceContainerHighest: AppColors.grey300,
    error: AppColors.error,
    onError: AppColors.white,
    outline: AppColors.dividerLight,
  );

  static const ColorScheme _darkColorScheme = ColorScheme(
    brightness: Brightness.dark,
    primary: AppColors.primaryLight,
    onPrimary: Color(0xFF003258),
    primaryContainer: AppColors.primaryDark,
    onPrimaryContainer: Color(0xFFDDEBFF),
    secondary: AppColors.secondaryLight,
    onSecondary: Color(0xFF00363D),
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: Color(0xFF67E8F9),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    surfaceContainerLowest: AppColors.backgroundDark,
    surfaceContainerLow: AppColors.surfaceDark,
    surfaceContainer: AppColors.cardDark,
    surfaceContainerHigh: Color(0xFF1A2540),
    surfaceContainerHighest: Color(0xFF1E2D4A),
    error: Color(0xFFFF6B6B),
    onError: Color(0xFF690005),
    outline: AppColors.dividerDark,
  );

  static TextTheme _textTheme({required bool dark}) {
    final color = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return TextTheme(
      displayLarge:  AppTextStyles.displayLarge.copyWith(color: color, letterSpacing: -1.5),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: color, letterSpacing: -1),
      displaySmall:  AppTextStyles.displaySmall.copyWith(color: color, letterSpacing: -0.5),
      headlineLarge:  AppTextStyles.headlineLarge.copyWith(color: color, fontWeight: FontWeight.w800, letterSpacing: -0.5),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: color, fontWeight: FontWeight.w700),
      headlineSmall:  AppTextStyles.headlineSmall.copyWith(color: color, fontWeight: FontWeight.w700),
      titleLarge:  AppTextStyles.titleLarge.copyWith(color: color, fontWeight: FontWeight.w700),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: color, fontWeight: FontWeight.w600),
      titleSmall:  AppTextStyles.titleSmall.copyWith(color: color, fontWeight: FontWeight.w600),
      bodyLarge:  AppTextStyles.bodyLarge.copyWith(color: color),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: color),
      bodySmall:  AppTextStyles.bodySmall.copyWith(
        color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      labelLarge:  AppTextStyles.labelLarge.copyWith(color: color, fontWeight: FontWeight.w700),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: color, fontWeight: FontWeight.w600),
      labelSmall:  AppTextStyles.labelSmall.copyWith(
        color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
    );
  }

  static AppBarTheme _appBarTheme({required bool dark}) => AppBarTheme(
    elevation: 0,
    scrolledUnderElevation: 0,
    centerTitle: false,
    backgroundColor: Colors.transparent,
    foregroundColor: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    systemOverlayStyle: dark
        ? SystemUiOverlayStyle.light.copyWith(statusBarColor: Colors.transparent)
        : SystemUiOverlayStyle.dark.copyWith(statusBarColor: Colors.transparent),
    titleTextStyle: AppTextStyles.titleLarge.copyWith(
      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      fontWeight: FontWeight.w800,
      letterSpacing: 0.2,
    ),
    iconTheme: IconThemeData(
      color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      size: 22,
    ),
  );

  static CardThemeData _cardTheme({required bool dark}) => CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: dark ? AppColors.dividerDark : AppColors.dividerLight,
      ),
    ),
    color: dark ? AppColors.cardDark : AppColors.cardLight,
    margin: const EdgeInsets.symmetric(vertical: 6),
    shadowColor: dark
        ? AppColors.primary.withValues(alpha: 0.05)
        : AppColors.grey400.withValues(alpha: 0.15),
  );

  static final FilledButtonThemeData _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: AppTextStyles.labelLarge.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: 0.3,
      ),
      elevation: 0,
    ),
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      textStyle: AppTextStyles.labelLarge.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
      elevation: 0,
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(double.infinity, 52),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5), width: 1.5),
      textStyle: AppTextStyles.labelLarge.copyWith(
        fontSize: 15,
        fontWeight: FontWeight.w700,
      ),
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static InputDecorationTheme _inputDecorationTheme({required bool dark}) =>
      InputDecorationTheme(
        filled: true,
        fillColor: dark
            ? AppColors.surfaceDark
            : AppColors.grey50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: dark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 1.5),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: AppColors.error, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        hintStyle: AppTextStyles.bodyMedium.copyWith(
          color: dark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
        ),
        prefixIconColor: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        suffixIconColor: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        labelStyle: AppTextStyles.bodyMedium.copyWith(
          color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        floatingLabelStyle: AppTextStyles.labelSmall.copyWith(
          color: AppColors.primary,
          fontWeight: FontWeight.w600,
        ),
      );

  static DividerThemeData _dividerTheme({required bool dark}) => DividerThemeData(
    color: dark ? AppColors.dividerDark : AppColors.dividerLight,
    thickness: 1,
    space: 1,
  );

  static ChipThemeData _chipTheme({required bool dark}) => ChipThemeData(
    backgroundColor: dark ? AppColors.cardDark : AppColors.grey100,
    selectedColor: AppColors.primary.withValues(alpha: 0.15),
    labelStyle: AppTextStyles.labelMedium.copyWith(
      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      fontWeight: FontWeight.w600,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(10),
      side: BorderSide(color: dark ? AppColors.dividerDark : AppColors.dividerLight),
    ),
  );

  static NavigationBarThemeData _navigationBarTheme({required bool dark}) =>
      NavigationBarThemeData(
        backgroundColor: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
        indicatorColor: AppColors.primary.withValues(alpha: 0.15),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        surfaceTintColor: Colors.transparent,
        shadowColor: Colors.transparent,
        elevation: 0,
        height: 68,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final base = AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w700);
          if (states.contains(WidgetState.selected)) {
            return base.copyWith(color: AppColors.primary);
          }
          return base.copyWith(
            color: dark ? AppColors.textDisabledDark : AppColors.grey400,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: AppColors.primary, size: 24);
          }
          return IconThemeData(
            color: dark ? AppColors.textDisabledDark : AppColors.grey400,
            size: 22,
          );
        }),
      );

  static DialogThemeData _dialogTheme({required bool dark}) => DialogThemeData(
    backgroundColor: dark ? AppColors.surfaceDark : AppColors.cardLight,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(24)),
    ),
    elevation: 0,
    shadowColor: Colors.transparent,
    titleTextStyle: AppTextStyles.headlineSmall.copyWith(
      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      fontWeight: FontWeight.w700,
    ),
    contentTextStyle: AppTextStyles.bodyLarge.copyWith(
      color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    ),
  );

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(14)),
    ),
    elevation: 0,
    backgroundColor: AppColors.snackBarBg,
    contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.w500),
  );

  static const FloatingActionButtonThemeData _fabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 0,
    focusElevation: 0,
    hoverElevation: 0,
    highlightElevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.all(Radius.circular(16)),
    ),
  );

  AppTheme._();
}
