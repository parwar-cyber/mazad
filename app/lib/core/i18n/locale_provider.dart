import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Supported locales (ADR-0003 / architecture.md §7).
/// `ar` and `ku` are RTL; `en` and `tr` are LTR.
const supportedLocales = <Locale>[
  Locale('en'),
  Locale('ar'),
  Locale('ku'),
  Locale('tr'),
];

bool isRtlLanguage(String languageCode) =>
    languageCode == 'ar' || languageCode == 'ku';

/// Current locale. Phase 0: in-memory only. Phase 1 will persist to
/// `profiles.locale` once auth is wired.
final localeProvider = StateProvider<Locale>((ref) => const Locale('en'));
