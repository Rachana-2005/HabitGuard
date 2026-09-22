import 'app_category.dart';
import '../core/utils/time_formatter.dart';

/// Represents individual application foreground usage statistics
class ApplicationUsage {
  final String packageName;
  final String applicationName;
  final AppCategory category;
  final int usageMilliseconds;
  final double percentageOfTotal;

  const ApplicationUsage({
    required this.packageName,
    required this.applicationName,
    required this.category,
    required this.usageMilliseconds,
    this.percentageOfTotal = 0.0,
  });

  /// Computed duration in full minutes
  int get usageMinutes => (usageMilliseconds / 60000).round();

  /// Formatted duration string e.g. "2h 15m"
  String get formattedDuration => TimeFormatter.formatMilliseconds(usageMilliseconds);

  /// Creates a copy with updated attributes (such as computed percentage)
  ApplicationUsage copyWith({
    String? packageName,
    String? applicationName,
    AppCategory? category,
    int? usageMilliseconds,
    double? percentageOfTotal,
  }) {
    return ApplicationUsage(
      packageName: packageName ?? this.packageName,
      applicationName: applicationName ?? this.applicationName,
      category: category ?? this.category,
      usageMilliseconds: usageMilliseconds ?? this.usageMilliseconds,
      percentageOfTotal: percentageOfTotal ?? this.percentageOfTotal,
    );
  }

  /// Converts model to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'packageName': packageName,
      'applicationName': applicationName,
      'category': category.toJson(),
      'usageMilliseconds': usageMilliseconds,
      'usageMinutes': usageMinutes,
    };
  }

  /// Factory constructor from Map
  factory ApplicationUsage.fromMap(Map<String, dynamic> map) {
    return ApplicationUsage(
      packageName: map['packageName'] as String? ?? '',
      applicationName: map['applicationName'] as String? ?? 'Unknown Application',
      category: AppCategory.fromJson(map['category'] as String?),
      usageMilliseconds: (map['usageMilliseconds'] as num?)?.toInt() ?? 0,
      percentageOfTotal: (map['percentageOfTotal'] as num?)?.toDouble() ?? 0.0,
    );
  }

  @override
  String toString() =>
      'ApplicationUsage($applicationName, $category, ${usageMinutes}m, ${(percentageOfTotal * 100).toStringAsFixed(1)}%)';
}
