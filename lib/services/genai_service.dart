import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../models/app_category.dart';
import '../models/behavioral_features.dart';
import '../models/daily_usage.dart';
import '../models/recommendation_model.dart';
import '../models/risk_model.dart';

/// Generative AI Service for HabitGuard Digital Wellbeing Coach.
/// Connects to Google Gemini API (using gemini-1.5-flash) and injects actual behavioral context.
class GenAiService {
  static final GenAiService _instance = GenAiService._internal();
  factory GenAiService() => _instance;
  GenAiService._internal();

  String? _apiKey;
  bool _useMockGenAI = false;

  bool get isConfigured => _apiKey != null && _apiKey!.trim().isNotEmpty;
  bool get useMockGenAI => _useMockGenAI;

  Future<void> init() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _apiKey = prefs.getString(AppConstants.prefKeyGenAiKey);
      _useMockGenAI = prefs.getBool(AppConstants.prefKeyUseMockGenAI) ?? false;
    } catch (e) {
      debugPrint('GenAiService init notice: $e');
    }
  }

  Future<void> setApiKey(String key) async {
    _apiKey = key.trim();
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(AppConstants.prefKeyGenAiKey, _apiKey!);
  }

  Future<void> setUseMockGenAI(bool value) async {
    _useMockGenAI = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefKeyUseMockGenAI, value);
  }

  /// Builds structured behavioral context for Gemini prompt injection
  String _buildBehavioralContext(BehavioralFeatures features, MlRiskPrediction prediction) {
    final topFactorsStr = prediction.riskFactors.map((f) => '- ${f.factor} (${f.impact}): ${f.description}').join('\n');

    return '''
ACTUAL USER USAGE METRICS:
- Today's Total Screen Time: ${features.totalScreenTime ~/ 60}h ${features.totalScreenTime % 60}m (${features.totalScreenTime} minutes)
- Social Media Time: ${features.socialMediaTime ~/ 60}h ${features.socialMediaTime % 60}m (${features.socialMediaPercentage.toStringAsFixed(1)}%)
- Gaming Time: ${features.gamingTime ~/ 60}h ${features.gamingTime % 60}m (${features.gamingPercentage.toStringAsFixed(1)}%)
- Entertainment / Streaming Time: ${features.entertainmentTime ~/ 60}h ${features.entertainmentTime % 60}m (${features.entertainmentPercentage.toStringAsFixed(1)}%)
- Educational Time: ${features.educationTime} minutes
- Productivity Time: ${features.productivityTime} minutes
- Productive Ratio: ${features.productiveUsagePercentage.toStringAsFixed(1)}%
- Late-Night Phone Usage (past 11 PM): ${features.lateNightUsage} minutes
- Early Morning Usage (before 7 AM): ${features.earlyMorningUsage} minutes
- Total Phone Sessions / Unlocks: ${features.numberOfAppSessions}
- Average Session Length: ${features.averageSessionDuration.toStringAsFixed(1)} minutes
- 7-Day Average Screen Time: ${features.sevenDayAverageScreenTime.round() ~/ 60}h ${features.sevenDayAverageScreenTime.round() % 60}m
- Screen Time Change vs Baseline: ${features.dailyUsageChangePercentage > 0 ? '+' : ''}${features.dailyUsageChangePercentage.toStringAsFixed(1)}%
- Most Used App: ${features.mostUsedApplication}
- Most Used Category: ${features.mostUsedCategory}
- Current ML Risk Score: ${prediction.riskScore} / 100 (${prediction.riskLevel.label})
- Longitudinal Risk Trend: ${prediction.trend}
- Top Contributory Risk Factors:
$topFactorsStr
''';
  }

  /// Sends contextual query to Gemini API
  Future<String> askCoach({
    required String userQuery,
    required BehavioralFeatures features,
    required MlRiskPrediction prediction,
  }) async {
    // 1. Mock GenAI Mode (Explicit Development Setting)
    if (_useMockGenAI) {
      return _generateMockCoachResponse(userQuery, features, prediction);
    }

    // 2. Real GenAI Mode: Validate API key
    if (!isConfigured) {
      throw StateError(
        'AI Coach is currently unavailable. Generative AI API key is not configured.\n'
        'You can configure your GEMINI_API_KEY in Profile > Settings or enable Development Mock Mode.',
      );
    }

    try {
      final context = _buildBehavioralContext(features, prediction);
      final systemInstruction =
          'You are HabitGuard AI, an empathetic, evidence-based digital wellbeing coach. '
          'You help the user understand their smartphone habits and offer constructive, achievable changes. '
          'CRITICAL RULE: You MUST cite the user\'s real metrics from the provided context (e.g. their exact screen time, '
          'late-night minutes, social media duration). NEVER invent numbers or hallucinate statistics. '
          'Keep your tone encouraging, concise, and focused on behavioral improvement. Never give medical diagnoses.';

      final prompt = '$systemInstruction\n\n$context\n\nUSER QUESTION: "$userQuery"\n\nCOACH RESPONSE:';

      final endpoint =
          'https://generativelanguage.googleapis.com/v1beta/models/gemini-1.5-flash:generateContent?key=$_apiKey';

      final response = await http.post(
        Uri.parse(endpoint),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'contents': [
            {
              'parts': [
                {'text': prompt}
              ]
            }
          ],
          'generationConfig': {
            'temperature': 0.7,
            'maxOutputTokens': 500,
          }
        }),
      ).timeout(const Duration(seconds: 12));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final candidates = data['candidates'] as List<dynamic>?;
        if (candidates != null && candidates.isNotEmpty) {
          final content = candidates[0]['content'];
          final parts = content['parts'] as List<dynamic>?;
          if (parts != null && parts.isNotEmpty) {
            return parts[0]['text'] as String? ?? 'I reviewed your habits, but could not formulate a response.';
          }
        }
        return 'No response was generated by the AI model.';
      } else {
        throw Exception('Gemini API returned status ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      debugPrint('GenAI request error: $e');
      rethrow;
    }
  }

  /// Generates a Personalized Daily Wellness Plan grounded in actual metrics
  Future<String> generateDailyPlan({
    required BehavioralFeatures features,
    required MlRiskPrediction prediction,
  }) async {
    const prompt = 'Create a tailored, 4-step digital wellness action plan for tomorrow based on my usage metrics.';
    return askCoach(userQuery: prompt, features: features, prediction: prediction);
  }

  /// Generates a Weekly AI Digital Wellbeing Summary
  Future<String> generateWeeklySummary({
    required List<DailyUsage> history,
    required BehavioralFeatures latestFeatures,
    required MlRiskPrediction latestPrediction,
  }) async {
    final prompt =
        'Synthesize a concise Weekly AI Digital Wellbeing Report analyzing my usage trend, peak habits, and biggest improvement opportunity.';
    return askCoach(userQuery: prompt, features: latestFeatures, prediction: latestPrediction);
  }

  /// Extracts personalized recommendations grounded in dominant risk category
  List<WellbeingRecommendation> getPersonalizedRecommendations({
    required BehavioralFeatures features,
    required MlRiskPrediction prediction,
  }) {
    final recommendations = <WellbeingRecommendation>[];

    // Check dominant behavioral contributors
    if (features.lateNightUsage >= 30) {
      recommendations.add(WellbeingRecommendation(
        id: 'rec_late_night',
        title: 'Curfew for Late-Night Usage',
        description: 'You spent ${features.lateNightUsage} minutes on your phone late at night, which impairs REM sleep.',
        suggestedGoal: 'Enable Bedtime Mode and avoid entertainment apps between 11 PM and 7 AM.',
        targetCategory: AppCategory.entertainment,
        impactLevel: 'HIGH',
      ));
    }

    if (features.socialMediaPercentage >= 35.0 || features.socialMediaTime >= 90) {
      final reductionTarget = (features.socialMediaTime * 0.25).round().clamp(15, 60);
      recommendations.add(WellbeingRecommendation(
        id: 'rec_social_media',
        title: 'Social Media Boundary',
        description: 'Social media comprises ${features.socialMediaPercentage.toStringAsFixed(0)}% of your screen time today (${features.socialMediaTime}m).',
        suggestedGoal: 'Reduce social media usage by $reductionTarget minutes tomorrow and disable non-urgent push notifications.',
        targetCategory: AppCategory.socialMedia,
        impactLevel: 'HIGH',
      ));
    }

    if (features.gamingTime >= 60) {
      recommendations.add(WellbeingRecommendation(
        id: 'rec_gaming',
        title: 'Break Up Gaming Sessions',
        description: 'Gaming accounted for ${features.gamingTime} minutes of continuous screen immersion.',
        suggestedGoal: 'Cap single gaming sessions at 30 minutes and take a 10-minute physical break between games.',
        targetCategory: AppCategory.gaming,
        impactLevel: 'MEDIUM',
      ));
    }

    if (features.numberOfAppSessions >= 45) {
      recommendations.add(WellbeingRecommendation(
        id: 'rec_sessions',
        title: 'Batch Digital Checking',
        description: 'You unlocked or switched applications ${features.numberOfAppSessions} times today (avg ${features.averageSessionDuration.toStringAsFixed(1)}m per check).',
        suggestedGoal: 'Practice mindful checking by batching notifications every 60 minutes instead of answering instantly.',
        targetCategory: AppCategory.communication,
        impactLevel: 'MEDIUM',
      ));
    }

    if (recommendations.isEmpty) {
      recommendations.add(const WellbeingRecommendation(
        id: 'rec_balanced',
        title: 'Sustain Balanced Habits',
        description: 'Your screen time and category allocations remain healthy and constructive.',
        suggestedGoal: 'Maintain your current daily routine and continue prioritizing offline activities.',
        targetCategory: AppCategory.productivity,
        impactLevel: 'LOW',
      ));
    }

    return recommendations;
  }

  /// Controlled mock response for development mode
  String _generateMockCoachResponse(
    String userQuery,
    BehavioralFeatures features,
    MlRiskPrediction prediction,
  ) {
    final lowerQuery = userQuery.toLowerCase();
    final totalHours = features.totalScreenTime ~/ 60;
    final totalMins = features.totalScreenTime % 60;

    if (lowerQuery.contains('why') && lowerQuery.contains('risk')) {
      return '[DEVELOPMENT MOCK]\n'
          'Your current risk is ${prediction.riskLevel.label} (Score: ${prediction.riskScore}/100) mainly because '
          'your social media usage (${features.socialMediaTime}m, ${features.socialMediaPercentage.toStringAsFixed(0)}% of total) '
          'and late-night phone usage (${features.lateNightUsage}m) exceed healthy guidelines.\n\n'
          'Today\'s total screen time is ${totalHours}h ${totalMins}m across ${features.numberOfAppSessions} sessions. '
          'A constructive starting point is reducing social media by 30 minutes tomorrow and turning off screens 45 minutes before sleep.';
    } else if (lowerQuery.contains('plan') || lowerQuery.contains('tomorrow')) {
      return '[DEVELOPMENT MOCK]\n'
          'YOUR WELLBEING PLAN FOR TOMORROW:\n'
          '1. Reduce social media by 25 minutes (currently ${features.socialMediaTime}m).\n'
          '2. Establish a digital wind-down buffer after 11 PM to prevent late-night checks (${features.lateNightUsage}m today).\n'
          '3. Batch notifications to reduce phone pickups (currently ${features.numberOfAppSessions} sessions).\n'
          '4. Dedicate at least 45 minutes to educational or productive tasks.';
    } else if (lowerQuery.contains('reduce') || lowerQuery.contains('screen time')) {
      return '[DEVELOPMENT MOCK]\n'
          'To reduce your ${totalHours}h ${totalMins}m screen time effectively:\n'
          '• Focus first on ${features.mostUsedCategory.toLowerCase()} apps (${features.mostUsedApplication} was your top app today).\n'
          '• Set an app timer of ${(features.socialMediaTime * 0.8).round()} minutes on your most-used entertainment app.\n'
          '• Keep your phone in another room while sleeping to eliminate ${features.lateNightUsage}m of late-night use.';
    } else if (lowerQuery.contains('weekly') || lowerQuery.contains('trend')) {
      return '[DEVELOPMENT MOCK]\n'
          'WEEKLY HABIT SUMMARY:\n'
          'Your current risk trend is ${prediction.trend}. Your 7-day average is ${features.sevenDayAverageScreenTime.round() ~/ 60}h '
          '${features.sevenDayAverageScreenTime.round() % 60}m. Your day-over-day change was '
          '${features.dailyUsageChangePercentage > 0 ? '+' : ''}${features.dailyUsageChangePercentage.toStringAsFixed(1)}%. '
          'Staying consistent with night curfews will stabilize your trend.';
    } else {
      return '[DEVELOPMENT MOCK]\n'
          'Analyzing your usage of ${totalHours}h ${totalMins}m today: You had ${features.numberOfAppSessions} sessions with '
          '${features.lateNightUsage}m spent late at night. Maintaining regular breaks every 45 minutes and setting bedtime boundaries '
          'will significantly improve your digital wellbeing score.';
    }
  }
}
