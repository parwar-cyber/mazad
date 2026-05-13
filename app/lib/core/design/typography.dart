import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Locale-aware base text style. See ADR-0005 and `i18n-rtl` skill §Fonts.
///
/// - Latin (en/tr): Inter
/// - Arabic-script (ar/ku): Vazirmatn (covers Sorani glyphs ێ ۆ ڕ ڵ)
TextStyle baseStyleForLocale(String lang) {
  switch (lang) {
    case 'ar':
    case 'ku':
      return GoogleFonts.vazirmatn();
    case 'tr':
    case 'en':
    default:
      return GoogleFonts.inter();
  }
}

/// Build a [TextTheme] in the user's locale font, with tight headline
/// letter-spacing and tabular figures on numeric body styles.
TextTheme buildTextTheme({required String lang, required Color onSurface}) {
  final base = baseStyleForLocale(lang).copyWith(color: onSurface);

  TextStyle h(double size, FontWeight weight, {double spacing = -0.02}) =>
      base.copyWith(
        fontSize: size,
        fontWeight: weight,
        letterSpacing: size * spacing,
        height: 1.15,
      );

  TextStyle b(double size, {FontWeight weight = FontWeight.w400}) =>
      base.copyWith(fontSize: size, fontWeight: weight, height: 1.5);

  return TextTheme(
    displayLarge: h(48, FontWeight.w700),
    displayMedium: h(36, FontWeight.w700),
    headlineLarge: h(28, FontWeight.w700),
    headlineMedium: h(24, FontWeight.w600),
    headlineSmall: h(20, FontWeight.w600),
    titleLarge: h(18, FontWeight.w600, spacing: 0),
    titleMedium: b(16, weight: FontWeight.w600),
    bodyLarge: b(16),
    bodyMedium: b(14),
    bodySmall: b(12),
    labelLarge: b(14, weight: FontWeight.w600),
    labelMedium: b(12, weight: FontWeight.w600),
  );
}

/// Tabular-figure variant for prices, bid amounts, countdowns. Eliminates
/// horizontal jitter when numbers change in live bid feeds.
TextStyle tabularNumeric(TextStyle base) =>
    base.copyWith(fontFeatures: const [FontFeature.tabularFigures()]);
