import 'package:flutter/foundation.dart';
import '../models/ai_message_model.dart';
import '../models/behavioral_features.dart';
import '../models/daily_usage.dart';
import '../models/recommendation_model.dart';
import '../models/risk_model.dart';
import '../services/genai_service.dart';
import '../services/ml_service.dart';

/// Provider for managing AI Wellness Coach chat, personalized plans, weekly reports, and AI services status
class AiProvider extends ChangeNotifier {
  final GenAiService _genAiService = GenAiService();
  final MlService _mlService = MlService();

  final List<AiMessage> _messages = [];
  bool _isLoading = false;
  String? _errorMessage;

  // AI Services Connectivity Status
  bool _mlConnected = false;
  bool _genAiConnected = false;
  bool _trackingConnected = false;

  List<AiMessage> get messages => List.unmodifiable(_messages);
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  bool get mlConnected => _mlConnected;
  bool get genAiConnected => _genAiConnected;
  bool get trackingConnected => _trackingConnected;

  GenAiService get genAiService => _genAiService;
  MlService get mlService => _mlService;

  AiProvider() {
    _init();
  }

  Future<void> _init() async {
    await _genAiService.init();
    await _mlService.init();
    await checkAiServicesHealth();
  }

  /// Refreshes connectivity status of all AI components
  Future<void> checkAiServicesHealth() async {
    _mlConnected = await _mlService.checkHealth();
    _genAiConnected = _genAiService.isConfigured || _genAiService.useMockGenAI;
    notifyListeners();
  }

  void setTrackingStatus(bool connected) {
    _trackingConnected = connected;
    notifyListeners();
  }

  /// Sends user query to AI Wellness Coach with behavioral context
  Future<void> sendMessage({
    required String userQuery,
    required BehavioralFeatures features,
    required MlRiskPrediction prediction,
  }) async {
    final queryText = userQuery.trim();
    if (queryText.isEmpty) return;

    _messages.add(AiMessage.user(queryText));
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final responseText = await _genAiService.askCoach(
        userQuery: queryText,
        features: features,
        prediction: prediction,
      );

      _messages.add(AiMessage.assistant(
        responseText,
        isMock: _genAiService.useMockGenAI,
      ));
    } catch (e) {
      final errorMsg = e is StateError ? e.message : 'AI Coach is currently unavailable: $e';
      _errorMessage = errorMsg;
      _messages.add(AiMessage.error(errorMsg));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Generates tailored daily wellness plan
  Future<void> generateDailyPlan({
    required BehavioralFeatures features,
    required MlRiskPrediction prediction,
  }) async {
    await sendMessage(
      userQuery: 'Create my tailored digital wellness plan for tomorrow.',
      features: features,
      prediction: prediction,
    );
  }

  /// Generates weekly AI report
  Future<void> generateWeeklyReport({
    required List<DailyUsage> history,
    required BehavioralFeatures latestFeatures,
    required MlRiskPrediction latestPrediction,
  }) async {
    await sendMessage(
      userQuery: 'Generate my Weekly AI Digital Wellbeing Report.',
      features: latestFeatures,
      prediction: latestPrediction,
    );
  }

  /// Returns rule-based and behavioral recommendations for instant UI display
  List<WellbeingRecommendation> getRecommendations(BehavioralFeatures features, MlRiskPrediction prediction) {
    return _genAiService.getPersonalizedRecommendations(features: features, prediction: prediction);
  }

  /// Clears chat history
  void clearMessages() {
    _messages.clear();
    _errorMessage = null;
    notifyListeners();
  }
}
