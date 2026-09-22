import 'package:flutter/material.dart';
import 'app_category.dart';
import '../core/theme/app_theme.dart';

/// Digital Addiction Risk Level Classifications
enum RiskLevel {
  low,
  moderate,
  high,
  critical;

  String get label {
    switch (this) {
      case RiskLevel.low:
        return 'LOW';
      case RiskLevel.moderate:
        return 'MODERATE';
      case RiskLevel.high:
        return 'HIGH';
      case RiskLevel.critical:
        return 'CRITICAL';
    }
  }

  String get fullLabel {
    switch (this) {
      case RiskLevel.low:
        return 'LOW RISK';
      case RiskLevel.moderate:
        return 'MODERATE RISK';
      case RiskLevel.high:
        return 'HIGH RISK';
      case RiskLevel.critical:
        return 'CRITICAL RISK';
    }
  }

  String get summary {
    switch (this) {
      case RiskLevel.low:
        return 'Your digital usage is balanced and healthy. Keep up the good habits!';
      case RiskLevel.moderate:
        return 'Moderate screen time detected. Be mindful of continuous scrolling sessions.';
      case RiskLevel.high:
        return 'High digital consumption detected. Significant time spent on dopamine-heavy apps.';
      case RiskLevel.critical:
        return 'Critical addiction risk! Screen time is heavily impacting daily wellbeing.';
    }
  }

  Color get color {
    switch (this) {
      case RiskLevel.low:
        return RiskColors.low;
      case RiskLevel.moderate:
        return RiskColors.moderate;
      case RiskLevel.high:
        return RiskColors.high;
      case RiskLevel.critical:
        return RiskColors.critical;
    }
  }

  Color get lightColor {
    switch (this) {
      case RiskLevel.low:
        return RiskColors.lowLight;
      case RiskLevel.moderate:
        return RiskColors.moderateLight;
      case RiskLevel.high:
        return RiskColors.highLight;
      case RiskLevel.critical:
        return RiskColors.criticalLight;
    }
  }

  static RiskLevel fromScore(int score) {
    if (score <= 30) return RiskLevel.low;
    if (score <= 60) return RiskLevel.moderate;
    if (score <= 80) return RiskLevel.high;
    return RiskLevel.critical;
  }

  static RiskLevel fromString(String? level) {
    if (level == null) return RiskLevel.low;
    return RiskLevel.values.firstWhere(
      (e) => e.name.toLowerCase() == level.toLowerCase() ||
             e.label.toLowerCase() == level.toLowerCase(),
      orElse: () => RiskLevel.low,
    );
  }
}

/// Computed risk evaluation for a given day
class RiskAssessment {
  final int score; // 0 to 100
  final RiskLevel level;
  final AppCategory topCategory;
  final Map<AppCategory, int> categoryMinutes;
  final List<String> recommendations;
  final DateTime assessmentDate;

  const RiskAssessment({
    required this.score,
    required this.level,
    required this.topCategory,
    required this.categoryMinutes,
    required this.recommendations,
    required this.assessmentDate,
  });

  /// Indicates if risk crosses the alert threshold (>= 61)
  bool get isHighRisk => score >= 61;

  /// Creates a default empty assessment
  factory RiskAssessment.zero({DateTime? date}) {
    return RiskAssessment(
      score: 0,
      level: RiskLevel.low,
      topCategory: AppCategory.other,
      categoryMinutes: const {},
      recommendations: const ['No smartphone usage detected today yet.'],
      assessmentDate: date ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'score': score,
      'level': level.label,
      'topCategory': topCategory.toJson(),
      'categoryMinutes': categoryMinutes.map((k, v) => MapEntry(k.name, v)),
      'recommendations': recommendations,
      'assessmentDate': assessmentDate.toIso8601String(),
    };
  }

  factory RiskAssessment.fromMap(Map<String, dynamic> map) {
    final score = (map['score'] as num?)?.toInt() ?? 0;
    final catMinutesMap = <AppCategory, int>{};
    if (map['categoryMinutes'] is Map) {
      (map['categoryMinutes'] as Map).forEach((k, v) {
        final cat = AppCategory.fromJson(k.toString());
        catMinutesMap[cat] = (v as num?)?.toInt() ?? 0;
      });
    }

    return RiskAssessment(
      score: score,
      level: RiskLevel.fromString(map['level'] as String?),
      topCategory: AppCategory.fromJson(map['topCategory'] as String?),
      categoryMinutes: catMinutesMap,
      recommendations: (map['recommendations'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      assessmentDate: map['assessmentDate'] != null
          ? DateTime.tryParse(map['assessmentDate'].toString()) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}
