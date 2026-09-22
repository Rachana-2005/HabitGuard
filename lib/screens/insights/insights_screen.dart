import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/ai_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/risk_provider.dart';
import '../../providers/usage_provider.dart';
import '../../widgets/charts/category_pie_chart.dart';
import '../../widgets/charts/risk_trend_chart.dart';
import '../../widgets/charts/usage_bar_chart.dart';
import '../ai_coach/ai_coach_screen.dart';

/// Comprehensive AI Insights & Explainable AI Screen
class InsightsScreen extends StatelessWidget {
  const InsightsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final history = Provider.of<HistoryProvider>(context);
    final usage = Provider.of<UsageProvider>(context);
    final risk = Provider.of<RiskProvider>(context);
    final ai = Provider.of<AiProvider>(context);

    final historyList = history.history;
    final categoryTotals = history.categoryTimeTotals;
    final prediction = risk.currentPrediction;
    final features = usage.todayFeatures;

    return Scaffold(
      appBar: AppBar(
        title: const Text('AI Insights & Analytics'),
        actions: [
          TextButton.icon(
            icon: const Icon(Icons.auto_awesome_rounded, size: 16, color: AppTheme.primarySeed),
            label: const Text('Ask AI Coach', style: TextStyle(fontWeight: FontWeight.bold)),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiCoachScreen()),
              );
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section 1: Machine Learning Risk Prediction Summary
            _buildMlPredictionCard(context, prediction, isDark),
            const SizedBox(height: 24),

            // Section 2: Explainable AI — "Why Your Risk is [Level]"
            if (prediction != null && prediction.riskFactors.isNotEmpty) ...[
              _buildSectionHeader('Explainable AI — Risk Factor Attribution', Icons.psychology_rounded, isDark),
              const SizedBox(height: 10),
              _buildExplainableAiCard(prediction, isDark),
              const SizedBox(height: 24),
            ],

            // Section 3: Behavioral Analysis Metrics
            if (features != null) ...[
              _buildSectionHeader('Behavioral Habit Analysis', Icons.analytics_outlined, isDark),
              const SizedBox(height: 10),
              _buildBehavioralAnalysisCard(features, isDark),
              const SizedBox(height: 24),
            ],

            // Section 4: Screen Time Trend (Hours)
            _buildSectionHeader('Screen Time Trend (Hours)', Icons.bar_chart_rounded, isDark),
            const SizedBox(height: 10),
            _buildChartCard(
              child: UsageBarChart(dailyList: historyList),
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Section 5: Risk Trajectory Line Chart
            _buildSectionHeader('Digital Addiction Risk Trajectory (0 - 100)', Icons.show_chart_rounded, isDark),
            const SizedBox(height: 10),
            _buildChartCard(
              child: Column(
                children: [
                  RiskTrendChart(dailyList: historyList),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildZoneLegend('0-30 Low', RiskColors.low),
                      _buildZoneLegend('31-60 Mod', RiskColors.moderate),
                      _buildZoneLegend('61-80 High', RiskColors.high),
                      _buildZoneLegend('81+ Crit', RiskColors.critical),
                    ],
                  ),
                ],
              ),
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Section 6: Category Distribution
            _buildSectionHeader('Category Usage Breakdown', Icons.pie_chart_outline_rounded, isDark),
            const SizedBox(height: 10),
            _buildChartCard(
              child: CategoryPieChart(categoryTotals: categoryTotals),
              isDark: isDark,
            ),
            const SizedBox(height: 24),

            // Section 7: Personalized Recommendations
            _buildSectionHeader('Personalized AI Recommendations', Icons.lightbulb_outline_rounded, isDark),
            const SizedBox(height: 10),
            if (features != null && prediction != null)
              ...ai.getRecommendations(features, prediction).map((rec) {
                return _buildRecommendationCard(rec, isDark);
              })
            else if (usage.currentAssessment != null)
              ...usage.currentAssessment!.recommendations.map((rec) {
                return _buildSimpleRecCard(rec, isDark);
              }),
            const SizedBox(height: 20),

            // Section 8: Weekly AI Report Trigger Card
            _buildWeeklyReportCard(context, historyList, features, prediction, isDark),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildMlPredictionCard(BuildContext context, dynamic prediction, bool isDark) {
    if (prediction == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : Colors.white,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Row(
          children: [
            CircularProgressIndicator(strokeWidth: 2),
            SizedBox(width: 16),
            Expanded(child: Text('Calculating Machine Learning Risk Prediction...')),
          ],
        ),
      );
    }

    final isUnavailable = prediction.errorMessage != null && prediction.errorMessage!.isNotEmpty;
    if (isUnavailable) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2C1E1E) : Colors.amber.shade50,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.amber.shade300),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.cloud_off_rounded, color: Colors.amber, size: 22),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    prediction.errorMessage!,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Your raw Android screen time statistics are displayed below. Start the Python ML backend or enable Mock ML in Profile to view live predictions.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      );
    }

    final score = prediction.riskScore;
    final level = prediction.riskLevel;
    final confidence = (prediction.confidence * 100).round();
    final isMock = prediction.isMock;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: level.color.withAlpha(isDark ? 45 : 30),
                      shape: BoxShape.circle,
                    ),
                    child: Icon(Icons.memory_rounded, color: level.color, size: 20),
                  ),
                  const SizedBox(width: 10),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'ML Risk Prediction',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        'Model: Random Forest Classifier ${isMock ? "[Mock]" : ""}',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: level.color,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  level.label,
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetric('Risk Score', '$score / 100', level.color),
              _buildMetric('Confidence', '$confidence%', isDark ? Colors.white : Colors.black87),
              _buildMetric('Trend', prediction.trend, AppTheme.primarySeed),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildExplainableAiCard(dynamic prediction, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'WHY YOUR RISK IS ${prediction.riskLevel.label}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.5,
              color: prediction.riskLevel.color,
            ),
          ),
          const SizedBox(height: 12),
          ...prediction.riskFactors.map<Widget>((factor) {
            final color = factor.color;
            return Container(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark ? Colors.black26 : Colors.blueGrey.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: color.withAlpha(isDark ? 45 : 30),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: color.withAlpha(100)),
                    ),
                    child: Text(
                      factor.impact,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          factor.factor,
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                        ),
                        if (factor.description.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            factor.description,
                            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildBehavioralAnalysisCard(dynamic features, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildAnalysisTile(
                  'Late Night Usage',
                  '${features.lateNightUsage}m',
                  features.lateNightUsage >= 30 ? Colors.red : Colors.green,
                  Icons.bedtime_outlined,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalysisTile(
                  'App Sessions',
                  '${features.numberOfAppSessions}',
                  AppTheme.primarySeed,
                  Icons.touch_app_outlined,
                  isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildAnalysisTile(
                  'Productive Ratio',
                  '${features.productiveUsagePercentage.toStringAsFixed(1)}%',
                  Colors.teal,
                  Icons.school_outlined,
                  isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAnalysisTile(
                  '7-Day Average',
                  '${features.sevenDayAverageScreenTime.round() ~/ 60}h ${features.sevenDayAverageScreenTime.round() % 60}m',
                  Colors.blueGrey,
                  Icons.calendar_today_outlined,
                  isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAnalysisTile(String label, String value, Color color, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.black26 : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
                Text(value, style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRecommendationCard(dynamic rec, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppTheme.primarySeed.withAlpha(isDark ? 40 : 25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_awesome_rounded, color: AppTheme.primarySeed, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rec.title,
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(
                  rec.description,
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
                if (rec.suggestedGoal.isNotEmpty) ...[
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.primarySeed.withAlpha(isDark ? 30 : 15),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Goal: ${rec.suggestedGoal}',
                      style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppTheme.primarySeed),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleRecCard(String rec, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Text(rec, style: const TextStyle(fontSize: 13)),
    );
  }

  Widget _buildWeeklyReportCard(
    BuildContext context,
    List<dynamic> history,
    dynamic features,
    dynamic prediction,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF0F172A)]
              : [Colors.blueGrey.shade50, Colors.white],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppTheme.primarySeed.withAlpha(isDark ? 50 : 25),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.assessment_rounded, color: AppTheme.primarySeed, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Weekly AI Digital Wellbeing Report',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Synthesize a full behavioral report grounded in your past 7-day usage.',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          ElevatedButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const AiCoachScreen()),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.primarySeed,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            ),
            child: const Text('View Report', style: TextStyle(fontSize: 12)),
          ),
        ],
      ),
    );
  }

  Widget _buildMetric(String label, String value, Color color) {
    return Column(
      children: [
        Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppTheme.primarySeed),
        const SizedBox(width: 8),
        Text(
          title,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, letterSpacing: 0.2),
        ),
      ],
    );
  }

  Widget _buildChartCard({required Widget child, required bool isDark}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
        ),
      ),
      child: child,
    );
  }

  Widget _buildZoneLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: Colors.grey.shade600)),
      ],
    );
  }
}
