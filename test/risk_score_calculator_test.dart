import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/core/algorithms/risk_score_calculator.dart';
import 'package:habitguard/models/risk_assessment.dart';
import 'package:habitguard/models/app_category.dart';

void main() {
  group('RiskScoreCalculator Tests', () {
    test('Zero usage should return 0 score and LOW risk', () {
      final assessment = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: 0,
        socialMediaMinutes: 0,
        gamingMinutes: 0,
        entertainmentMinutes: 0,
      );

      expect(assessment.score, equals(0));
      expect(assessment.level, equals(RiskLevel.low));
      expect(assessment.isHighRisk, isFalse);
    });

    test('2 hours screen time (120 min) should yield LOW risk level (<= 30)', () {
      final assessment = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: 120,
        socialMediaMinutes: 20,
        gamingMinutes: 15,
        entertainmentMinutes: 20,
        educationMinutes: 35,
        productivityMinutes: 30,
      );

      expect(assessment.level, equals(RiskLevel.low));
      expect(assessment.score, lessThanOrEqualTo(30));
      expect(assessment.isHighRisk, isFalse);
    });

    test('4 hours screen time (240 min) should yield MODERATE risk level (31 - 60)', () {
      final assessment = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: 240,
        socialMediaMinutes: 60,
        gamingMinutes: 45,
        entertainmentMinutes: 60,
        communicationMinutes: 40,
        otherMinutes: 35,
      );

      expect(assessment.level, equals(RiskLevel.moderate));
      expect(assessment.score, greaterThanOrEqualTo(31));
      expect(assessment.score, lessThanOrEqualTo(60));
      expect(assessment.isHighRisk, isFalse);
    });

    test('6 hours screen time (360 min) should yield HIGH risk level (61 - 80)', () {
      final assessment = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: 360,
        socialMediaMinutes: 140,
        gamingMinutes: 90,
        entertainmentMinutes: 80,
        communicationMinutes: 30,
        otherMinutes: 20,
      );

      expect(assessment.level, equals(RiskLevel.high));
      expect(assessment.score, greaterThanOrEqualTo(61));
      expect(assessment.score, lessThanOrEqualTo(80));
      expect(assessment.isHighRisk, isTrue);
    });

    test('8+ hours screen time (480+ min) with gaming/social should yield CRITICAL risk level (81 - 100)', () {
      final assessment = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: 520,
        socialMediaMinutes: 180,
        gamingMinutes: 160,
        entertainmentMinutes: 120,
        communicationMinutes: 40,
        otherMinutes: 20,
      );

      expect(assessment.level, equals(RiskLevel.critical));
      expect(assessment.score, greaterThanOrEqualTo(81));
      expect(assessment.score, lessThanOrEqualTo(100));
      expect(assessment.isHighRisk, isTrue);
    });

    test('Productive/Educational usage should mitigate risk score', () {
      // 5 hours with purely entertainment vs 5 hours with high education
      final unmitigated = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: 300,
        socialMediaMinutes: 140,
        gamingMinutes: 100,
        entertainmentMinutes: 60,
      );

      final mitigated = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: 300,
        socialMediaMinutes: 30,
        gamingMinutes: 20,
        entertainmentMinutes: 30,
        educationMinutes: 140,
        productivityMinutes: 80,
      );

      expect(mitigated.score, lessThan(unmitigated.score));
    });

    test('Should generate customized recommendations according to top category', () {
      final assessment = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: 280,
        socialMediaMinutes: 160,
        gamingMinutes: 40,
        entertainmentMinutes: 50,
      );

      expect(assessment.topCategory, equals(AppCategory.socialMedia));
      expect(assessment.recommendations, isNotEmpty);
      expect(assessment.recommendations.any((r) => r.toLowerCase().contains('social media')), isTrue);
    });
  });
}
