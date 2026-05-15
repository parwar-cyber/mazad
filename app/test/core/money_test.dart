import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mazad/core/money/money_format.dart';

void main() {
  // intl number-formatters need locale data initialized before use.
  setUpAll(() async {
    await initializeDateFormatting();
  });

  group('formatIQD — locale-aware thousands separators', () {
    test('English uses comma', () {
      expect(formatIQD(25000, const Locale('en')), '25,000 IQD');
    });

    test('Turkish uses period (the bug class to guard)', () {
      expect(formatIQD(25000, const Locale('tr')), '25.000 IQD');
    });

    test('Arabic uses Arabic currency mark', () {
      // intl's Arabic numeric formatter outputs Western digits by default,
      // grouped by Arabic conventions.
      final out = formatIQD(25000, const Locale('ar'));
      expect(out.endsWith('د.ع'), isTrue, reason: 'must end with IQD mark');
      expect(out.contains('25'), isTrue);
    });

    test('Kurdish (Sorani) uses Arabic-script numeric grouping, "IQD" suffix',
        () {
      final out = formatIQD(25000, const Locale('ku'));
      expect(out.endsWith('IQD'), isTrue);
      expect(out.contains('25'), isTrue);
    });

    test('zero formats cleanly', () {
      expect(formatIQD(0, const Locale('en')), '0 IQD');
      expect(formatIQD(0, const Locale('tr')), '0 IQD');
    });

    test('one million formats correctly in EN and TR', () {
      expect(formatIQD(1000000, const Locale('en')), '1,000,000 IQD');
      expect(formatIQD(1000000, const Locale('tr')), '1.000.000 IQD');
    });
  });

  group('minimumBidIncrement', () {
    test('floors at 1000 for low current high', () {
      expect(minimumBidIncrement(0), 1000);
      expect(minimumBidIncrement(10000), 1000); // 5% = 500, floor wins
      expect(minimumBidIncrement(19999), 1000);
    });

    test('uses 5% above the floor crossover', () {
      expect(minimumBidIncrement(20000), 1000); // exactly at crossover
      expect(minimumBidIncrement(100000), 5000);
      expect(minimumBidIncrement(1000000), 50000);
    });

    // The single most likely "money looks right but is subtly wrong" bug.
    // 5% as integer division truncates — never rounds.  Mirrors the SQL:
    //   v_min_increment := greatest(1000, (v_current * 5) / 100);
    // If we ever switched to double or to a rounding op, the server would
    // silently disagree with the client about "is this bid valid."
    group('integer truncation matches server', () {
      test('99 IQD * 5 / 100 = 4, not 4.95', () {
        // current 99 → 5% = 4.95 → truncates to 4 → 1000 floor wins.
        expect(minimumBidIncrement(99), 1000);
      });

      test('29 999 IQD → 5% = 1 499 (truncated from 1 499.95)', () {
        expect(minimumBidIncrement(29999), 1499);
      });

      test('100 001 IQD → 5% = 5 000 (truncated from 5 000.05)', () {
        expect(minimumBidIncrement(100001), 5000);
      });

      test('999 999 IQD → 5% = 49 999 (truncated from 49 999.95)', () {
        expect(minimumBidIncrement(999999), 49999);
      });

      test('returns plain int — never double / num', () {
        final r = minimumBidIncrement(123456);
        expect(r, isA<int>());
        expect(r.runtimeType, int);
      });

      test('100 IQD edge: 5 < 1000 floor, so 1000 wins', () {
        // 100 * 5 / 100 = 5; floor is 1000.
        expect(minimumBidIncrement(100), 1000);
      });
    });
  });

  group('calculatePercentageFee', () {
    test('truncates (integer division) — does not round', () {
      expect(calculatePercentageFee(100000, 7), 7000);
      expect(calculatePercentageFee(33333, 7), 2333); // 2333.31 truncated
      expect(calculatePercentageFee(1, 7), 0);
    });
  });

  group('KycTierCeiling — bigint discipline, mirrors SQL helper', () {
    test('Tier 1 ceiling is 100,000 IQD as int', () {
      expect(KycTierCeiling.tier1, 100000);
      expect(KycTierCeiling.tier1, isA<int>());
    });

    test('Tier 0 is zero (browse-only)', () {
      expect(KycTierCeiling.tier0, 0);
      expect(KycTierCeiling.forTier(0), 0);
    });

    test('Tier 2 ceiling is JS-safe max — no practical ceiling', () {
      // 2^53 — the largest int dart2js can represent exactly. Still
      // ~9 quadrillion IQD, far above any realistic auction.
      expect(KycTierCeiling.tier2, 9007199254740992);
    });

    test('forTier dispatches by integer', () {
      expect(KycTierCeiling.forTier(1), 100000);
      expect(KycTierCeiling.forTier(2), KycTierCeiling.tier2);
      expect(KycTierCeiling.forTier(99), 0); // unknown defaults to 0
    });

    test('Tier 1 formats correctly in Turkish (period thousands sep)', () {
      // The single most likely formatting bug — verify on the ceiling too.
      expect(
        formatIQD(KycTierCeiling.tier1, const Locale('tr')),
        '100.000 IQD',
      );
    });
  });
}
