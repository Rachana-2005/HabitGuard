import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/core/utils/time_formatter.dart';
import 'package:habitguard/core/utils/validators.dart';

void main() {
  group('TimeFormatter Tests', () {
    test('Formats minutes correctly', () {
      expect(TimeFormatter.formatMinutes(0), equals('0m'));
      expect(TimeFormatter.formatMinutes(45), equals('45m'));
      expect(TimeFormatter.formatMinutes(60), equals('1h'));
      expect(TimeFormatter.formatMinutes(135), equals('2h 15m'));
      expect(TimeFormatter.formatMinutes(342), equals('5h 42m'));
    });

    test('Formats milliseconds correctly', () {
      expect(TimeFormatter.formatMilliseconds(7200000), equals('2h')); // 2h = 7,200,000 ms
      expect(TimeFormatter.formatMilliseconds(2700000), equals('45m')); // 45m
    });

    test('Date key conversion is bidirectional', () {
      final date = DateTime(2026, 8, 14);
      final key = TimeFormatter.formatDateKey(date);
      expect(key, equals('2026-08-14'));
      final parsed = TimeFormatter.parseDateKey(key);
      expect(parsed.year, equals(2026));
      expect(parsed.month, equals(8));
      expect(parsed.day, equals(14));
    });
  });

  group('Validators Tests', () {
    test('Validates Guardian Name correctly', () {
      expect(Validators.validateGuardianName(null), isNotNull);
      expect(Validators.validateGuardianName(''), isNotNull);
      expect(Validators.validateGuardianName('A'), isNotNull); // < 2 chars
      expect(Validators.validateGuardianName('Parent'), isNull);
      expect(Validators.validateGuardianName('Alex Smith'), isNull);
    });

    test('Validates Guardian Mobile Number correctly', () {
      expect(Validators.validateMobileNumber(null), isNotNull);
      expect(Validators.validateMobileNumber(''), isNotNull);
      expect(Validators.validateMobileNumber('123'), isNotNull); // Too short
      expect(Validators.validateMobileNumber('abcd'), isNotNull); // Non-digits

      expect(Validators.validateMobileNumber('9876543210'), isNull);
      expect(Validators.validateMobileNumber('+919876543210'), isNull);
      expect(Validators.validateMobileNumber('+1 (415) 555-2671'), isNull);
      expect(Validators.validateMobileNumber('98765-43210'), isNull);
    });

    test('Normalizes phone numbers with country code prefix', () {
      expect(Validators.normalizePhoneNumber('9876543210', defaultCountryCode: '+91'), equals('+919876543210'));
      expect(Validators.normalizePhoneNumber('+14155552671', defaultCountryCode: '+91'), equals('+14155552671'));
      expect(Validators.normalizePhoneNumber('09876543210', defaultCountryCode: '+91'), equals('+919876543210'));
    });
  });
}
