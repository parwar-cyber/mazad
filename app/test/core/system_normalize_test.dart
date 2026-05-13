import 'package:flutter_test/flutter_test.dart';
import 'package:mazad/core/i18n/system_normalize.dart';

void main() {
  group('systemLower — Turkish dotted/dotless-i bug class', () {
    test('en_US semantics: uppercase I → i, never İ', () {
      expect(systemLower('I'), 'i');
      expect(systemLower('Istanbul'), 'istanbul');
    });

    test('uppercase İ (dotted, U+0130) → i (not "i with combining dot")', () {
      // Turkish locale-aware lower() would yield "i" with a combining dot
      // mark. We must collapse to plain ASCII "i" so equality with the
      // canonical lowercase "i" holds.
      expect(systemLower('İstanbul'), 'istanbul');
    });

    test('lowercase ı (dotless, U+0131) is preserved as ı', () {
      // We don't fold ı → i — that would collide ı (the legitimate
      // dotless lowercase) with i (the dotted one). System fields keep
      // them distinct just as they're distinct in Unicode.
      expect(systemLower('ı').codeUnits.first, 0x0131);
    });

    test('user-input variants of "Istanbul" still collide as needed', () {
      // The bug we are preventing: "Istanbul" typed by a Turkish user
      // and "ISTANBUL" pasted by an English user must collide for
      // uniqueness, slug, etc.  Both should normalize to "istanbul".
      expect(systemLower('Istanbul'), systemLower('ISTANBUL'));
      // BUT "İstanbul" (with dotted capital) ALSO must collapse to the
      // same canonical key.
      expect(systemLower('İstanbul'), systemLower('Istanbul'));
    });

    test('ASCII A-Z folded; non-Latin left alone', () {
      expect(systemLower('MAZAD'), 'mazad');
      expect(systemLower('مزاد'), 'مزاد');
      expect(systemLower('کوردی'), 'کوردی');
    });
  });

  group('systemEquals', () {
    test('case-insensitive equality holds across the Turkish-i variants', () {
      expect(systemEquals('Istanbul', 'istanbul'), isTrue);
      expect(systemEquals('İSTANBUL', 'istanbul'), isTrue);
    });
  });
}
