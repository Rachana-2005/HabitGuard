import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/algorithms/risk_score_calculator.dart';
import '../core/categorization/app_categorizer.dart';
import '../core/constants/app_constants.dart';
import '../models/app_category.dart';
import '../models/application_usage.dart';
import '../models/daily_usage.dart';
import 'mock_usage_service.dart';

/// Service interfacing with native Android UsageStatsManager via MethodChannel
class UsageService {
  static const MethodChannel _channel = MethodChannel(AppConstants.usageChannelName);

  /// Checks whether mock data mode is currently active
  Future<bool> isMockModeEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(AppConstants.prefKeyMockDataEnabled) ?? false;
    } catch (_) {
      return false;
    }
  }

  /// Sets mock data mode preference
  Future<void> setMockMode(bool enabled, {MockRiskPreset? preset}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(AppConstants.prefKeyMockDataEnabled, enabled);
      if (preset != null) {
        MockUsageService.currentPreset = preset;
        await prefs.setString(AppConstants.prefKeyMockRiskPreset, preset.name);
      }
    } catch (e) {
      debugPrint('Error setting mock mode: $e');
    }
  }





  
  /// Checks if Android Usage Access permission is granted
  Future<bool> checkUsagePermission() async {
    final mockEnabled = await isMockModeEnabled();
    if (mockEnabled) {
      return true;
    }

    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool? hasPermission = await _channel.invokeMethod<bool>('checkUsagePermission');
        return hasPermission ?? false;
      } on PlatformException catch (e) {
        debugPrint('PlatformException checking usage permission: ${e.message}');
        return false;
      } catch (e) {
        debugPrint('Error checking usage permission: $e');
        return false;
      }
    }

    // Default to granted for development on non-Android platforms
    return true;
  }

  /// Launches Android Usage Access Settings screen
  Future<bool> requestUsagePermission() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        final bool? launched = await _channel.invokeMethod<bool>('requestUsagePermission');
        return launched ?? false;
      } on PlatformException catch (e) {
        debugPrint('PlatformException requesting usage permission: ${e.message}');
        return false;
      }
    }
    return true;
  }

  /// Fetches today's application usage data (from 00:00:00 to now)
  Future<List<ApplicationUsage>> getTodayUsage() async {
    final mockEnabled = await isMockModeEnabled();

    if (mockEnabled || kIsWeb || !Platform.isAndroid) {
      final mockList = MockUsageService.getMockTodayUsage();
      return _enrichUsageWithPercentages(mockList);
    }

    try {
      final List<dynamic>? rawStats = await _channel.invokeMethod<List<dynamic>>('getTodayUsage');
      if (rawStats == null || rawStats.isEmpty) {
        return [];
      }

      final List<ApplicationUsage> apps = [];
      for (final raw in rawStats) {
        if (raw is Map) {
          final pkgName = raw['packageName']?.toString() ?? '';
          final appName = raw['applicationName']?.toString() ?? pkgName;
          final durationMs = (raw['usageMilliseconds'] as num?)?.toInt() ?? 0;

          if (durationMs > 0 && pkgName.isNotEmpty) {
            final category = AppCategorizer.categorize(pkgName, appName);
            apps.add(
              ApplicationUsage(
                packageName: pkgName,
                applicationName: appName,
                category: category,
                usageMilliseconds: durationMs,
              ),
            );
          }
        }
      }

      return _enrichUsageWithPercentages(apps);
    } on PlatformException catch (e) {
      debugPrint('Error retrieving today usage: ${e.message}');
      return [];
    } catch (e) {
      debugPrint('Unexpected error in getTodayUsage: $e');
      return [];
    }
  }

  /// Fetches application usage for a specific calendar date
  Future<List<ApplicationUsage>> getUsageForDate(DateTime date) async {
    final mockEnabled = await isMockModeEnabled();
    if (mockEnabled || kIsWeb || !Platform.isAndroid) {
      return _enrichUsageWithPercentages(MockUsageService.getMockTodayUsage());
    }

    final startOfDay = DateTime(date.year, date.month, date.day, 0, 0, 0);
    final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);

    try {
      final List<dynamic>? rawStats = await _channel.invokeMethod<List<dynamic>>(
        'getUsageForDate',
        {
          'startTime': startOfDay.millisecondsSinceEpoch,
          'endTime': endOfDay.millisecondsSinceEpoch,
        },
      );

      if (rawStats == null || rawStats.isEmpty) return [];

      final List<ApplicationUsage> apps = [];
      for (final raw in rawStats) {
        if (raw is Map) {
          final pkgName = raw['packageName']?.toString() ?? '';
          final appName = raw['applicationName']?.toString() ?? pkgName;
          final durationMs = (raw['usageMilliseconds'] as num?)?.toInt() ?? 0;

          if (durationMs > 0 && pkgName.isNotEmpty) {
            final category = AppCategorizer.categorize(pkgName, appName);
            apps.add(
              ApplicationUsage(
                packageName: pkgName,
                applicationName: appName,
                category: category,
                usageMilliseconds: durationMs,
              ),
            );
          }
        }
      }

      return _enrichUsageWithPercentages(apps);
    } catch (e) {
      debugPrint('Error in getUsageForDate: $e');
      return [];
    }
  }

  /// Fetches historical daily usage for past N days directly from native Android UsageStatsManager
  Future<List<DailyUsage>> getPastDaysUsage(int days) async {
    final mockEnabled = await isMockModeEnabled();
    if (mockEnabled || kIsWeb || !Platform.isAndroid) {
      return MockUsageService.getMockHistoryList(daysCount: days);
    }

    try {
      final List<dynamic>? rawDays = await _channel.invokeMethod<List<dynamic>>(
        'getPastDaysUsage',
        {'days': days},
      );

      if (rawDays == null || rawDays.isEmpty) {
        return [];
      }

      final List<DailyUsage> dailyList = [];

      for (final rawDay in rawDays) {
        if (rawDay is Map) {
          final dateStr = rawDay['date']?.toString() ?? '';
          final timestamp = (rawDay['timestamp'] as num?)?.toInt() ?? DateTime.now().millisecondsSinceEpoch;
          final rawApps = rawDay['applications'] as List<dynamic>? ?? [];

          final List<ApplicationUsage> apps = [];
          int socialMins = 0;
          int gamingMins = 0;
          int entMins = 0;
          int eduMins = 0;
          int prodMins = 0;
          int commMins = 0;
          int otherMins = 0;
          int totalMs = 0;

          for (final raw in rawApps) {
            if (raw is Map) {
              final pkgName = raw['packageName']?.toString() ?? '';
              final appName = raw['applicationName']?.toString() ?? pkgName;
              final durationMs = (raw['usageMilliseconds'] as num?)?.toInt() ?? 0;

              if (durationMs > 0 && pkgName.isNotEmpty) {
                final category = AppCategorizer.categorize(pkgName, appName);
                final app = ApplicationUsage(
                  packageName: pkgName,
                  applicationName: appName,
                  category: category,
                  usageMilliseconds: durationMs,
                );
                apps.add(app);

                totalMs += durationMs;
                final mins = app.usageMinutes;
                switch (category) {
                  case AppCategory.socialMedia:
                    socialMins += mins;
                    break;
                  case AppCategory.gaming:
                    gamingMins += mins;
                    break;
                  case AppCategory.entertainment:
                    entMins += mins;
                    break;
                  case AppCategory.education:
                    eduMins += mins;
                    break;
                  case AppCategory.productivity:
                    prodMins += mins;
                    break;
                  case AppCategory.communication:
                    commMins += mins;
                    break;
                  case AppCategory.shopping:
                  case AppCategory.other:
                    otherMins += mins;
                    break;
                }
              }
            }
          }

          final int totalMinutes = (totalMs / 60000).round();
          final dayDate = DateTime.fromMillisecondsSinceEpoch(timestamp);

          final assessment = RiskScoreCalculator.calculate(
            totalScreenTimeMinutes: totalMinutes,
            socialMediaMinutes: socialMins,
            gamingMinutes: gamingMins,
            entertainmentMinutes: entMins,
            educationMinutes: eduMins,
            productivityMinutes: prodMins,
            communicationMinutes: commMins,
            otherMinutes: otherMins,
            date: dayDate,
          );

          dailyList.add(
            DailyUsage(
              date: dateStr,
              totalScreenTimeMinutes: totalMinutes,
              totalScreenTimeMilliseconds: totalMs,
              socialMediaTime: socialMins,
              gamingTime: gamingMins,
              entertainmentTime: entMins,
              educationTime: eduMins,
              productivityTime: prodMins,
              communicationTime: commMins,
              otherTime: otherMins,
              riskScore: assessment.score,
              riskLevel: assessment.level,
              applications: _enrichUsageWithPercentages(apps),
              createdAt: dayDate,
            ),
          );
        }
      }

      dailyList.sort((a, b) => b.date.compareTo(a.date));
      return dailyList;
    } catch (e) {
      debugPrint('Error retrieving past days usage: $e');
      return [];
    }
  }

  /// Computes percentages for each application based on total foreground duration
  List<ApplicationUsage> _enrichUsageWithPercentages(List<ApplicationUsage> apps) {
    if (apps.isEmpty) return [];

    final int totalMs = apps.fold(0, (sum, item) => sum + item.usageMilliseconds);
    if (totalMs <= 0) return apps;

    return apps.map((app) {
      final double pct = app.usageMilliseconds / totalMs;
      return app.copyWith(percentageOfTotal: pct);
    }).toList();
  }
}
