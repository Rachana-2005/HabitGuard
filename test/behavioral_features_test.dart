import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/models/app_category.dart';
import 'package:habitguard/models/application_usage.dart';
import 'package:habitguard/models/daily_usage.dart';
import 'package:habitguard/models/risk_assessment.dart';
import 'package:habitguard/services/feature_service.dart';

void main() {
  group('Behavioral Feature Extraction Tests', () {
    test('Correctly extracts features from DailyUsage with multiple categories', () {
      final apps = [
        const ApplicationUsage(
          packageName: 'com.instagram.android',
          applicationName: 'Instagram',
          category: AppCategory.socialMedia,
          usageMilliseconds: 120 * 60 * 1000, // 120m
        ),
        const ApplicationUsage(
          packageName: 'com.pubg.imobile',
          applicationName: 'BGMI',
          category: AppCategory.gaming,
          usageMilliseconds: 60 * 60 * 1000, // 60m
        ),
        const ApplicationUsage(
          packageName: 'com.google.android.apps.classroom',
          applicationName: 'Google Classroom',
          category: AppCategory.education,
          usageMilliseconds: 45 * 60 * 1000, // 45m
        ),
      ];

      final today = DailyUsage(
        date: '2026-09-10',
        totalScreenTimeMinutes: 225,
        totalScreenTimeMilliseconds: 225 * 60 * 1000,
        socialMediaTime: 120,
        gamingTime: 60,
        entertainmentTime: 0,
        educationTime: 45,
        productivityTime: 0,
        communicationTime: 0,
        otherTime: 0,
        riskScore: 65,
        riskLevel: RiskLevel.high,
        applications: apps,
        createdAt: DateTime.now(),
      );

      final nativeMetrics = {
        'totalSessions': 40,
        'lateNightUsageMillis': 45 * 60 * 1000, // 45 mins late night
        'earlyMorningUsageMillis': 15 * 60 * 1000, // 15 mins early morning
      };

      final features = FeatureService.extractFeatures(
        todayUsage: today,
        nativeBehavioralMetrics: nativeMetrics,
      );

      expect(features.totalScreenTime, equals(225));
      expect(features.socialMediaTime, equals(120));
      expect(features.gamingTime, equals(60));
      expect(features.educationTime, equals(45));
      expect(features.numberOfAppSessions, equals(40));
      expect(features.lateNightUsage, equals(45));
      expect(features.earlyMorningUsage, equals(15));
      expect(features.mostUsedApplication, equals('Instagram'));
      expect(features.mostUsedCategory, equals('SOCIALMEDIA'));

      // Check behavioral percentages
      expect(features.socialMediaPercentage, closeTo((120 / 225) * 100, 0.5));
      expect(features.gamingPercentage, closeTo((60 / 225) * 100, 0.5));
      expect(features.productiveUsagePercentage, closeTo((45 / 225) * 100, 0.5));

      // Test ML payload serialization
      final payload = features.toMlRequest();
      expect(payload['totalScreenTime'], equals(225));
      expect(payload['numberOfSessions'], equals(40));
      expect(payload['lateNightUsage'], equals(45));
      expect(payload.containsKey('socialMediaPercentage'), isTrue);
    });

    test('Handles longitudinal trend correctly with past history', () {
      final pastHistory = [
        DailyUsage.empty(DateTime(2026, 9, 8)),
        DailyUsage(
          date: '2026-09-09',
          totalScreenTimeMinutes: 180,
          totalScreenTimeMilliseconds: 180 * 60 * 1000,
          socialMediaTime: 60,
          gamingTime: 30,
          entertainmentTime: 30,
          educationTime: 30,
          productivityTime: 30,
          communicationTime: 0,
          otherTime: 0,
          riskScore: 40,
          riskLevel: RiskLevel.moderate,
          applications: const [],
          createdAt: DateTime(2026, 9, 9),
        ),
      ];

      final today = DailyUsage(
        date: '2026-09-10',
        totalScreenTimeMinutes: 300, // Surge of +66%
        totalScreenTimeMilliseconds: 300 * 60 * 1000,
        socialMediaTime: 150,
        gamingTime: 60,
        entertainmentTime: 50,
        educationTime: 20,
        productivityTime: 20,
        communicationTime: 0,
        otherTime: 0,
        riskScore: 72,
        riskLevel: RiskLevel.high,
        applications: const [],
        createdAt: DateTime(2026, 9, 10),
      );

      final features = FeatureService.extractFeatures(
        todayUsage: today,
        pastDaysHistory: pastHistory,
      );

      expect(features.dailyUsageChangePercentage, greaterThan(20.0));
      expect(features.sevenDayRiskTrend, equals('INCREASING'));
    });
  });
}
