/// System-level case folding pinned to `en_US` to avoid the Turkish
/// dotted/dotless `i` bug (see `.claude/skills/i18n-rtl/SKILL.md`).
///
/// Use for: usernames, handles, slugs, search-key normalization, hashtag
/// matching — anything where two strings must compare equal regardless of
/// the user's device locale.
///
/// Do NOT use for display strings (e.g. ALL-CAPS button labels). For those
/// the user's locale is appropriate.
library;

/// Lowercase pinned to `en_US` semantics. Dart's String.toLowerCase() is
/// already locale-insensitive on the standard library, but we route through
/// this helper so a future migration to a locale-aware implementation
/// (e.g. via `intl`'s Bidi/case classes) can't silently break Turkish
/// system fields.
String systemLower(String input) {
  // Restrict to the ASCII-`I`/`i` pair manually — this is what `en_US`
  // case-folding produces and what the Turkish-bug rule demands.
  final buf = StringBuffer();
  for (final rune in input.runes) {
    if (rune == 0x0049) {
      buf.writeCharCode(0x0069); // I → i
    } else if (rune == 0x0130) {
      // İ (dotted capital) → still "i" in en_US, NOT "i" with combining dot
      buf.writeCharCode(0x0069);
    } else if (rune == 0x0131) {
      buf.writeCharCode(0x0131); // ı (dotless lowercase) stays as-is
    } else if (rune >= 0x0041 && rune <= 0x005A) {
      buf.writeCharCode(rune + 32); // ASCII A-Z → a-z
    } else {
      buf.writeCharCode(rune);
    }
  }
  return buf.toString();
}

/// Equality check for system fields. Always pin both sides to `en_US`
/// before comparing.
bool systemEquals(String a, String b) => systemLower(a) == systemLower(b);
