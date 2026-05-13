import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';

/// Locale-aware IQD formatter. See `.claude/skills/money-handling/SKILL.md`.
///
/// All money values are integers. Never `double`, `num`, or `decimal`.
///
/// Output examples for `25000`:
///   en → `25,000 IQD`
///   ar → `25,000 د.ع`
///   ku → `25,000 IQD`
///   tr → `25.000 IQD`   ← period thousands separator
///
/// The Turkish thousands separator is the single most common formatting bug;
/// unit tests assert it explicitly.
String formatIQD(int amount, Locale locale) {
  final lang = locale.languageCode;
  final formatter = NumberFormat.decimalPattern(_intlLocale(lang));
  final number = formatter.format(amount);

  switch (lang) {
    case 'ar':
      return '$number د.ع';
    case 'en':
    case 'ku':
    case 'tr':
    default:
      return '$number IQD';
  }
}

String _intlLocale(String lang) {
  switch (lang) {
    case 'ar':
      return 'ar';
    case 'ku':
      // Sorani uses Arabic-script number-formatting conventions.
      return 'ar';
    case 'tr':
      return 'tr';
    case 'en':
    default:
      return 'en_US';
  }
}

/// 5% of current high, with 1000 IQD floor. Mirror of the server-side
/// computation in `place_bid()` — server is authoritative; this is for
/// display only. See architecture.md §6.1.
int minimumBidIncrement(int currentHigh) {
  final fivePercent = (currentHigh * 5) ~/ 100;
  return fivePercent < 1000 ? 1000 : fivePercent;
}

/// Integer fee math. `(hammer * pct) ~/ 100`. Truncation by design.
int calculatePercentageFee(int amount, int percent) =>
    (amount * percent) ~/ 100;
