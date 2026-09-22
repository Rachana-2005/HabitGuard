import 'package:flutter_test/flutter_test.dart';
import 'package:habitguard/models/app_category.dart';
import 'package:habitguard/models/application_usage.dart';
import 'package:habitguard/models/daily_usage.dart';
import 'package:habitguard/models/risk_assessment.dart';

void main() {
  group('Usage Processing Tests', () {
    test('ApplicationUsage computes minutes and formats correctly', () {
      const app = ApplicationUsage(
        packageName: 'com.google.android.youtube',
        applicationName: 'YouTube',
        category: AppCategory.entertainment,
        usageMilliseconds: 7200000, // 120 minutes = 2 hours
        percentageOfTotal: 0.50,
      );

      expect(app.usageMinutes, equals(120));
      expect(app.formattedDuration, equals('2h'));
      expect(app.percentageOfTotal, equals(0.50));
    });

    test('DailyUsage correctly identifies top applications in descending order', () {
      final apps = [
        const ApplicationUsage(
          packageName: 'com.whatsapp',
          applicationName: 'WhatsApp',
          category: AppCategory.communication,
          usageMilliseconds: 1800000, // 30m
        ),
        const ApplicationUsage(
          packageName: 'com.google.android.youtube',
          applicationName: 'YouTube',
          category: AppCategory.entertainment,
          usageMilliseconds: 7200000, // 120m
        ),
        const ApplicationUsage(
          packageName: 'com.instagram.android',
          applicationName: 'Instagram',
          category: AppCategory.socialMedia,
          usageMilliseconds: 5400000, // 90m
        ),
        const ApplicationUsage(
          packageName: 'com.pubg.imobile',
          applicationName: 'BGMI',
          category: AppCategory.gaming,
          usageMilliseconds: 3600000, // 60m
        ),
      ];

      final daily = DailyUsage(
        date: '2026-08-14',
        totalScreenTimeMinutes: 300,
        totalScreenTimeMilliseconds: 300 * 60000,
        socialMediaTime: 90,
        gamingTime: 60,
        entertainmentTime: 120,
        educationTime: 0,
        productivityTime: 0,
        communicationTime: 30,
        otherTime: 0,
        riskScore: 68,
        riskLevel: RiskLevel.high,
        applications: apps,
        createdAt: DateTime.now(),
      );

      final top3 = daily.getTopApplications(3);
      expect(top3.length, equals(3));
      expect(top3[0].applicationName, equals('YouTube')); // 120m
      expect(top3[1].applicationName, equals('Instagram')); // 90m
      expect(top3[2].applicationName, equals('BGMI')); // 60m
    });

    test('DailyUsage serialization to and from Map is consistent', () {
      final now = DateTime(2026, 8, 14, 12, 0);
      final daily = DailyUsage(
        date: '2026-08-14',
        totalScreenTimeMinutes: 240,
        totalScreenTimeMilliseconds: 240 * 60000,
        socialMediaTime: 80,
        gamingTime: 50,
        entertainmentTime: 60,
        educationTime: 20,
        productivityTime: 20,
        communicationTime: 10,
        otherTime: 0,
        riskScore: 52,
        riskLevel: RiskLevel.moderate,
        applications: const [],
        createdAt: now,
      );

      final map = daily.toMap();
      final reconstructed = DailyUsage.fromMap(map);

      expect(reconstructed.date, equals(daily.date));
      expect(reconstructed.totalScreenTimeMinutes, equals(daily.totalScreenTimeMinutes));
      expect(reconstructed.socialMediaTime, equals(daily.socialMediaTime));
      expect(reconstructed.riskScore, equals(daily.riskScore));
      expect(reconstructed.riskLevel, equals(daily.riskLevel));
    });
  });
}
