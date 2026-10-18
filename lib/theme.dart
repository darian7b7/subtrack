import 'package:flutter/material.dart';

const _seed = Color(0xFF2F6B5A);

ThemeData buildTheme(Brightness brightness) {
  final dark = brightness == Brightness.dark;
  final scheme = ColorScheme.fromSeed(
    seedColor: _seed,
    brightness: brightness,
    dynamicSchemeVariant: DynamicSchemeVariant.fidelity,
  ).copyWith(
    surface: dark ? const Color(0xFF111513) : const Color(0xFFF3F5F2),
    surfaceContainerLow: dark ? const Color(0xFF1A201D) : Colors.white,
    surfaceContainerHigh: dark ? const Color(0xFF232A26) : const Color(0xFFE9EDE9),
  );

  final radius = BorderRadius.circular(16);
  return ThemeData(
    useMaterial3: true,
    colorScheme: scheme,
    scaffoldBackgroundColor: scheme.surface,
    // InkRipple, not InkSparkle: the sparkle effect loads a shader on first
    // tap and costs extra GPU time on every frame it runs.
    splashFactory: InkRipple.splashFactory,
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: scheme.surfaceContainerHigh,
      border: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(borderRadius: radius, borderSide: BorderSide(color: scheme.primary, width: 2)),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        minimumSize: const Size(0, 54),
        shape: RoundedRectangleBorder(borderRadius: radius),
        textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        minimumSize: const Size(0, 48),
        shape: RoundedRectangleBorder(borderRadius: radius),
      ),
    ),
    chipTheme: ChipThemeData(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: scheme.surface,
      showDragHandle: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: radius),
    ),
    pageTransitionsTheme: PageTransitionsTheme(
      builders: {for (final p in TargetPlatform.values) p: FadeForwardsPageTransitionsBuilder()},
    ),
  );
}

/// Semantic colors: trial warnings and savings. Kept apart from the brand
/// accent so a warning never looks like a button.
class Tones {
  const Tones(this.warn, this.warnBg, this.onWarnBg, this.good, this.goodBg, this.onGoodBg);
  final Color warn, warnBg, onWarnBg, good, goodBg, onGoodBg;

  static const _light = Tones(
    Color(0xFFE8961E),
    Color(0xFFFFF0D4),
    Color(0xFF4A3000),
    Color(0xFF2E8B57),
    Color(0xFFE3F3E8),
    Color(0xFF0F3D22),
  );
  static const _dark = Tones(
    Color(0xFFF5B04A),
    Color(0xFF3A2A0E),
    Color(0xFFFFE2B0),
    Color(0xFF6BCB94),
    Color(0xFF173323),
    Color(0xFFCFF0DB),
  );

  static Tones of(BuildContext context) => Theme.of(context).brightness == Brightness.dark ? _dark : _light;
}
