import 'package:flutter/material.dart';

import '../l10n/strings.dart';

/// NutriGo brand colors.
///
/// Brand colors are constant. Neutral colors are getters that follow
/// [AppColors.dark], so the whole UI switches when dark mode toggles
/// (the app root rebuilds every widget when it changes).
class AppColors {
  AppColors._();

  static bool dark = false;

  // Brand navy (splash / login / hero cards gradient)
  static const navy900 = Color(0xFF001B39);
  static const navy800 = Color(0xFF002850);
  static const navy700 = Color(0xFF0B4984);
  static const navyCard = Color(0xFF1D4166);

  // Brand green
  static const green = Color(0xFF2E7D32);
  static const greenDark = Color(0xFF1B5E20);
  static const greenLight = Color(0xFF66BB6A);

  // Accents
  static const orange = Color(0xFFF57C00);
  static const red = Color(0xFFD32F2F);

  /// Text on surfaces that stay light in both modes (e.g. the login label card).
  static const inkFixed = Color(0xFF0F1F33);

  // ---- Neutrals (theme dependent) ----
  static Color get background =>
      dark ? const Color(0xFF0A111C) : const Color(0xFFF4F7FB);
  static Color get surface => dark ? const Color(0xFF141D2B) : Colors.white;
  static Color get border =>
      dark ? const Color(0xFF26324A) : const Color(0xFFE2E8F0);
  static Color get ink => dark ? const Color(0xFFE8EEF6) : inkFixed;
  static Color get muted =>
      dark ? const Color(0xFF94A3B8) : const Color(0xFF64748B);
  static Color get track =>
      dark ? const Color(0xFF26324A) : const Color(0xFFE6EBF1);

  // ---- Tints (theme dependent) ----
  static Color get greenTint =>
      dark ? const Color(0xFF14301B) : const Color(0xFFE8F3E9);
  static Color get greenSoft =>
      dark ? const Color(0xFF2E5A36) : const Color(0xFFCBDFCC);
  static Color get orangeTint =>
      dark ? const Color(0xFF3A2812) : const Color(0xFFFFF3E0);
  static Color get blueTint =>
      dark ? const Color(0xFF1C3150) : const Color(0xFFE3EDF7);
  static Color get selectedCard =>
      dark ? const Color(0xFF13261A) : const Color(0xFFF6FBF6);
  static Color get greenText => dark ? greenLight : green;

  static const heroGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy900, navy800, navy700],
  );
}

/// Typography: Montserrat for headings/numbers, Open Sans for body.
/// Arabic text falls back to the system Arabic font.
class AppText {
  AppText._();

  static String? get _headingFamily => L10n.arabic ? null : 'Montserrat';
  static String? get _bodyFamily => L10n.arabic ? null : 'Open Sans';

  static TextStyle heading(double size,
          {Color? color, FontWeight weight = FontWeight.w700}) =>
      TextStyle(
        fontFamily: _headingFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        height: L10n.arabic ? 1.35 : 1.2,
      );

  static TextStyle body(double size,
          {Color? color, FontWeight weight = FontWeight.w400}) =>
      TextStyle(
        fontFamily: _bodyFamily,
        fontSize: size,
        fontWeight: weight,
        color: color ?? AppColors.ink,
        height: L10n.arabic ? 1.45 : 1.35,
      );

  // Common presets
  static TextStyle get screenTitle => heading(30);
  static TextStyle get sectionTitle => heading(19);
  static TextStyle get barTitle => heading(20);
  static TextStyle get subtitle => body(15.3, color: AppColors.muted);
  static TextStyle get label => body(14.2, color: AppColors.muted);
  static TextStyle get caption => body(12, color: AppColors.muted);
  static TextStyle get overline =>
      body(12, color: AppColors.muted, weight: FontWeight.w700)
          .copyWith(letterSpacing: L10n.arabic ? 0 : 0.8);
  static TextStyle get button =>
      body(17.5, color: Colors.white, weight: FontWeight.w700);
}

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    brightness: AppColors.dark ? Brightness.dark : Brightness.light,
    colorScheme: ColorScheme.fromSeed(
      seedColor: AppColors.green,
      brightness: AppColors.dark ? Brightness.dark : Brightness.light,
      primary: AppColors.green,
      surface: AppColors.surface,
    ),
    scaffoldBackgroundColor: AppColors.background,
    dividerColor: AppColors.border,
  );
  return base.copyWith(
    textTheme: base.textTheme.apply(
      fontFamily: L10n.arabic ? null : 'Open Sans',
      bodyColor: AppColors.ink,
      displayColor: AppColors.ink,
    ),
    dialogTheme: DialogThemeData(backgroundColor: AppColors.surface),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      dragHandleColor: AppColors.border,
    ),
    snackBarTheme: const SnackBarThemeData(behavior: SnackBarBehavior.floating),
  );
}
