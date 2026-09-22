import 'package:intl/intl.dart';

/// Helper utility for converting and formatting durations, timestamps, and dates.
class TimeFormatter {
  /// Converts minutes into human-readable format e.g. "5h 42m" or "45m"
  static String formatMinutes(int minutes) {
    if (minutes <= 0) return '0m';
    final hours = minutes ~/ 60;
    final remainingMinutes = minutes % 60;

    if (hours > 0 && remainingMinutes > 0) {
      return '${hours}h ${remainingMinutes}m';
    } else if (hours > 0) {
      return '${hours}h';
    } else {
      return '${remainingMinutes}m';
    }
  }

  /// Converts milliseconds into human-readable format
  static String formatMilliseconds(int milliseconds) {
    final minutes = (milliseconds / 60000).round();
    return formatMinutes(minutes);
  }

  /// Converts Duration object into formatted string
  static String formatDuration(Duration duration) {
    return formatMinutes(duration.inMinutes);
  }

  /// Formats date to display format: "14 Aug 2026"
  static String formatDate(DateTime date) {
    return DateFormat('dd MMM yyyy').format(date);
  }

  /// Formats date to concise format: "Wed, Aug 14"
  static String formatDateShort(DateTime date) {
    return DateFormat('EEE, MMM d').format(date);
  }

  /// Formats date to weekday short name: "Mon", "Tue"
  static String formatWeekday(DateTime date) {
    return DateFormat('E').format(date);
  }

  /// Formats date as standardized Firestore key: "2026-08-14"
  static String formatDateKey(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Parses standardized Firestore key back to DateTime
  static DateTime parseDateKey(String key) {
    return DateFormat('yyyy-MM-dd').parse(key);
  }

  /// Formats time of day: "10:45 AM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Returns greeting according to time of day ("Good Morning", "Good Afternoon", "Good Evening")
  static String getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good Morning';
    } else if (hour < 17) {
      return 'Good Afternoon';
    } else {
      return 'Good Evening';
    }
  }
}
