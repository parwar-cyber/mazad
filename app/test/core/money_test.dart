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

    test('Kurdish (Sorani) uses Arabic-script numeric grouping, "IQD" suffix', () {
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
  });

  group('calculatePercentageFee', () {
    test('truncates (integer division) — does not round', () {
      expect(calculatePercentageFee(100000, 7), 7000);
      expect(calculatePercentageFee(33333, 7), 2333); // 2333.31 truncated
      expect(calculatePercentageFee(1, 7), 0);
    });
  });
}
