import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/core/constants/app_constants.dart';
import 'package:habitguard/core/utils/validators.dart';
import 'package:habitguard/models/risk_assessment.dart';

void main() {
  group('Guardian Validation & Alert Logic Tests', () {
    test('Validates phone numbers properly', () {
      expect(Validators.validateMobileNumber('9876543210'), isNull);
      expect(Validators.validateMobileNumber('+919876543210'), isNull);
      expect(Validators.validateMobileNumber('123'), isNotNull);
      expect(Validators.validateMobileNumber('abcdefghij'), isNotNull);
      expect(Validators.validateMobileNumber(''), isNotNull);
    });

    test('Validates guardian name properly', () {
      expect(Validators.validateGuardianName('John Doe'), isNull);
      expect(Validators.validateGuardianName('A'), isNotNull);
      expect(Validators.validateGuardianName(''), isNotNull);
    });

    test('Only risk score >= 61 qualifies for High Risk Guardian Alert', () {
      expect(55 >= AppConstants.riskThresholdHighAlert, isFalse);
      expect(60 >= AppConstants.riskThresholdHighAlert, isFalse);
      expect(61 >= AppConstants.riskThresholdHighAlert, isTrue);
      expect(78 >= AppConstants.riskThresholdHighAlert, isTrue);
      expect(95 >= AppConstants.riskThresholdHighAlert, isTrue);
    });

    test('Risk levels are correctly classified from scores', () {
      expect(RiskLevel.fromScore(25), equals(RiskLevel.low));
      expect(RiskLevel.fromScore(30), equals(RiskLevel.low));
      expect(RiskLevel.fromScore(31), equals(RiskLevel.moderate));
      expect(RiskLevel.fromScore(60), equals(RiskLevel.moderate));
      expect(RiskLevel.fromScore(61), equals(RiskLevel.high));
      expect(RiskLevel.fromScore(80), equals(RiskLevel.high));
      expect(RiskLevel.fromScore(81), equals(RiskLevel.critical));
      expect(RiskLevel.fromScore(100), equals(RiskLevel.critical));
    });
  });
}
