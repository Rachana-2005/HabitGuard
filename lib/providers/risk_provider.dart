import 'package:flutter/material.dart';
import '../models/app_category.dart';
import '../models/behavioral_features.dart';
import '../models/risk_assessment.dart';
import '../models/risk_model.dart';
import '../models/user_model.dart';
import '../services/guardian_alert_service.dart';
import '../services/ml_service.dart';

/// Provider managing Machine Learning risk prediction, Explainable AI factors, and Guardian alerts
class RiskProvider extends ChangeNotifier {
  final MlService _mlService = MlService();
  final GuardianAlertService _guardianAlertService = GuardianAlertService();

  MlRiskPrediction? _currentPrediction;
  BehavioralFeatures? _currentFeatures;
  bool _isPredicting = false;
  String? _predictionError;

  bool _isAlertTriggered = false;
  DateTime? _lastAlertTimestamp;
  String? _lastAlertMessage;

  MlRiskPrediction? get currentPrediction => _currentPrediction;
  BehavioralFeatures? get currentFeatures => _currentFeatures;
  bool get isPredicting => _isPredicting;
  String? get predictionError => _predictionError;

  bool get isAlertTriggered => _isAlertTriggered;
  DateTime? get lastAlertTimestamp => _lastAlertTimestamp;
  String? get lastAlertMessage => _lastAlertMessage;

  /// Runs Machine Learning prediction for the given behavioral features
  Future<void> predictRisk({
    required BehavioralFeatures features,
    UserModel? user,
  }) async {
    _currentFeatures = features;
    _isPredicting = true;
    _predictionError = null;
    notifyListeners();

    try {
      final prediction = await _mlService.predictRisk(features);
      _currentPrediction = prediction;

      // Check if prediction is an error / unavailable state
      if (prediction.errorMessage != null && prediction.errorMessage!.isNotEmpty) {
        _predictionError = prediction.errorMessage;
      }

      // Check guardian notification criteria (Score >= 61: HIGH or CRITICAL)
      if (user != null && prediction.riskScore >= 61) {
        await evaluateAndNotifyGuardian(
          user: user,
          prediction: prediction,
          totalScreenMinutes: features.totalScreenTime,
        );
      }
    } catch (e) {
      _predictionError = 'Failed to obtain risk prediction: $e';
      _currentPrediction = MlRiskPrediction.unavailable(message: _predictionError);
    } finally {
      _isPredicting = false;
      notifyListeners();
    }
  }

  /// Evaluates and dispatches Guardian Alert
  Future<bool> evaluateAndNotifyGuardian({
    required UserModel user,
    required MlRiskPrediction prediction,
    required int totalScreenMinutes,
  }) async {
    if (prediction.riskScore < 61) return false;

    final dummyAssessment = RiskAssessment(
      score: prediction.riskScore,
      level: prediction.riskLevel,
      topCategory: _currentFeatures != null
          ? AppCategory.fromJson(_currentFeatures!.mostUsedCategory)
          : AppCategory.other,
      categoryMinutes: const {},
      recommendations: prediction.riskFactors.map((f) => f.description).toList(),
      assessmentDate: DateTime.now(),
    );

    final bool sent = await _guardianAlertService.evaluateAndDispatchAlert(
      user: user,
      assessment: dummyAssessment,
      totalScreenMinutes: totalScreenMinutes,
    );

    if (sent) {
      _isAlertTriggered = true;
      _lastAlertTimestamp = DateTime.now();
      _lastAlertMessage = 'High-risk alert dispatched to ${user.guardianName} (${user.formattedGuardianMobile})';
      notifyListeners();
    }
    return sent;
  }

  /// Manually triggers a test guardian alert (for profile / developer testing)
  Future<bool> triggerTestAlert({required UserModel user, required int mockScore}) async {
    final testAssessment = RiskAssessment(
      score: mockScore,
      level: RiskLevel.fromScore(mockScore),
      topCategory: AppCategory.other,
      categoryMinutes: const {},
      recommendations: const ['Test Recommendation'],
      assessmentDate: DateTime.now(),
    );

    final sent = await _guardianAlertService.evaluateAndDispatchAlert(
      user: user,
      assessment: testAssessment,
      totalScreenMinutes: 380,
    );

    if (sent) {
      _isAlertTriggered = true;
      _lastAlertTimestamp = DateTime.now();
      _lastAlertMessage = 'Test alert dispatched to ${user.guardianName}';
      notifyListeners();
    }

    return sent;
  }
}
