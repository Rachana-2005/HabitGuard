import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/time_formatter.dart';
import '../../models/app_category.dart';
import '../../models/daily_usage.dart';
import '../../models/risk_assessment.dart';
import '../../providers/auth_provider.dart';
import '../../providers/history_provider.dart';
import '../risk_details/risk_details_screen.dart';

/// History Screen displaying historical daily usage and addiction risk logs
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final history = Provider.of<HistoryProvider>(context, listen: false);
      history.fetchHistory(auth.user?.uid ?? 'guest', days: 7);
    });
  }

  void _showDayDetails(DailyUsage day) {
    final assessment = RiskAssessment(
      score: day.riskScore,
      level: day.riskLevel,
      topCategory: day.applications.isNotEmpty ? day.applications.first.category : AppCategory.other,
      categoryMinutes: day.categoryBreakdown,
      recommendations: [
        'Recorded screen time for ${day.date}: ${day.formattedTotalTime}.',
        'Top dopamine category: ${day.socialMediaTime > day.gamingTime ? "Social Media" : "Gaming"}.',
      ],
      assessmentDate: day.createdAt,
    );

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => RiskDetailsScreen(
          dailyUsage: day,
          assessment: assessment,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final history = Provider.of<HistoryProvider>(context);

    final list = history.history;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Usage History'),
      ),
      body: Column(
        children: [
          // Timeframe Filter Chips
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                _buildFilterChip('7 Days', 7, history, auth.user?.uid, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('14 Days', 14, history, auth.user?.uid, isDark),
                const SizedBox(width: 8),
                _buildFilterChip('30 Days', 30, history, auth.user?.uid, isDark),
              ],
            ),
          ),

          // KPI Aggregate Highlights
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVG SCREEN TIME',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          TimeFormatter.formatMinutes(history.averageScreenTimeMinutes.round()),
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 36,
                    color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'AVG RISK SCORE',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                            color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            Text(
                              '${history.averageRiskScore.round()}',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.w900,
                                color: RiskColors.getColorForScore(history.averageRiskScore.round()),
                              ),
                            ),
                            Text(
                              ' / 100',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.blueGrey.shade400 : Colors.blueGrey.shade500,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 8),

          // Daily Records List
          Expanded(
            child: history.isLoading
                ? const Center(child: CircularProgressIndicator())
                : list.isEmpty
                    ? const Center(child: Text('No historical logs found'))
                    : ListView.builder(
                        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        itemCount: list.length,
                        itemBuilder: (context, index) {
                          final item = list[index];
                          final parsedDate = DateTime.tryParse(item.date) ?? item.createdAt;

                          return Card(
                            margin: const EdgeInsets.symmetric(vertical: 6),
                            elevation: 0,
                            color: isDark ? const Color(0xFF1E293B) : Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                              side: BorderSide(
                                color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
                              ),
                            ),
                            child: InkWell(
                              onTap: () => _showDayDetails(item),
                              borderRadius: BorderRadius.circular(18),
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Row(
                                  children: [
                                    // Risk Score Pill Indicator
                                    Container(
                                      width: 48,
                                      height: 48,
                                      alignment: Alignment.center,
                                      decoration: BoxDecoration(
                                        color: item.riskLevel.lightColor.withAlpha(isDark ? 40 : 255),
                                        borderRadius: BorderRadius.circular(14),
                                        border: Border.all(
                                          color: item.riskLevel.color.withAlpha(120),
                                        ),
                                      ),
                                      child: Text(
                                        '${item.riskScore}',
                                        style: TextStyle(
                                          fontSize: 18,
                                          fontWeight: FontWeight.w900,
                                          color: item.riskLevel.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),

                                    // Date and Details
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            TimeFormatter.formatDate(parsedDate),
                                            style: TextStyle(
                                              fontSize: 15,
                                              fontWeight: FontWeight.w700,
                                              color: isDark ? Colors.white : const Color(0xFF0F172A),
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            'Screen Time: ${item.formattedTotalTime}',
                                            style: TextStyle(
                                              fontSize: 13,
                                              color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),

                                    // Status Badge
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: item.riskLevel.color.withAlpha(isDark ? 40 : 25),
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Text(
                                        item.riskLevel.label,
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w800,
                                          color: item.riskLevel.color,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Icon(
                                      Icons.chevron_right_rounded,
                                      color: isDark ? Colors.blueGrey.shade600 : Colors.blueGrey.shade300,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, int days, HistoryProvider provider, String? uid, bool isDark) {
    final isSelected = provider.selectedDays == days;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) {
        provider.setTimeframe(uid ?? 'guest', days);
      },
      selectedColor: AppTheme.primarySeed,
      labelStyle: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isSelected ? Colors.white : (isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700),
      ),
    );
  }
}
