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
      color: AppColors.primaryLight,
      linearTrackColor: AppColors.grey800,
    ),
  );

  static const ColorScheme _lightColorScheme = ColorScheme(
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: Color(0xFFD1E4FF),
    onPrimaryContainer: Color(0xFF001D36),
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: Color(0xFFCEE5FF),
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
    onPrimaryContainer: Color(0xFFD1E4FF),
    secondary: AppColors.secondaryLight,
    onSecondary: Color(0xFF00363D),
    secondaryContainer: AppColors.secondaryDark,
    onSecondaryContainer: Color(0xFF80CBC4),
    surface: AppColors.surfaceDark,
    onSurface: AppColors.textPrimaryDark,
    surfaceContainerLowest: Color(0xFF0F1115),
    surfaceContainerLow: Color(0xFF1A1D24),
    surfaceContainer: Color(0xFF222831),
    surfaceContainerHigh: Color(0xFF2A313C),
    surfaceContainerHighest: Color(0xFF343D4B),
    error: Color(0xFFFFB4AB),
    onError: Color(0xFF690005),
    outline: AppColors.dividerDark,
  );

  static TextTheme _textTheme({required bool dark}) {
    final color = dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    return TextTheme(
      displayLarge: AppTextStyles.displayLarge.copyWith(color: color, letterSpacing: -1),
      displayMedium: AppTextStyles.displayMedium.copyWith(color: color, letterSpacing: -0.5),
      displaySmall: AppTextStyles.displaySmall.copyWith(color: color),
      headlineLarge: AppTextStyles.headlineLarge.copyWith(color: color, fontWeight: FontWeight.w800),
      headlineMedium: AppTextStyles.headlineMedium.copyWith(color: color, fontWeight: FontWeight.w700),
      headlineSmall: AppTextStyles.headlineSmall.copyWith(color: color, fontWeight: FontWeight.w600),
      titleLarge: AppTextStyles.titleLarge.copyWith(color: color),
      titleMedium: AppTextStyles.titleMedium.copyWith(color: color),
      titleSmall: AppTextStyles.titleSmall.copyWith(color: color),
      bodyLarge: AppTextStyles.bodyLarge.copyWith(color: color),
      bodyMedium: AppTextStyles.bodyMedium.copyWith(color: color),
      bodySmall: AppTextStyles.bodySmall.copyWith(
        color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
      ),
      labelLarge: AppTextStyles.labelLarge.copyWith(color: color, fontWeight: FontWeight.w600),
      labelMedium: AppTextStyles.labelMedium.copyWith(color: color),
      labelSmall: AppTextStyles.labelSmall.copyWith(
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
    systemOverlayStyle: dark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
    titleTextStyle: AppTextStyles.titleLarge.copyWith(
      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      fontWeight: FontWeight.w700,
    ),
  );

  static CardThemeData _cardTheme({required bool dark}) => CardThemeData(
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(20),
      side: BorderSide(
        color: dark ? AppColors.dividerDark.withOpacity(0.5) : AppColors.dividerLight.withOpacity(0.5),
      ),
    ),
    color: dark ? AppColors.cardDark : AppColors.cardLight,
    margin: const EdgeInsets.symmetric(vertical: 8),
  );

  static final FilledButtonThemeData _filledButtonTheme = FilledButtonThemeData(
    style: FilledButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      elevation: 0,
    ),
  );

  static final ElevatedButtonThemeData _elevatedButtonTheme = ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
      elevation: 2,
      shadowColor: AppColors.primary.withOpacity(0.3),
    ),
  );

  static final OutlinedButtonThemeData _outlinedButtonTheme = OutlinedButtonThemeData(
    style: OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      minimumSize: const Size(double.infinity, 54),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      side: const BorderSide(color: AppColors.dividerLight, width: 1.5),
      textStyle: AppTextStyles.labelLarge.copyWith(fontSize: 16, fontWeight: FontWeight.w700),
    ),
  );

  static final TextButtonThemeData _textButtonTheme = TextButtonThemeData(
    style: TextButton.styleFrom(
      foregroundColor: AppColors.primary,
      textStyle: AppTextStyles.labelLarge.copyWith(fontWeight: FontWeight.w700),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
    ),
  );

  static InputDecorationTheme _inputDecorationTheme({required bool dark}) => InputDecorationTheme(
    filled: true,
    fillColor: dark ? AppColors.surfaceDark : AppColors.grey50,
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide.none,
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: dark ? AppColors.dividerDark : AppColors.dividerLight,
        width: 1,
      ),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.primary, width: 2),
    ),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColors.error, width: 1.5),
    ),
    contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
    hintStyle: AppTextStyles.bodyMedium.copyWith(
      color: dark ? AppColors.textDisabledDark : AppColors.textDisabledLight,
    ),
    prefixIconColor: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    suffixIconColor: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
  );

  static DividerThemeData _dividerTheme({required bool dark}) => DividerThemeData(
    color: dark ? AppColors.dividerDark : AppColors.dividerLight,
    thickness: 1,
    space: 1,
  );

  static ChipThemeData _chipTheme({required bool dark}) => ChipThemeData(
    backgroundColor: dark ? Color(0xFF2A313C) : AppColors.grey100,
    selectedColor: AppColors.primary.withOpacity(0.15),
    labelStyle: AppTextStyles.labelMedium.copyWith(
      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      fontWeight: FontWeight.w600,
    ),
    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    side: BorderSide.none,
  );

  static NavigationBarThemeData _navigationBarTheme({required bool dark}) => NavigationBarThemeData(
    backgroundColor: dark ? AppColors.surfaceDark : AppColors.surfaceLight,
    indicatorColor: AppColors.primary.withOpacity(0.1),
    labelTextStyle: WidgetStateProperty.resolveWith((states) {
      final style = AppTextStyles.labelSmall.copyWith(fontWeight: FontWeight.w600);
      if (states.contains(WidgetState.selected)) {
        return style.copyWith(color: AppColors.primary);
      }
      return style.copyWith(color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight);
    }),
    iconTheme: WidgetStateProperty.resolveWith((states) {
      if (states.contains(WidgetState.selected)) {
        return IconThemeData(color: AppColors.primary, size: 26);
      }
      return IconThemeData(color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight, size: 24);
    }),
    elevation: 0,
    height: 72,
  );

  static DialogThemeData _dialogTheme({required bool dark}) => DialogThemeData(
    backgroundColor: dark ? AppColors.cardDark : AppColors.cardLight,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
    elevation: 8,
    titleTextStyle: AppTextStyles.headlineSmall.copyWith(
      color: dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
    ),
    contentTextStyle: AppTextStyles.bodyLarge.copyWith(
      color: dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
    ),
  );

  static const SnackBarThemeData _snackBarTheme = SnackBarThemeData(
    behavior: SnackBarBehavior.floating,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(16))),
    elevation: 4,
  );

  static const FloatingActionButtonThemeData _fabTheme = FloatingActionButtonThemeData(
    backgroundColor: AppColors.primary,
    foregroundColor: AppColors.white,
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(18))),
  );

  AppTheme._();
}