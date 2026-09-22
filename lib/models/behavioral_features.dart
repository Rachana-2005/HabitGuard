/// Comprehensive behavioral features extracted from smartphone usage data.
/// Passed to the Machine Learning risk prediction model and stored for longitudinal analysis.
class BehavioralFeatures {
  final int totalScreenTime; // in minutes
  final int socialMediaTime;
  final int gamingTime;
  final int entertainmentTime;
  final int educationTime;
  final int productivityTime;
  final int communicationTime;
  final int otherTime;

  final int numberOfAppSessions;
  final double averageSessionDuration; // in minutes

  final int lateNightUsage; // in minutes (11 PM - 5/7 AM)
  final int earlyMorningUsage; // in minutes (5 AM - 7 AM)

  final String mostUsedCategory;
  final String mostUsedApplication;
  final int numberOfFrequentlyOpenedApps;

  final double dailyUsageChangePercentage; // vs previous day or 7-day baseline
  final int previousDayScreenTime;
  final double sevenDayAverageScreenTime;
  final String sevenDayRiskTrend; // "INCREASING", "DECREASING", "STABLE", "INSUFFICIENT_DATA"

  final double socialMediaPercentage;
  final double gamingPercentage;
  final double productiveUsagePercentage;
  final double entertainmentPercentage;

  final int usageAfter11PM;
  final int usageBefore7AM;
  final bool isWeekend;

  const BehavioralFeatures({
    required this.totalScreenTime,
    required this.socialMediaTime,
    required this.gamingTime,
    required this.entertainmentTime,
    required this.educationTime,
    required this.productivityTime,
    required this.communicationTime,
    required this.otherTime,
    required this.numberOfAppSessions,
    required this.averageSessionDuration,
    required this.lateNightUsage,
    required this.earlyMorningUsage,
    required this.mostUsedCategory,
    required this.mostUsedApplication,
    required this.numberOfFrequentlyOpenedApps,
    required this.dailyUsageChangePercentage,
    required this.previousDayScreenTime,
    required this.sevenDayAverageScreenTime,
    required this.sevenDayRiskTrend,
    required this.socialMediaPercentage,
    required this.gamingPercentage,
    required this.productiveUsagePercentage,
    required this.entertainmentPercentage,
    required this.usageAfter11PM,
    required this.usageBefore7AM,
    required this.isWeekend,
  });

  /// Serializes feature vector for Python ML API payload
  Map<String, dynamic> toMlRequest() {
    return {
      'totalScreenTime': totalScreenTime,
      'socialMediaTime': socialMediaTime,
      'gamingTime': gamingTime,
      'entertainmentTime': entertainmentTime,
      'educationTime': educationTime,
      'productivityTime': productivityTime,
      'communicationTime': communicationTime,
      'otherTime': otherTime,
      'numberOfSessions': numberOfAppSessions,
      'averageSessionDuration': double.parse(averageSessionDuration.toStringAsFixed(1)),
      'lateNightUsage': lateNightUsage,
      'earlyMorningUsage': earlyMorningUsage,
      'sevenDayAverage': double.parse(sevenDayAverageScreenTime.toStringAsFixed(1)),
      'usageChangePercentage': double.parse(dailyUsageChangePercentage.toStringAsFixed(1)),
      'socialMediaPercentage': double.parse(socialMediaPercentage.toStringAsFixed(1)),
      'gamingPercentage': double.parse(gamingPercentage.toStringAsFixed(1)),
      'productivePercentage': double.parse(productiveUsagePercentage.toStringAsFixed(1)),
      'entertainmentPercentage': double.parse(entertainmentPercentage.toStringAsFixed(1)),
      'isWeekend': isWeekend ? 1 : 0,
    };
  }

  /// Serializes to Firestore `users/{uid}/behaviorFeatures/{date}`
  Map<String, dynamic> toFirestore() {
    return {
      'totalScreenTime': totalScreenTime,
      'socialMediaTime': socialMediaTime,
      'gamingTime': gamingTime,
      'entertainmentTime': entertainmentTime,
      'educationTime': educationTime,
      'productivityTime': productivityTime,
      'communicationTime': communicationTime,
      'otherTime': otherTime,
      'socialMediaPercentage': socialMediaPercentage,
      'gamingPercentage': gamingPercentage,
      'productivePercentage': productiveUsagePercentage,
      'entertainmentPercentage': entertainmentPercentage,
      'lateNightUsage': lateNightUsage,
      'earlyMorningUsage': earlyMorningUsage,
      'sessionCount': numberOfAppSessions,
      'averageSessionDuration': averageSessionDuration,
      'sevenDayAverage': sevenDayAverageScreenTime,
      'usageChangePercentage': dailyUsageChangePercentage,
      'mostUsedCategory': mostUsedCategory,
      'mostUsedApplication': mostUsedApplication,
      'sevenDayRiskTrend': sevenDayRiskTrend,
      'isWeekend': isWeekend,
      'recordedAt': DateTime.now().toIso8601String(),
    };
  }

  factory BehavioralFeatures.fromMap(Map<String, dynamic> map) {
    return BehavioralFeatures(
      totalScreenTime: (map['totalScreenTime'] as num?)?.toInt() ?? 0,
      socialMediaTime: (map['socialMediaTime'] as num?)?.toInt() ?? 0,
      gamingTime: (map['gamingTime'] as num?)?.toInt() ?? 0,
      entertainmentTime: (map['entertainmentTime'] as num?)?.toInt() ?? 0,
      educationTime: (map['educationTime'] as num?)?.toInt() ?? 0,
      productivityTime: (map['productivityTime'] as num?)?.toInt() ?? 0,
      communicationTime: (map['communicationTime'] as num?)?.toInt() ?? 0,
      otherTime: (map['otherTime'] as num?)?.toInt() ?? 0,
      numberOfAppSessions: (map['sessionCount'] ?? map['numberOfSessions'] as num?)?.toInt() ?? 0,
      averageSessionDuration: (map['averageSessionDuration'] as num?)?.toDouble() ?? 0.0,
      lateNightUsage: (map['lateNightUsage'] as num?)?.toInt() ?? 0,
      earlyMorningUsage: (map['earlyMorningUsage'] as num?)?.toInt() ?? 0,
      mostUsedCategory: map['mostUsedCategory'] as String? ?? 'OTHER',
      mostUsedApplication: map['mostUsedApplication'] as String? ?? 'Unknown',
      numberOfFrequentlyOpenedApps: (map['numberOfFrequentlyOpenedApps'] as num?)?.toInt() ?? 0,
      dailyUsageChangePercentage: (map['usageChangePercentage'] as num?)?.toDouble() ?? 0.0,
      previousDayScreenTime: (map['previousDayScreenTime'] as num?)?.toInt() ?? 0,
      sevenDayAverageScreenTime: (map['sevenDayAverage'] as num?)?.toDouble() ?? 0.0,
      sevenDayRiskTrend: map['sevenDayRiskTrend'] as String? ?? 'STABLE',
      socialMediaPercentage: (map['socialMediaPercentage'] as num?)?.toDouble() ?? 0.0,
      gamingPercentage: (map['gamingPercentage'] as num?)?.toDouble() ?? 0.0,
      productiveUsagePercentage: (map['productivePercentage'] as num?)?.toDouble() ?? 0.0,
      entertainmentPercentage: (map['entertainmentPercentage'] as num?)?.toDouble() ?? 0.0,
      usageAfter11PM: (map['lateNightUsage'] as num?)?.toInt() ?? 0,
      usageBefore7AM: (map['earlyMorningUsage'] as num?)?.toInt() ?? 0,
      isWeekend: map['isWeekend'] == true || map['isWeekend'] == 1,
    );
  }

  factory BehavioralFeatures.empty() {
    return const BehavioralFeatures(
      totalScreenTime: 0,
      socialMediaTime: 0,
      gamingTime: 0,
      entertainmentTime: 0,
      educationTime: 0,
      productivityTime: 0,
      communicationTime: 0,
      otherTime: 0,
      numberOfAppSessions: 0,
      averageSessionDuration: 0.0,
      lateNightUsage: 0,
      earlyMorningUsage: 0,
      mostUsedCategory: 'NONE',
      mostUsedApplication: 'None',
      numberOfFrequentlyOpenedApps: 0,
      dailyUsageChangePercentage: 0.0,
      previousDayScreenTime: 0,
      sevenDayAverageScreenTime: 0.0,
      sevenDayRiskTrend: 'INSUFFICIENT_DATA',
      socialMediaPercentage: 0.0,
      gamingPercentage: 0.0,
      productiveUsagePercentage: 0.0,
      entertainmentPercentage: 0.0,
      usageAfter11PM: 0,
      usageBefore7AM: 0,
      isWeekend: false,
    );
  }
}
