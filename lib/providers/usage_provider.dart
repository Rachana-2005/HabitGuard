import 'package:flutter/material.dart';
import '../models/app_category.dart';
import '../models/application_usage.dart';
import '../models/behavioral_features.dart';
import '../models/daily_usage.dart';
import '../models/risk_assessment.dart';
import '../services/feature_service.dart';
import '../core/algorithms/risk_score_calculator.dart';
import '../core/utils/time_formatter.dart';
import '../services/firestore_service.dart';
import '../services/mock_usage_service.dart';
import '../services/usage_service.dart';

/// Provider managing usage statistics collection, aggregation, permissions, and mock state
class UsageProvider extends ChangeNotifier {
  final UsageService _usageService = UsageService();
  final FirestoreService _firestoreService = FirestoreService();

  bool _hasPermission = false;
  bool _isLoading = false;
  bool _isMockMode = false;
  MockRiskPreset _currentMockPreset = MockRiskPreset.high;
  List<ApplicationUsage> _todayApplications = [];
  DailyUsage? _todayDailyUsage;
  RiskAssessment? _currentAssessment;
  BehavioralFeatures? _todayFeatures;
  String? _errorMessage;

  bool get hasPermission => _hasPermission;
  bool get isLoading => _isLoading;
  bool get isMockMode => _isMockMode;
  MockRiskPreset get currentMockPreset => _currentMockPreset;
  List<ApplicationUsage> get todayApplications => _todayApplications;
  DailyUsage? get todayDailyUsage => _todayDailyUsage;
  RiskAssessment? get currentAssessment => _currentAssessment;
  BehavioralFeatures? get todayFeatures => _todayFeatures;
  String? get errorMessage => _errorMessage;

  /// Initializes usage provider, checks permission and mock mode
  Future<void> initialize(String? uid) async {
    _isLoading = true;
    notifyListeners();

    _isMockMode = await _usageService.isMockModeEnabled();
    _hasPermission = await _usageService.checkUsagePermission();

    if (_hasPermission || _isMockMode) {
      await fetchTodayUsage(uid);
    }

    _isLoading = false;
    notifyListeners();
  }

  /// Checks Usage Access permission
  Future<bool> checkPermission() async {
    _hasPermission = await _usageService.checkUsagePermission();
    notifyListeners();
    return _hasPermission;
  }

  /// Requests Usage Access permission from system settings
  Future<void> requestPermission() async {
    await _usageService.requestUsagePermission();
    // After user returns from settings, re-check
    await checkPermission();
  }

  /// Toggles Developer Mock Data mode
  Future<void> setMockMode(bool enabled, {MockRiskPreset? preset, String? uid}) async {
    _isMockMode = enabled;
    if (preset != null) {
      _currentMockPreset = preset;
    }
    await _usageService.setMockMode(enabled, preset: _currentMockPreset);
    _hasPermission = true;
    await fetchTodayUsage(uid);
    notifyListeners();
  }

  /// Changes mock preset (e.g. Low, Moderate, High, Critical)
  Future<void> switchMockPreset(MockRiskPreset preset, {String? uid}) async {
    _currentMockPreset = preset;
    MockUsageService.currentPreset = preset;
    await _usageService.setMockMode(_isMockMode, preset: preset);
    await fetchTodayUsage(uid);
    notifyListeners();
  }

  /// Fetches today's usage, aggregates categories, calculates risk score, and syncs to Firestore
  Future<void> fetchTodayUsage(String? uid) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final apps = await _usageService.getTodayUsage();
      _todayApplications = apps;

      // Category breakdown aggregation
      int socialMins = 0;
      int gamingMins = 0;
      int entMins = 0;
      int eduMins = 0;
      int prodMins = 0;
      int commMins = 0;
      int otherMins = 0;
      int totalMs = 0;

      for (final app in apps) {
        totalMs += app.usageMilliseconds;
        final mins = app.usageMinutes;
        switch (app.category) {
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

      final int totalMinutes = (totalMs / 60000).round();
      final now = DateTime.now();

      // Calculate Risk Assessment
      final assessment = RiskScoreCalculator.calculate(
        totalScreenTimeMinutes: totalMinutes,
        socialMediaMinutes: socialMins,
        gamingMinutes: gamingMins,
        entertainmentMinutes: entMins,
        educationMinutes: eduMins,
        productivityMinutes: prodMins,
        communicationMinutes: commMins,
        otherMinutes: otherMins,
        date: now,
      );

      _currentAssessment = assessment;

      // Construct DailyUsage
      final daily = DailyUsage(
        date: TimeFormatter.formatDateKey(now),
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
        applications: apps,
        createdAt: now,
      );

      _todayDailyUsage = daily;

      // Extract multi-dimensional behavioral features
      final features = FeatureService.extractFeatures(todayUsage: daily);
      _todayFeatures = features;

      // Sync to Firestore if authenticated
      if (uid != null && uid.isNotEmpty) {
        await _firestoreService.saveDailyUsage(uid, daily);
        await _firestoreService.saveBehavioralFeatures(uid, daily.date, features.toFirestore());
      }
    } catch (e) {
      _errorMessage = 'Failed to load usage data: $e';
      debugPrint('Error in fetchTodayUsage: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
