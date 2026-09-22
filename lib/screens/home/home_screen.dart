import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';
import '../../models/app_category.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../../providers/risk_provider.dart';
import '../../providers/usage_provider.dart';
import '../../widgets/app_usage_tile.dart';
import '../../widgets/category_usage_card.dart';
import '../../widgets/guardian_alert_banner.dart';
import '../../widgets/risk_score_gauge.dart';
import '../ai_coach/ai_coach_screen.dart';
import '../onboarding/profile_setup_screen.dart';
import '../risk_details/risk_details_screen.dart';

/// Dashboard (Home) Screen displaying today's screen time, ML risk gauge, AI trend, categories, and top apps
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndPredict();
    });
  }

  Future<void> _initAndPredict() async {
    final usage = Provider.of<UsageProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final risk = Provider.of<RiskProvider>(context, listen: false);

    if (usage.todayFeatures != null) {
      await risk.predictRisk(features: usage.todayFeatures!, user: auth.user);
    }
  }

  Future<void> _handleRefresh() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final usage = Provider.of<UsageProvider>(context, listen: false);
    final risk = Provider.of<RiskProvider>(context, listen: false);
    final history = Provider.of<HistoryProvider>(context, listen: false);

    await usage.fetchTodayUsage(auth.user?.uid);
    if (auth.user != null) {
      await history.fetchHistory(auth.user!.uid);
    }
    if (usage.todayFeatures != null) {
      await risk.predictRisk(features: usage.todayFeatures!, user: auth.user);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final usage = Provider.of<UsageProvider>(context);
    final risk = Provider.of<RiskProvider>(context);
    final history = Provider.of<HistoryProvider>(context);

    final daily = usage.todayDailyUsage;
    final assessment = usage.currentAssessment;
    final prediction = risk.currentPrediction;
    final topApps = daily?.getTopApplications(4) ?? [];
    final totalMinutes = daily?.totalScreenTimeMinutes ?? 0;

    // Use ML prediction score/level if available, otherwise rule-based assessment
    final displayScore = prediction?.riskScore ?? assessment?.score ?? 0;
    final displayLevel = prediction?.riskLevel ?? assessment?.level;
    final trend = prediction?.trend ?? usage.todayFeatures?.sevenDayRiskTrend ?? 'INSUFFICIENT_DATA';
    final isMock = usage.isMockMode || (prediction?.isMock ?? false);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${TimeFormatter.getGreeting()}, ${auth.user?.name.split(' ').first ?? 'User'}!',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              TimeFormatter.formatDate(DateTime.now()),
              style: TextStyle(
                fontSize: 12,
                color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
              ),
            ),
          ],
        ),
        actions: [
          if (isMock)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF6366F1).withAlpha(isDark ? 40 : 25),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF6366F1)),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.developer_mode, size: 14, color: Color(0xFF6366F1)),
                  SizedBox(width: 4),
                  Text('MOCK', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, color: Color(0xFF6366F1))),
                ],
              ),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _handleRefresh,
        child: usage.isLoading && daily == null
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Guardian Alert Status Banner
                    GuardianAlertBanner(
                      user: auth.user,
                      assessment: assessment,
                      onConfigureTap: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
                        );
                      },
                    ),
                    const SizedBox(height: 12),

                    // First-Day / Insufficient History Banner if appropriate
                    if (history.history.length < 2 && !isMock)
                      Container(
                        margin: const EdgeInsets.only(bottom: 14),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF1E293B) : Colors.blue.shade50,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: Colors.blue.shade200),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline_rounded, color: Colors.blue, size: 22),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Building Your Digital Profile',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'HabitGuard needs a few days of usage data to establish your personal behavioral baseline. Predictions will become more reliable over time.',
                                    style: TextStyle(fontSize: 11, color: isDark ? Colors.blueGrey.shade300 : Colors.blue.shade900),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),

                    // Risk Score & Screen Time Main Card
                    Card(
                      elevation: 0,
                      color: isDark ? const Color(0xFF1E293B) : Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(24),
                        side: BorderSide(
                          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
                        ),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      "TODAY'S SCREEN TIME",
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        letterSpacing: 1.0,
                                        color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      daily?.formattedTotalTime ?? '0m',
                                      style: TextStyle(
                                        fontSize: 28,
                                        fontWeight: FontWeight.w900,
                                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                                        letterSpacing: -0.5,
                                      ),
                                    ),
                                  ],
                                ),
                                IconButton(
                                  icon: const Icon(Icons.info_outline_rounded),
                                  tooltip: 'Risk Score Details',
                                  onPressed: () {
                                    if (daily != null && assessment != null) {
                                      Navigator.of(context).push(
                                        MaterialPageRoute(
                                          builder: (_) => RiskDetailsScreen(
                                            dailyUsage: daily,
                                            assessment: assessment,
                                          ),
                                        ),
                                      );
                                    }
                                  },
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),

                            // Circular Risk Gauge
                            if (displayLevel != null)
                              RiskScoreGauge(
                                score: displayScore,
                                level: displayLevel,
                                onTap: () {
                                  if (daily != null && assessment != null) {
                                    Navigator.of(context).push(
                                      MaterialPageRoute(
                                        builder: (_) => RiskDetailsScreen(
                                          dailyUsage: daily,
                                          assessment: assessment,
                                        ),
                                      ),
                                    );
                                  }
                                },
                              ),
                            const SizedBox(height: 12),

                            // AI Predictive Trend Badge
                            _buildTrendBadge(trend, isDark),
                            const SizedBox(height: 10),

                            // Tap to view full assessment prompt
                            TextButton.icon(
                              onPressed: () {
                                if (daily != null && assessment != null) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => RiskDetailsScreen(
                                        dailyUsage: daily,
                                        assessment: assessment,
                                      ),
                                    ),
                                  );
                                }
                              },
                              icon: const Icon(Icons.analytics_outlined, size: 18),
                              label: const Text('View Full Risk Analysis & AI Tips'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Quick AI Wellness Coach Shortcut Card
                    _buildAiCoachCard(context, isDark),
                    const SizedBox(height: 24),

                    // Section: Category Screen Time
                    Text(
                      'Category Breakdown',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (daily != null) ...[
                      CategoryUsageCard(
                        category: AppCategory.socialMedia,
                        minutes: daily.socialMediaTime,
                        totalScreenMinutes: totalMinutes,
                      ),
                      CategoryUsageCard(
                        category: AppCategory.gaming,
                        minutes: daily.gamingTime,
                        totalScreenMinutes: totalMinutes,
                      ),
                      CategoryUsageCard(
                        category: AppCategory.entertainment,
                        minutes: daily.entertainmentTime,
                        totalScreenMinutes: totalMinutes,
                      ),
                      CategoryUsageCard(
                        category: AppCategory.education,
                        minutes: daily.educationTime,
                        totalScreenMinutes: totalMinutes,
                      ),
                      CategoryUsageCard(
                        category: AppCategory.productivity,
                        minutes: daily.productivityTime,
                        totalScreenMinutes: totalMinutes,
                      ),
                      CategoryUsageCard(
                        category: AppCategory.communication,
                        minutes: daily.communicationTime,
                        totalScreenMinutes: totalMinutes,
                      ),
                      CategoryUsageCard(
                        category: AppCategory.other,
                        minutes: daily.otherTime,
                        totalScreenMinutes: totalMinutes,
                      ),
                    ],
                    const SizedBox(height: 24),

                    // Section: Most Used Applications
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Most Used Applications',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                        Text(
                          'Top ${topApps.length}',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
                        ),
                      ),
                      child: topApps.isEmpty
                          ? const Padding(
                              padding: EdgeInsets.all(16),
                              child: Center(child: Text('No application usage tracked yet today.')),
                            )
                          : ListView.separated(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: topApps.length,
                              separatorBuilder: (_, _) => Divider(
                                height: 12,
                                color: isDark
                                    ? Colors.blueGrey.shade800.withAlpha(60)
                                    : Colors.blueGrey.shade100,
                              ),
                              itemBuilder: (context, index) {
                                return AppUsageTile(
                                  app: topApps[index],
                                  rank: index + 1,
                                );
                              },
                            ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
      ),
    );
  }

  Widget _buildTrendBadge(String trend, bool isDark) {
    IconData icon = Icons.trending_flat_rounded;
    Color color = Colors.grey;
    String label = 'AI Trend: Stable';

    if (trend == 'INCREASING') {
      icon = Icons.trending_up_rounded;
      color = Colors.red;
      label = 'AI Risk Trend: ↑ Increasing';
    } else if (trend == 'DECREASING') {
      icon = Icons.trending_down_rounded;
      color = Colors.green;
      label = 'AI Risk Trend: ↓ Decreasing';
    } else if (trend == 'INSUFFICIENT_DATA') {
      icon = Icons.insights_rounded;
      color = Colors.blueGrey;
      label = 'AI Trend: Profiling in progress';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
      decoration: BoxDecoration(
        color: color.withAlpha(isDark ? 40 : 25),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _buildAiCoachCard(BuildContext context, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E293B), const Color(0xFF192231)]
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
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primarySeed.withAlpha(isDark ? 45 : 30),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.psychology_rounded, color: AppTheme.primarySeed, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'AI Wellness Coach',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(
                  'Ask about your risk factors or get a personalized action plan.',
                  style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
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
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Open Coach', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
  }
}
