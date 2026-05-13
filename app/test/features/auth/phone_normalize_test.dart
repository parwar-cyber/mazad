import 'package:flutter_test/flutter_test.dart';
import 'package:mazad/features/auth/data/auth_service.dart';

void main() {
  group('normalizeIraqiPhone — accepts the input shapes Iraqis actually use', () {
    test('E.164 with +964 prefix passes through', () {
      expect(normalizeIraqiPhone('+9647712345678'), '+9647712345678');
    });

    test('00964 prefix is normalized to +964', () {
      expect(normalizeIraqiPhone('009647712345678'), '+9647712345678');
    });

    test('Local form 07XX-XXXX-XXX with separators', () {
      expect(normalizeIraqiPhone('0771-234-5678'), '+9647712345678');
      expect(normalizeIraqiPhone('0771 234 5678'), '+9647712345678');
    });

    test('Bare 7XXXXXXXXX (10 digits) is accepted', () {
      expect(normalizeIraqiPhone('7712345678'), '+9647712345678');
    });

    test('Numbers not starting with 7 are rejected (Iraqi mobile constraint)', () {
      expect(normalizeIraqiPhone('+9648712345678'), isNull);
      expect(normalizeIraqiPhone('0812345678'), isNull);
    });

    test('Wrong digit length is rejected', () {
      expect(normalizeIraqiPhone('+96477123456'), isNull);   // too short
      expect(normalizeIraqiPhone('+964771234567890'), isNull); // too long
    });

    test('Empty / non-numeric input is rejected', () {
      expect(normalizeIraqiPhone(''), isNull);
      expect(normalizeIraqiPhone('not a number'), isNull);
    });
  });
}
