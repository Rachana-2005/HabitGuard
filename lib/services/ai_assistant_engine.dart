import '../core/utils/time_formatter.dart';
import '../models/app_category.dart';
import '../models/daily_usage.dart';
import '../models/user_model.dart';
import '../providers/history_provider.dart';
import '../providers/usage_provider.dart';

/// Rule-based intelligent response engine for HabitGuard AI Assistant.
/// Evaluates user queries and generates context-aware, personalized responses
/// using dynamic screen time, category breakdown, app rankings, and historical records.
class AiAssistantEngine {
  /// Evaluates query against rule-based intent classifiers and returns a dynamic answer
  static String generateResponse({
    required String query,
    required UsageProvider usageProvider,
    required HistoryProvider historyProvider,
    UserModel? user,
  }) {
    final q = query.toLowerCase().trim();

    // ----------------------------------------------------
    // Intent 1 (Priority): Compare Today with Yesterday
    // ----------------------------------------------------
    if (_matches(q, [
      'compare today\'s usage with yesterday\'s usage',
      'compare today with yesterday',
      'compare with yesterday',
      'compare',
      'yesterday',
      'today vs yesterday',
      'yesterday comparison',
      'difference from yesterday',
      'am i using phone more than yesterday',
      'how much did i use yesterday',
    ])) {
      return _generateYesterdayComparisonResponse(usageProvider, historyProvider);
    }

    // ----------------------------------------------------
    // Intent 2 (Priority): Advice & Tips to Reduce Screen Time
    // ----------------------------------------------------
    if (_matches(q, [
      'give me advice to reduce screen time',
      'advice to reduce screen time',
      'advice to reduce',
      'advice',
      'tips to reduce',
      'how can i reduce screen time',
      'how to reduce screen time',
      'reduce screen time',
      'how to reduce',
      'how can i reduce',
      'tips',
      'suggestions to reduce',
      'help me reduce',
      'habits to improve',
      'stop scrolling',
      'stop addiction',
    ])) {
      return _generateAdviceResponse(usageProvider);
    }

    // ----------------------------------------------------
    // Intent 3: Most Used App / Top App
    // ----------------------------------------------------
    if (_matches(q, [
      'which app did i use the most',
      'which app i used most',
      'most used app',
      'top app',
      'top application',
      'highest used app',
      'app used the most',
      'what app did i use most',
      'most time on which app',
      'which app',
    ])) {
      return _generateTopAppResponse(usageProvider);
    }

    // ----------------------------------------------------
    // Intent 4: Most Used Category / Category Breakdown
    // ----------------------------------------------------
    if (_matches(q, [
      'which category did i use the most',
      'which category i used most',
      'most used category',
      'top category',
      'category did i use the most',
      'category breakdown',
      'highest category',
      'category used the most',
      'which category',
      'categories',
    ])) {
      return _generateTopCategoryResponse(usageProvider);
    }

    // ----------------------------------------------------
    // Intent 5: Risk Level & Addiction Assessment
    // ----------------------------------------------------
    if (_matches(q, [
      'what is my risk level',
      'risk level',
      'risk score',
      'addiction risk',
      'am i addicted',
      'addiction level',
      'my score',
      'risk assessment',
      'how risky is my usage',
      'risk',
    ])) {
      return _generateRiskLevelResponse(usageProvider);
    }

    // ----------------------------------------------------
    // Intent 6: Today's Total Screen Time
    // ----------------------------------------------------
    if (_matches(q, [
      'what is my screen time today',
      'screen time today',
      'screen time',
      'today usage',
      'today\'s usage',
      'how much time did i use today',
      'how long have i used my phone',
      'how long did i use',
      'total screen time',
      'total time today',
      'hours today',
      'usage today',
      'time today',
    ])) {
      return _generateScreenTimeResponse(usageProvider);
    }

    // ----------------------------------------------------
    // Intent 7: Greetings & Introduction
    // ----------------------------------------------------
    if (_matches(q, ['hi', 'hello', 'hey', 'good morning', 'good afternoon', 'good evening', 'who are you', 'help'])) {
      final name = user?.name.isNotEmpty == true ? ', ${user!.name.split(' ').first}' : '';
      return 'Hello$name! 👋 I am your **HabitGuard AI Assistant**.\n\nI can analyze your live usage data and answer questions such as:\n\n'
          '• **"What is my screen time today?"**\n'
          '• **"Which app did I use the most?"**\n'
          '• **"What is my risk level?"**\n'
          '• **"Which category did I use the most?"**\n'
          '• **"Compare today\'s usage with yesterday\'s usage"**\n'
          '• **"Give me advice to reduce screen time"**\n\n'
          'What would you like to check?';
    }

    // ----------------------------------------------------
    // Fallback: Context-Aware Helper
    // ----------------------------------------------------
    return 'I analyzed your request: *"$query"*\n\n'
        'Here are the key insights I can provide directly from your device data:\n\n'
        '1. ⏱️ **"What is my screen time today?"** — View total minutes & category split\n'
        '2. 📱 **"Which app did I use the most?"** — See your top applications ranking\n'
        '3. 🛡️ **"What is my risk level?"** — Check your digital addiction risk score\n'
        '4. 📊 **"Which category did I use the most?"** — Identify your dominant habit category\n'
        '5. ⚖️ **"Compare today\'s usage with yesterday\'s usage"** — Track daily trend\n'
        '6. 💡 **"Give me advice to reduce screen time"** — Personalized reduction strategies';
  }

  // Helper matcher
  static bool _matches(String query, List<String> patterns) {
    for (final pattern in patterns) {
      if (query.contains(pattern)) return true;
    }
    return false;
  }

  // ----------------------------------------------------
  // Generators
  // ----------------------------------------------------

  static String _generateScreenTimeResponse(UsageProvider usage) {
    final daily = usage.todayDailyUsage;
    final totalMins = daily?.totalScreenTimeMinutes ?? 0;
    final formattedTime = TimeFormatter.formatMinutes(totalMins);

    if (totalMins <= 0) {
      return '⏱️ **Today\'s Screen Time:**\n\nYou have recorded **0 minutes** of active screen time today. Your app activity will appear here as you use your device.';
    }

    final buffer = StringBuffer();
    buffer.writeln('⏱️ **Today\'s Screen Time Summary:**\n');
    buffer.writeln('Your total active screen time today is **$formattedTime** ($totalMins minutes).\n');
    buffer.writeln('**Category Breakdown:**');

    final categories = [
      MapEntry(AppCategory.socialMedia.displayName, daily?.socialMediaTime ?? 0),
      MapEntry(AppCategory.entertainment.displayName, daily?.entertainmentTime ?? 0),
      MapEntry(AppCategory.gaming.displayName, daily?.gamingTime ?? 0),
      MapEntry(AppCategory.productivity.displayName, daily?.productivityTime ?? 0),
      MapEntry(AppCategory.education.displayName, daily?.educationTime ?? 0),
      MapEntry(AppCategory.communication.displayName, daily?.communicationTime ?? 0),
      MapEntry(AppCategory.other.displayName, daily?.otherTime ?? 0),
    ]..sort((a, b) => b.value.compareTo(a.value));

    for (final entry in categories) {
      if (entry.value > 0) {
        final pct = ((entry.value / totalMins) * 100).round();
        buffer.writeln('• **${entry.key}**: ${TimeFormatter.formatMinutes(entry.value)} ($pct%)');
      }
    }

    buffer.writeln('');
    if (totalMins <= 120) {
      buffer.writeln('🌟 **Healthy Range**: Your screen time is under 2 hours today. Excellent focus!');
    } else if (totalMins <= 240) {
      buffer.writeln('⚠️ **Moderate Usage**: Your screen time is between 2 to 4 hours. Keep monitoring your entertainment usage.');
    } else {
      buffer.writeln('🚨 **High Usage**: You have spent over 4 hours on your device today. Consider taking a digital detox break.');
    }

    return buffer.toString();
  }

  static String _generateTopAppResponse(UsageProvider usage) {
    final apps = usage.todayApplications;
    if (apps.isEmpty) {
      return '📱 **Most Used App:**\n\nNo app usage has been recorded yet today.';
    }

    final topApp = apps.first;
    final topDuration = topApp.formattedDuration;
    final pct = (topApp.percentageOfTotal * 100).toStringAsFixed(1);

    final buffer = StringBuffer();
    buffer.writeln('🏆 **Most Used App Today:**\n');
    buffer.writeln('Your #1 most used app is **${topApp.applicationName}** with **$topDuration** of active screen time ($pct% of your total usage).\n');
    buffer.writeln('**Top Applications Ranking:**');

    final limit = apps.length < 5 ? apps.length : 5;
    for (int i = 0; i < limit; i++) {
      final app = apps[i];
      final rank = i + 1;
      buffer.writeln('$rank. **${app.applicationName}** (${app.category.displayName}) — ${app.formattedDuration}');
    }

    return buffer.toString();
  }

  static String _generateRiskLevelResponse(UsageProvider usage) {
    final assessment = usage.currentAssessment;
    final score = assessment?.score ?? usage.todayDailyUsage?.riskScore ?? 0;
    final level = assessment?.level.fullLabel ?? usage.todayDailyUsage?.riskLevel.fullLabel ?? 'LOW RISK';
    final topCategory = assessment?.topCategory.displayName ?? 'General';

    final buffer = StringBuffer();
    buffer.writeln('🛡️ **Digital Addiction Risk Assessment:**\n');
    buffer.writeln('• **Risk Level**: **$level**');
    buffer.writeln('• **Risk Score**: **$score / 100**\n');

    if (score <= 30) {
      buffer.writeln('🟢 **Low Risk (Healthy Digital Wellbeing)**:\nYour smartphone habits are well-balanced. You are in control of your digital consumption.');
    } else if (score <= 60) {
      buffer.writeln('🟡 **Moderate Risk**:\nYour usage is elevated, primarily driven by **$topCategory**. Setting app time limits will help prevent habitual checking.');
    } else if (score <= 80) {
      buffer.writeln('🟠 **High Risk**:\nYour screen time is significantly elevated. High engagement in **$topCategory** is increasing your addiction risk score.');
    } else {
      buffer.writeln('🔴 **Critical Risk**:\nExcessive screen time detected. Immediate digital boundaries and guardian awareness are strongly recommended.');
    }

    return buffer.toString();
  }

  static String _generateTopCategoryResponse(UsageProvider usage) {
    final daily = usage.todayDailyUsage;
    final totalMins = daily?.totalScreenTimeMinutes ?? 0;
    if (totalMins <= 0) {
      return '📊 **Top Category:**\n\nNo category usage recorded yet today.';
    }

    final categories = [
      MapEntry(AppCategory.socialMedia, daily?.socialMediaTime ?? 0),
      MapEntry(AppCategory.gaming, daily?.gamingTime ?? 0),
      MapEntry(AppCategory.entertainment, daily?.entertainmentTime ?? 0),
      MapEntry(AppCategory.education, daily?.educationTime ?? 0),
      MapEntry(AppCategory.productivity, daily?.productivityTime ?? 0),
      MapEntry(AppCategory.communication, daily?.communicationTime ?? 0),
      MapEntry(AppCategory.other, daily?.otherTime ?? 0),
    ]..sort((a, b) => b.value.compareTo(a.value));

    final topCategory = categories.first;
    final topMins = topCategory.value;
    final pct = totalMins > 0 ? ((topMins / totalMins) * 100).round() : 0;

    final buffer = StringBuffer();
    buffer.writeln('📊 **Most Used Category Today:**\n');
    buffer.writeln('Your top category is **${topCategory.key.displayName}** with **${TimeFormatter.formatMinutes(topMins)}** ($topMins minutes), accounting for **$pct%** of your total daily usage.\n');
    buffer.writeln('**All Categories Today:**');

    for (final entry in categories) {
      if (entry.value > 0) {
        final categoryPct = ((entry.value / totalMins) * 100).round();
        buffer.writeln('• **${entry.key.displayName}**: ${TimeFormatter.formatMinutes(entry.value)} ($categoryPct%)');
      }
    }

    return buffer.toString();
  }

  static String _generateYesterdayComparisonResponse(
    UsageProvider usage,
    HistoryProvider historyProvider,
  ) {
    final todayMins = usage.todayDailyUsage?.totalScreenTimeMinutes ?? 0;
    final history = historyProvider.history;

    DailyUsage? yesterday;
    final yesterdayDateKey = TimeFormatter.formatDateKey(DateTime.now().subtract(const Duration(days: 1)));

    for (final day in history) {
      if (day.date == yesterdayDateKey) {
        yesterday = day;
        break;
      }
    }

    // Fallback if exact date match is not found but history has at least 2 entries
    if (yesterday == null && history.length > 1) {
      yesterday = history[1];
    }

    if (yesterday == null) {
      return '⚖️ **Usage Comparison:**\n\n'
          '• **Today\'s Screen Time**: ${TimeFormatter.formatMinutes(todayMins)} ($todayMins min)\n\n'
          'Yesterday\'s historical data is currently syncing. Once loaded, you will see a detailed comparison of your day-over-day changes.';
    }

    final yesterdayMins = yesterday.totalScreenTimeMinutes;
    final diffMins = todayMins - yesterdayMins;

    final buffer = StringBuffer();
    buffer.writeln('⚖️ **Today vs. Yesterday Comparison:**\n');
    buffer.writeln('• **Today**: ${TimeFormatter.formatMinutes(todayMins)} ($todayMins min)');
    buffer.writeln('• **Yesterday**: ${TimeFormatter.formatMinutes(yesterdayMins)} ($yesterdayMins min)\n');

    if (diffMins > 0) {
      final pctIncrease = yesterdayMins > 0 ? ((diffMins / yesterdayMins) * 100).round() : 100;
      buffer.writeln('📈 You have used your phone **${TimeFormatter.formatMinutes(diffMins)} MORE (+$pctIncrease%)** today compared to yesterday.');
      buffer.writeln('\n💡 *Tip: Try reducing non-essential browsing to keep today\'s usage close to yesterday\'s baseline.*');
    } else if (diffMins < 0) {
      final pctDecrease = yesterdayMins > 0 ? ((diffMins.abs() / yesterdayMins) * 100).round() : 0;
      buffer.writeln('📉 🎉 **Great job!** You have reduced your screen time by **${TimeFormatter.formatMinutes(diffMins.abs())} (-$pctDecrease%)** compared to yesterday.');
      buffer.writeln('\nKeep up the disciplined digital habits!');
    } else {
      buffer.writeln('⚖️ Your screen time today is **identical** to yesterday\'s screen time (${TimeFormatter.formatMinutes(todayMins)}).');
    }

    return buffer.toString();
  }

  static String _generateAdviceResponse(UsageProvider usage) {
    final topApps = usage.todayApplications;
    final topApp = topApps.isNotEmpty ? topApps.first : null;
    final assessment = usage.currentAssessment;
    final topCategory = assessment?.topCategory ?? AppCategory.other;

    final buffer = StringBuffer();
    buffer.writeln('💡 **Personalized Advice to Reduce Screen Time:**\n');

    // Dynamic advice based on top category
    if (topCategory == AppCategory.socialMedia) {
      buffer.writeln('1. 📱 **Social Media Batching**: Designate two 20-minute windows per day for ${topApp?.applicationName ?? 'social media'} rather than checking impulsively throughout the day.');
    } else if (topCategory == AppCategory.gaming) {
      buffer.writeln('1. 🎮 **Session Caps**: Set a strict 45-minute timer before starting a game on ${topApp?.applicationName ?? 'games'}, and avoid gaming before sleep.');
    } else if (topCategory == AppCategory.entertainment) {
      buffer.writeln('1. 🎬 **Disable Autoplay**: Turn off auto-play next video features on ${topApp?.applicationName ?? 'video streaming apps'} to stop endless watching loops.');
    } else {
      buffer.writeln('1. ⏱️ **App Limiters**: Set daily time limits for ${topApp?.applicationName ?? 'your most used apps'} in device Digital Wellbeing settings.');
    }

    buffer.writeln('2. 🌙 **Digital Sunset**: Put your device away at least 30 minutes before bedtime to prevent sleep cycle disruptions.');
    buffer.writeln('3. 📵 **Create Phone-Free Zones**: Keep meal tables, study desks, and bedtime areas free from smartphones.');
    buffer.writeln('4. 🔔 **Notification Diet**: Turn off non-essential social notifications to eliminate habitual trigger loops.');

    if (assessment != null && assessment.recommendations.isNotEmpty) {
      buffer.writeln('\n**HabitGuard Algorithm Recommendations:**');
      for (final rec in assessment.recommendations.take(2)) {
        buffer.writeln('• $rec');
      }
    }

    return buffer.toString();
  }
}
