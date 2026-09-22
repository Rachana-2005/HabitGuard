import 'app_category.dart';
import 'application_usage.dart';
import 'risk_assessment.dart';
import '../core/utils/time_formatter.dart';

/// Aggregated usage statistics for a single calendar day
class DailyUsage {
  final String date; // "yyyy-MM-dd"
  final int totalScreenTimeMinutes;
  final int totalScreenTimeMilliseconds;
  final int socialMediaTime; // in minutes
  final int gamingTime;
  final int entertainmentTime;
  final int educationTime;
  final int productivityTime;
  final int communicationTime;
  final int otherTime;
  final int riskScore;
  final RiskLevel riskLevel;
  final List<ApplicationUsage> applications;
  final DateTime createdAt;

  const DailyUsage({
    required this.date,
    required this.totalScreenTimeMinutes,
    required this.totalScreenTimeMilliseconds,
    required this.socialMediaTime,
    required this.gamingTime,
    required this.entertainmentTime,
    required this.educationTime,
    required this.productivityTime,
    required this.communicationTime,
    required this.otherTime,
    required this.riskScore,
    required this.riskLevel,
    required this.applications,
    required this.createdAt,
  });

  /// Formatted total screen time e.g. "5h 42m"
  String get formattedTotalTime => TimeFormatter.formatMinutes(totalScreenTimeMinutes);

  /// Map of category to minutes
  Map<AppCategory, int> get categoryBreakdown => {
        AppCategory.socialMedia: socialMediaTime,
        AppCategory.gaming: gamingTime,
        AppCategory.entertainment: entertainmentTime,
        AppCategory.education: educationTime,
        AppCategory.productivity: productivityTime,
        AppCategory.communication: communicationTime,
        AppCategory.other: otherTime,
      };

  /// Top most used applications (limit defaults to 5)
  List<ApplicationUsage> getTopApplications([int limit = 5]) {
    final sorted = List<ApplicationUsage>.from(applications)
      ..sort((a, b) => b.usageMilliseconds.compareTo(a.usageMilliseconds));
    return sorted.take(limit).toList();
  }

  /// Empty initial state for a day
  factory DailyUsage.empty(DateTime dateTime) {
    return DailyUsage(
      date: TimeFormatter.formatDateKey(dateTime),
      totalScreenTimeMinutes: 0,
      totalScreenTimeMilliseconds: 0,
      socialMediaTime: 0,
      gamingTime: 0,
      entertainmentTime: 0,
      educationTime: 0,
      productivityTime: 0,
      communicationTime: 0,
      otherTime: 0,
      riskScore: 0,
      riskLevel: RiskLevel.low,
      applications: const [],
      createdAt: dateTime,
    );
  }

  /// Converts model to Firestore Map
  Map<String, dynamic> toMap() {
    return {
      'date': date,
      'totalScreenTime': totalScreenTimeMinutes,
      'totalScreenTimeMs': totalScreenTimeMilliseconds,
      'socialMediaTime': socialMediaTime,
      'gamingTime': gamingTime,
      'entertainmentTime': entertainmentTime,
      'educationTime': educationTime,
      'productivityTime': productivityTime,
      'communicationTime': communicationTime,
      'otherTime': otherTime,
      'riskScore': riskScore,
      'riskLevel': riskLevel.label,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  /// Factory constructor from Firestore Map
  factory DailyUsage.fromMap(Map<String, dynamic> map, {List<ApplicationUsage> apps = const []}) {
    final totalMins = (map['totalScreenTime'] as num?)?.toInt() ?? 0;
    final totalMs = (map['totalScreenTimeMs'] as num?)?.toInt() ?? (totalMins * 60000);
    final score = (map['riskScore'] as num?)?.toInt() ?? 0;

    return DailyUsage(
      date: map['date'] as String? ?? '',
      totalScreenTimeMinutes: totalMins,
      totalScreenTimeMilliseconds: totalMs,
      socialMediaTime: (map['socialMediaTime'] as num?)?.toInt() ?? 0,
      gamingTime: (map['gamingTime'] as num?)?.toInt() ?? 0,
      entertainmentTime: (map['entertainmentTime'] as num?)?.toInt() ?? 0,
      educationTime: (map['educationTime'] as num?)?.toInt() ?? 0,
      productivityTime: (map['productivityTime'] as num?)?.toInt() ?? 0,
      communicationTime: (map['communicationTime'] as num?)?.toInt() ?? 0,
      otherTime: (map['otherTime'] as num?)?.toInt() ?? 0,
      riskScore: score,
      riskLevel: RiskLevel.fromString(map['riskLevel'] as String?),
      applications: apps,
      createdAt: map['createdAt'] != null
          ? DateTime.tryParse(map['createdAt'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
