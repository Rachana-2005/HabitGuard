import '../models/application_usage.dart';
import '../models/behavioral_features.dart';
import '../models/daily_usage.dart';

/// Behavioral Feature Extraction Engine.
/// Transforms raw Android screen-time and session data into structured feature vectors for Machine Learning.
class FeatureService {
  /// Extracts multi-dimensional behavioral features for a given day and historical records
  static BehavioralFeatures extractFeatures({
    required DailyUsage todayUsage,
    List<DailyUsage> pastDaysHistory = const [],
    Map<String, dynamic>? nativeBehavioralMetrics,
  }) {
    final totalMins = todayUsage.totalScreenTimeMinutes;
    if (totalMins <= 0 && todayUsage.applications.isEmpty) {
      return BehavioralFeatures.empty();
    }

    // 1. Category Times
    final socialMins = todayUsage.socialMediaTime;
    final gamingMins = todayUsage.gamingTime;
    final entertainmentMins = todayUsage.entertainmentTime;
    final educationMins = todayUsage.educationTime;
    final productivityMins = todayUsage.productivityTime;
    final communicationMins = todayUsage.communicationTime;
    final otherMins = todayUsage.otherTime;

    // 2. Session Metrics
    int totalSessions = 0;
    if (nativeBehavioralMetrics != null && nativeBehavioralMetrics.containsKey('totalSessions')) {
      totalSessions = (nativeBehavioralMetrics['totalSessions'] as num?)?.toInt() ?? 0;
    }
    if (totalSessions <= 0) {
      totalSessions = todayUsage.applications.length;
    }
    if (totalSessions <= 0) {
      totalSessions = totalMins > 0 ? (totalMins / 15).ceil().clamp(1, 150) : 0;
    }

    final double avgSessionDuration = totalSessions > 0 ? (totalMins / totalSessions) : 0.0;

    // 3. Late-Night & Early-Morning Usage (in minutes)
    int lateNightMinutes = 0;
    int earlyMorningMinutes = 0;
    if (nativeBehavioralMetrics != null) {
      final lateMs = (nativeBehavioralMetrics['lateNightUsageMillis'] as num?)?.toInt() ?? 0;
      final earlyMs = (nativeBehavioralMetrics['earlyMorningUsageMillis'] as num?)?.toInt() ?? 0;
      lateNightMinutes = (lateMs / 60000).round();
      earlyMorningMinutes = (earlyMs / 60000).round();
    }

    // 4. Most Used Category & App
    String mostUsedCategoryName = 'OTHER';
    int maxCategoryMins = -1;
    for (final entry in todayUsage.categoryBreakdown.entries) {
      if (entry.value > maxCategoryMins) {
        maxCategoryMins = entry.value;
        mostUsedCategoryName = entry.key.name.toUpperCase();
      }
    }

    String topAppName = 'None';
    if (todayUsage.applications.isNotEmpty) {
      final sortedApps = List<ApplicationUsage>.from(todayUsage.applications)
        ..sort((a, b) => b.usageMilliseconds.compareTo(a.usageMilliseconds));
      topAppName = sortedApps.first.applicationName;
    }

    // Frequently opened apps (apps used in multiple sessions)
    final frequentlyOpenedApps = todayUsage.applications.where((a) => a.usageMinutes >= 15).length;

    // 5. Historical Longitudinal Comparisons
    int prevDayMins = 0;
    double sevenDayAvg = totalMins.toDouble();
    double changePct = 0.0;
    String trend = 'INSUFFICIENT_DATA';

    if (pastDaysHistory.isNotEmpty) {
      // Find previous day
      final validPastDays = pastDaysHistory.where((d) => d.date != todayUsage.date).toList();
      if (validPastDays.isNotEmpty) {
        prevDayMins = validPastDays.first.totalScreenTimeMinutes;

        int sumPastMins = totalMins;
        int count = 1;
        for (final past in validPastDays.take(6)) {
          sumPastMins += past.totalScreenTimeMinutes;
          count++;
        }
        sevenDayAvg = sumPastMins / count;

        if (prevDayMins > 0) {
          changePct = ((totalMins - prevDayMins) / prevDayMins) * 100.0;
        } else if (totalMins > 0) {
          changePct = 100.0;
        }

        // Trend calculation
        if (count >= 2) {
          final diffFromAvg = totalMins - sevenDayAvg;
          if (diffFromAvg > (sevenDayAvg * 0.10)) {
            trend = 'INCREASING';
          } else if (diffFromAvg < -(sevenDayAvg * 0.10)) {
            trend = 'DECREASING';
          } else {
            trend = 'STABLE';
          }
        }
      }
    }

    // 6. Behavioral Percentages
    final double safeTotal = totalMins > 0 ? totalMins.toDouble() : 1.0;
    final double socialPct = (socialMins / safeTotal) * 100.0;
    final double gamingPct = (gamingMins / safeTotal) * 100.0;
    final double entertainmentPct = (entertainmentMins / safeTotal) * 100.0;
    final double productivePct = ((educationMins + productivityMins) / safeTotal) * 100.0;

    final now = DateTime.now();
    final isWeekend = now.weekday == DateTime.saturday || now.weekday == DateTime.sunday;

    return BehavioralFeatures(
      totalScreenTime: totalMins,
      socialMediaTime: socialMins,
      gamingTime: gamingMins,
      entertainmentTime: entertainmentMins,
      educationTime: educationMins,
      productivityTime: productivityMins,
      communicationTime: communicationMins,
      otherTime: otherMins,
      numberOfAppSessions: totalSessions,
      averageSessionDuration: avgSessionDuration,
      lateNightUsage: lateNightMinutes,
      earlyMorningUsage: earlyMorningMinutes,
      mostUsedCategory: mostUsedCategoryName,
      mostUsedApplication: topAppName,
      numberOfFrequentlyOpenedApps: frequentlyOpenedApps,
      dailyUsageChangePercentage: changePct,
      previousDayScreenTime: prevDayMins,
      sevenDayAverageScreenTime: sevenDayAvg,
      sevenDayRiskTrend: trend,
      socialMediaPercentage: socialPct,
      gamingPercentage: gamingPct,
      productiveUsagePercentage: productivePct,
      entertainmentPercentage: entertainmentPct,
      usageAfter11PM: lateNightMinutes,
      usageBefore7AM: earlyMorningMinutes,
      isWeekend: isWeekend,
    );
  }
}
