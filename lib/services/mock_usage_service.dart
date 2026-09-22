import 'dart:math';
import '../models/app_category.dart';
import '../models/application_usage.dart';
import '../models/daily_usage.dart';
import '../core/algorithms/risk_score_calculator.dart';
import '../core/utils/time_formatter.dart';

/// Predefined Mock Risk Scenarios for Developer Testing
enum MockRiskPreset {
  low,
  moderate,
  high,
  critical;

  String get title {
    switch (this) {
      case MockRiskPreset.low:
        return 'Low Risk (~1h 45m)';
      case MockRiskPreset.moderate:
        return 'Moderate Risk (~3h 45m)';
      case MockRiskPreset.high:
        return 'High Risk (~5h 50m - Triggers Alert)';
      case MockRiskPreset.critical:
        return 'Critical Risk (~8h 30m - Heavy Alert)';
    }
  }
}

/// Provides simulated usage statistics for development and cross-platform testing
class MockUsageService {
  static MockRiskPreset currentPreset = MockRiskPreset.high;

  /// Returns simulated today application usage according to current preset
  static List<ApplicationUsage> getMockTodayUsage({MockRiskPreset? preset}) {
    final activePreset = preset ?? currentPreset;
    switch (activePreset) {
      case MockRiskPreset.low:
        return [
          const ApplicationUsage(
            packageName: 'com.duolingo',
            applicationName: 'Duolingo',
            category: AppCategory.education,
            usageMilliseconds: 45 * 60 * 1000, // 45m
          ),
          const ApplicationUsage(
            packageName: 'com.google.android.keep',
            applicationName: 'Google Keep',
            category: AppCategory.productivity,
            usageMilliseconds: 25 * 60 * 1000, // 25m
          ),
          const ApplicationUsage(
            packageName: 'com.whatsapp',
            applicationName: 'WhatsApp',
            category: AppCategory.communication,
            usageMilliseconds: 20 * 60 * 1000, // 20m
          ),
          const ApplicationUsage(
            packageName: 'com.chess',
            applicationName: 'Chess.com',
            category: AppCategory.gaming,
            usageMilliseconds: 15 * 60 * 1000, // 15m
          ),
        ];

      case MockRiskPreset.moderate:
        return [
          const ApplicationUsage(
            packageName: 'com.google.android.youtube',
            applicationName: 'YouTube',
            category: AppCategory.entertainment,
            usageMilliseconds: 75 * 60 * 1000, // 1h 15m
          ),
          const ApplicationUsage(
            packageName: 'com.instagram.android',
            applicationName: 'Instagram',
            category: AppCategory.socialMedia,
            usageMilliseconds: 65 * 60 * 1000, // 1h 05m
          ),
          const ApplicationUsage(
            packageName: 'com.whatsapp',
            applicationName: 'WhatsApp',
            category: AppCategory.communication,
            usageMilliseconds: 40 * 60 * 1000, // 40m
          ),
          const ApplicationUsage(
            packageName: 'com.Slack',
            applicationName: 'Slack',
            category: AppCategory.productivity,
            usageMilliseconds: 30 * 60 * 1000, // 30m
          ),
          const ApplicationUsage(
            packageName: 'com.amazon.mShop.android.shopping',
            applicationName: 'Amazon',
            category: AppCategory.shopping,
            usageMilliseconds: 15 * 60 * 1000, // 15m
          ),
        ];

      case MockRiskPreset.high:
        return [
          const ApplicationUsage(
            packageName: 'com.instagram.android',
            applicationName: 'Instagram',
            category: AppCategory.socialMedia,
            usageMilliseconds: 140 * 60 * 1000, // 2h 20m
          ),
          const ApplicationUsage(
            packageName: 'com.google.android.youtube',
            applicationName: 'YouTube',
            category: AppCategory.entertainment,
            usageMilliseconds: 95 * 60 * 1000, // 1h 35m
          ),
          const ApplicationUsage(
            packageName: 'com.pubg.imobile',
            applicationName: 'BGMI',
            category: AppCategory.gaming,
            usageMilliseconds: 75 * 60 * 1000, // 1h 15m
          ),
          const ApplicationUsage(
            packageName: 'com.snapchat.android',
            applicationName: 'Snapchat',
            category: AppCategory.socialMedia,
            usageMilliseconds: 30 * 60 * 1000, // 30m
          ),
          const ApplicationUsage(
            packageName: 'com.whatsapp',
            applicationName: 'WhatsApp',
            category: AppCategory.communication,
            usageMilliseconds: 15 * 60 * 1000, // 15m
          ),
        ];

      case MockRiskPreset.critical:
        return [
          const ApplicationUsage(
            packageName: 'com.pubg.imobile',
            applicationName: 'BGMI',
            category: AppCategory.gaming,
            usageMilliseconds: 210 * 60 * 1000, // 3h 30m
          ),
          const ApplicationUsage(
            packageName: 'com.instagram.android',
            applicationName: 'Instagram',
            category: AppCategory.socialMedia,
            usageMilliseconds: 160 * 60 * 1000, // 2h 40m
          ),
          const ApplicationUsage(
            packageName: 'com.google.android.youtube',
            applicationName: 'YouTube',
            category: AppCategory.entertainment,
            usageMilliseconds: 90 * 60 * 1000, // 1h 30m
          ),
          const ApplicationUsage(
            packageName: 'com.dts.freefiremax',
            applicationName: 'Free Fire MAX',
            category: AppCategory.gaming,
            usageMilliseconds: 40 * 60 * 1000, // 40m
          ),
          const ApplicationUsage(
            packageName: 'com.netflix.mediaclient',
            applicationName: 'Netflix',
            category: AppCategory.entertainment,
            usageMilliseconds: 20 * 60 * 1000, // 20m
          ),
        ];
    }
  }

  /// Generates simulated 30-day historical data for charts and history screen
  static List<DailyUsage> getMockHistoryList({int daysCount = 30}) {
    final List<DailyUsage> history = [];
    final random = Random(42); // Seeded for deterministic beautiful trend
    final now = DateTime.now();

    for (int i = 1; i <= daysCount; i++) {
      final date = now.subtract(Duration(days: i));
      // Generate varying screen time between 100 mins and 420 mins
      final int totalMins = 120 + random.nextInt(280);
      final int socialMins = (totalMins * (0.2 + random.nextDouble() * 0.25)).round();
      final int gamingMins = (totalMins * (0.1 + random.nextDouble() * 0.20)).round();
      final int entMins = (totalMins * (0.15 + random.nextDouble() * 0.15)).round();
      final int eduMins = (totalMins * (0.05 + random.nextDouble() * 0.15)).round();
      final int prodMins = (totalMins * (0.05 + random.nextDouble() * 0.10)).round();
      final int commMins = (totalMins * (0.05 + random.nextDouble() * 0.10)).round();
      final int otherMins = max(0, totalMins - (socialMins + gamingMins + entMins + eduMins + prodMins + commMins));

      final assessment = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: totalMins,
        socialMediaMinutes: socialMins,
        gamingMinutes: gamingMins,
        entertainmentMinutes: entMins,
        educationMinutes: eduMins,
        productivityMinutes: prodMins,
        communicationMinutes: commMins,
        otherMinutes: otherMins,
        date: date,
      );

      final daily = DailyUsage(
        date: TimeFormatter.formatDateKey(date),
        totalScreenTimeMinutes: totalMins,
        totalScreenTimeMilliseconds: totalMins * 60000,
        socialMediaTime: socialMins,
        gamingTime: gamingMins,
        entertainmentTime: entMins,
        educationTime: eduMins,
        productivityTime: prodMins,
        communicationTime: commMins,
        otherTime: otherMins,
        riskScore: assessment.score,
        riskLevel: assessment.level,
        applications: [
          ApplicationUsage(
            packageName: 'com.instagram.android',
            applicationName: 'Instagram',
            category: AppCategory.socialMedia,
            usageMilliseconds: socialMins * 60000,
          ),
          ApplicationUsage(
            packageName: 'com.google.android.youtube',
            applicationName: 'YouTube',
            category: AppCategory.entertainment,
            usageMilliseconds: entMins * 60000,
          ),
          ApplicationUsage(
            packageName: 'com.pubg.imobile',
            applicationName: 'BGMI',
            category: AppCategory.gaming,
            usageMilliseconds: gamingMins * 60000,
          ),
        ],
        createdAt: date,
      );

      history.add(daily);
    }

    return history;
  }
}
