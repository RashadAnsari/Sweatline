import 'package:flutter/material.dart';

/// Sweatline visual identity: industrial gym utility.
/// Charcoal surfaces with a green cast, one loud volt-lime accent, and
/// Bebas Neue condensed display type for big numbers and headings.
/// Dark is the primary theme (phones get used between sets); light is a
/// bone/ink variant with the same accent.

const _volt = Color(0xFFC8F135);
const _voltDark = Color(0xFF4A5B00);
const _ink = Color(0xFF171A10);
const _bone = Color(0xFFF4F3EA);

const displayFont = 'BebasNeue';

ThemeData sweatlineDark() => _build(
  ColorScheme.fromSeed(seedColor: _volt, brightness: Brightness.dark).copyWith(
    primary: _volt,
    onPrimary: _ink,
    primaryContainer: const Color(0xFF39420E),
    onPrimaryContainer: const Color(0xFFDDF56E),
    secondaryContainer: const Color(0xFF262B1A),
    onSecondaryContainer: const Color(0xFFD5E3A8),
    tertiary: const Color(0xFFE8B44A),
    surface: const Color(0xFF12140D),
    onSurface: const Color(0xFFE4E6D9),
    surfaceContainerLowest: const Color(0xFF0C0E08),
    surfaceContainerLow: const Color(0xFF171A11),
    surfaceContainer: const Color(0xFF1B1F13),
    surfaceContainerHigh: const Color(0xFF222717),
    surfaceContainerHighest: const Color(0xFF2C321D),
    outline: const Color(0xFF5C6349),
    outlineVariant: const Color(0xFF3A4028),
    error: const Color(0xFFFF7A66),
  ),
);

ThemeData sweatlineLight() => _build(
  ColorScheme.fromSeed(seedColor: _volt).copyWith(
    primary: _voltDark,
    onPrimary: _bone,
    primaryContainer: _volt,
    onPrimaryContainer: const Color(0xFF232A00),
    secondaryContainer: const Color(0xFFE4E6CE),
    onSecondaryContainer: const Color(0xFF3C4028),
    tertiary: const Color(0xFF8A5D00),
    surface: _bone,
    onSurface: _ink,
    surfaceContainerLowest: const Color(0xFFFFFEF6),
    surfaceContainerLow: const Color(0xFFEDECE0),
    surfaceContainer: const Color(0xFFE7E6D8),
    surfaceContainerHigh: const Color(0xFFE0E0CF),
    surfaceContainerHighest: const Color(0xFFD6D6C2),
    outline: const Color(0xFF787A65),
    outlineVariant: const Color(0xFFC4C5AE),
  ),
);

ThemeData _build(ColorScheme scheme) {
  final base = ThemeData(colorScheme: scheme);
  final display = base.textTheme.copyWith(
    displayLarge: base.textTheme.displayLarge!.copyWith(
      fontFamily: displayFont,
      letterSpacing: 1.5,
    ),
    displayMedium: base.textTheme.displayMedium!.copyWith(
      fontFamily: displayFont,
      letterSpacing: 1.5,
    ),
    displaySmall: base.textTheme.displaySmall!.copyWith(
      fontFamily: displayFont,
      letterSpacing: 1.2,
    ),
    headlineLarge: base.textTheme.headlineLarge!.copyWith(
      fontFamily: displayFont,
      letterSpacing: 1.2,
    ),
    headlineMedium: base.textTheme.headlineMedium!.copyWith(
      fontFamily: displayFont,
      letterSpacing: 1.0,
    ),
    headlineSmall: base.textTheme.headlineSmall!.copyWith(
      fontFamily: displayFont,
      letterSpacing: 1.0,
    ),
    titleLarge: base.textTheme.titleLarge!.copyWith(
      fontFamily: displayFont,
      letterSpacing: 1.0,
    ),
  );

  return base.copyWith(
    textTheme: display,
    scaffoldBackgroundColor: scheme.surface,
    appBarTheme: AppBarTheme(
      backgroundColor: scheme.surface,
      foregroundColor: scheme.onSurface,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: display.headlineMedium!.copyWith(color: scheme.onSurface),
    ),
    cardTheme: CardThemeData(
      color: scheme.surfaceContainer,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: scheme.outlineVariant, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    chipTheme: base.chipTheme.copyWith(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      side: BorderSide(color: scheme.outlineVariant),
      backgroundColor: scheme.surfaceContainerLow,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: scheme.surfaceContainerLowest,
      indicatorColor: scheme.primaryContainer,
      height: 68,
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: display.titleLarge!.copyWith(fontSize: 20),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size.fromHeight(48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        side: BorderSide(color: scheme.outline),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outline),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: scheme.outlineVariant),
      ),
      filled: true,
      fillColor: scheme.surfaceContainerLow,
    ),
    dividerTheme: DividerThemeData(color: scheme.outlineVariant),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: scheme.inverseSurface,
      contentTextStyle: base.textTheme.bodyMedium!.copyWith(
        color: scheme.onInverseSurface,
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: scheme.surfaceContainer,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: FadeForwardsPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      },
    ),
  );
}
