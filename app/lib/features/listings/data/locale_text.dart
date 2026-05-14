/// Reads a `{en, ar, ku, tr}` UGC map with the locale-fallback chain
/// documented in `.claude/skills/i18n-rtl/SKILL.md` §UGC.
///
/// Fallback: user's locale → en → ar → ku → tr → first non-empty value.
String localizedUgc(Map<String, dynamic> translations, String lang) {
  String? pick(String key) {
    final v = translations[key];
    if (v is String && v.trim().isNotEmpty) return v;
    return null;
  }

  final preferred = pick(lang);
  if (preferred != null) return preferred;
  for (final fb in const ['en', 'ar', 'ku', 'tr']) {
    final v = pick(fb);
    if (v != null) return v;
  }
  return '';
}
