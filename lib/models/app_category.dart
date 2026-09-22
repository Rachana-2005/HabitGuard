import 'package:flutter/material.dart';
import '../core/theme/app_theme.dart';

/// Supported application categories for screen time analysis
enum AppCategory {
  socialMedia,
  gaming,
  entertainment,
  education,
  productivity,
  communication,
  shopping,
  other;

  /// Human-readable category title
  String get displayName {
    switch (this) {
      case AppCategory.socialMedia:
        return 'Social Media';
      case AppCategory.gaming:
        return 'Gaming';
      case AppCategory.entertainment:
        return 'Entertainment';
      case AppCategory.education:
        return 'Education';
      case AppCategory.productivity:
        return 'Productivity';
      case AppCategory.communication:
        return 'Communication';
      case AppCategory.shopping:
        return 'Shopping';
      case AppCategory.other:
        return 'Other';
    }
  }

  /// Category UI Icon
  IconData get icon {
    switch (this) {
      case AppCategory.socialMedia:
        return Icons.people_alt_rounded;
      case AppCategory.gaming:
        return Icons.sports_esports_rounded;
      case AppCategory.entertainment:
        return Icons.movie_filter_rounded;
      case AppCategory.education:
        return Icons.school_rounded;
      case AppCategory.productivity:
        return Icons.check_circle_outline_rounded;
      case AppCategory.communication:
        return Icons.chat_bubble_outline_rounded;
      case AppCategory.shopping:
        return Icons.shopping_bag_outlined;
      case AppCategory.other:
        return Icons.apps_rounded;
    }
  }

  /// Theme accent color for category
  Color get color {
    switch (this) {
      case AppCategory.socialMedia:
        return CategoryColors.socialMedia;
      case AppCategory.gaming:
        return CategoryColors.gaming;
      case AppCategory.entertainment:
        return CategoryColors.entertainment;
      case AppCategory.education:
        return CategoryColors.education;
      case AppCategory.productivity:
        return CategoryColors.productivity;
      case AppCategory.communication:
        return CategoryColors.communication;
      case AppCategory.shopping:
        return CategoryColors.shopping;
      case AppCategory.other:
        return CategoryColors.other;
    }
  }

  /// Serializes enum to Firestore/JSON key
  String toJson() => name;

  /// Deserializes string from Firestore/JSON
  static AppCategory fromJson(String? value) {
    if (value == null) return AppCategory.other;
    try {
      return AppCategory.values.firstWhere(
        (e) => e.name.toLowerCase() == value.toLowerCase() ||
               e.displayName.toLowerCase() == value.toLowerCase(),
        orElse: () => AppCategory.other,
      );
    } catch (_) {
      return AppCategory.other;
    }
  }
}
