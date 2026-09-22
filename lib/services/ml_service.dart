import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/behavioral_features.dart';
import '../models/risk_model.dart';
import '../models/risk_assessment.dart';

/// Client service communicating with the Python FastAPI Machine Learning backend.
/// Handles risk classification, Explainable AI factors, connectivity checks, and transparent fallbacks.
class MlService {
  static final MlService _instance = MlService._internal();
  factory MlService() => _instance;
  MlService._internal();

  String _mlApiUrl = AppConstants.defaultMlApiUrl;
  bool _useMockML = false;

  String get mlApiUrl => _mlApiUrl;
  bool get useMockML => _useMockML;

  /// Initializes preferences for ML service endpoints and modes
  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _mlApiUrl = prefs.getString(AppConstants.prefKeyMlApiUrl) ?? AppConstants.defaultMlApiUrl;
      _useMockML = prefs.getBool(AppConstants.prefKeyUseMockML) ?? false;
    } catch (e) {
      debugPrint('MlService init notice: $e');
    }
  }

  Future<void> setUseMockML(bool value) async {
    _useMockML = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyUseMockML, value);
  }

  Future<void> setMlApiUrl(String url) async {
    _mlApiUrl = url;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyMlApiUrl, url);
  }

  /// Checks if the Python ML server is alive and has loaded the trained Random Forest model
  Future<bool> checkHealth() async {
    if (_useMockML) return true;
    try {
      final uri = Uri.parse('$_mlApiUrl/health');
      final response = await http.get(uri).timeout(const Duration(seconds: 3));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['status'] == 'healthy' && data['model_loaded'] == true;
      }
      return false;
    } catch (_) {
      // Try fallback to localhost if 10.0.2.2 fails (e.g. running on desktop/web)
      if (_mlApiUrl.contains('10.0.2.2')) {
        try {
          final fallbackUri = Uri.parse('${AppConstants.defaultMlLocalUrl}/health');
          final resp = await http.get(fallbackUri).timeout(const Duration(seconds: 2));
          if (resp.statusCode == 200) {
            _mlApiUrl = AppConstants.defaultMlLocalUrl;
            return true;
          }
        } catch (_) {}
      }
      return false;
    }
  }

  /// Sends behavioral features vector to `/predict-risk` endpoint
  Future<MlRiskPrediction> predictRisk(BehavioralFeatures features, {bool? forceMock}) async {
    final bool shouldUseMock = forceMock ?? _useMockML;

    // 1. Mock ML Mode (Explicit Development Mode only)
    if (shouldUseMock) {
      return _generateMockPrediction(features);
    }

    // 2. Real ML Mode: Call FastAPI service
    try {
      final uri = Uri.parse('$_mlApiUrl/predict-risk');
      final payload = jsonEncode(features.toMlRequest());

      final response = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: payload,
      ).timeout(const Duration(seconds: 6));

      if (response.statusCode == 200) {
        final Map<String, dynamic> data = jsonDecode(response.body);
        return MlRiskPrediction.fromApiResponse(
          data,
          trend: features.sevenDayRiskTrend,
          isMock: false,
        );
      } else {
        debugPrint('ML Service returned status ${response.statusCode}: ${response.body}');
        return MlRiskPrediction.unavailable(
          message: 'AI Risk Prediction Temporarily Unavailable (HTTP ${response.statusCode})',
        );
      }
    } catch (e) {
      debugPrint('ML Service connection failed: $e');
      // Transparent error state without fabricating fake ML data
      return MlRiskPrediction.unavailable(
        message: 'AI Risk Prediction Temporarily Unavailable: Could not connect to Python ML service at $_mlApiUrl.',
      );
    }
  }

  /// Realistic mock prediction for controlled development/testing when explicit mock mode is ON
  MlRiskPrediction _generateMockPrediction(BehavioralFeatures features) {
    int score = 0;
    // Calculate approximate score for realistic mock preview
    score += ((features.totalScreenTime / 480.0) * 45).round();
    score += ((features.socialMediaTime / 180.0) * 25).round();
    score += ((features.lateNightUsage / 90.0) * 20).round();
    score += ((features.numberOfAppSessions / 70.0) * 10).round();
    if (features.productiveUsagePercentage >= 25.0) {
      score = (score - 15).clamp(0, 100);
    }
    score = score.clamp(5, 95);

    final level = RiskLevel.fromScore(score);
    final factors = <RiskFactorImpact>[];

    if (features.lateNightUsage >= 30) {
      factors.add(RiskFactorImpact(
        factor: 'Late Night Usage',
        impact: features.lateNightUsage >= 60 ? 'HIGH' : 'MEDIUM',
        description: '${features.lateNightUsage} minutes of screen time after 11 PM [MOCK PREVIEW].',
      ));
    }
    if (features.socialMediaTime >= 60) {
      factors.add(RiskFactorImpact(
        factor: 'Social Media Usage',
        impact: features.socialMediaTime >= 120 ? 'HIGH' : 'MEDIUM',
        description: '${features.socialMediaTime}m spent on social media apps [MOCK PREVIEW].',
      ));
    }
    if (features.numberOfAppSessions >= 45) {
      factors.add(RiskFactorImpact(
        factor: 'Frequent App Sessions',
        impact: 'MEDIUM',
        description: '${features.numberOfAppSessions} phone pickup sessions detected [MOCK PREVIEW].',
      ));
    }
    if (factors.isEmpty) {
      factors.add(const RiskFactorImpact(
        factor: 'Balanced Habits',
        impact: 'LOW',
        description: 'Usage is within safe digital wellbeing limits [MOCK PREVIEW].',
      ));
    }

    return MlRiskPrediction(
      riskScore: score,
      riskLevel: level,
      confidence: 0.85,
      riskFactors: factors,
      trend: features.sevenDayRiskTrend,
      isMock: true,
      timestamp: DateTime.now(),
    );
  }
}
