import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/daily_usage.dart';
import '../../models/risk_assessment.dart';
import '../../models/app_category.dart';
import '../../core/utils/time_formatter.dart';
import '../../providers/auth_provider.dart';
import '../../services/sms_service.dart';
import '../../widgets/risk_score_gauge.dart';

/// Detailed Risk Assessment Breakdown and Recommendations Screen
class RiskDetailsScreen extends StatelessWidget {
  final DailyUsage dailyUsage;
  final RiskAssessment assessment;

  const RiskDetailsScreen({
    super.key,
    required this.dailyUsage,
    required this.assessment,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Digital Wellbeing Score'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Risk Gauge Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: assessment.level.color.withAlpha(isDark ? 80 : 100),
                  width: 1.5,
                ),
              ),
              child: Column(
                children: [
                  RiskScoreGauge(
                    score: assessment.score,
                    level: assessment.level,
                    size: 210,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    assessment.level.summary,
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.4,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.blueGrey.shade200 : Colors.blueGrey.shade700,
                    ),
                  ),
                  const SizedBox(height: 14),
                  // Total Screen Time Badge
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.timer_outlined, size: 18),
                        const SizedBox(width: 6),
                        Text(
                          'Total Screen Time: ${dailyUsage.formattedTotalTime}',
                          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Category Breakdown
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Category Screen Time Breakdown',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
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
              child: Column(
                children: [
                  _buildCategoryRow(AppCategory.socialMedia, dailyUsage.socialMediaTime, isDark),
                  _buildDivider(isDark),
                  _buildCategoryRow(AppCategory.gaming, dailyUsage.gamingTime, isDark),
                  _buildDivider(isDark),
                  _buildCategoryRow(AppCategory.entertainment, dailyUsage.entertainmentTime, isDark),
                  _buildDivider(isDark),
                  _buildCategoryRow(AppCategory.education, dailyUsage.educationTime, isDark),
                  _buildDivider(isDark),
                  _buildCategoryRow(AppCategory.productivity, dailyUsage.productivityTime, isDark),
                  _buildDivider(isDark),
                  _buildCategoryRow(AppCategory.communication, dailyUsage.communicationTime, isDark),
                  _buildDivider(isDark),
                  _buildCategoryRow(AppCategory.other, dailyUsage.otherTime, isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section: Personalized AI Recommendations
            Align(
              alignment: Alignment.centerLeft,
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: Color(0xFF818CF8), size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Personalized Wellbeing Recommendations',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),

            ...assessment.recommendations.map((tip) {
              return Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF6366F1).withAlpha(isDark ? 40 : 25),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.lightbulb_outline_rounded, color: Color(0xFF6366F1), size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        tip,
                        style: TextStyle(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: isDark ? Colors.blueGrey.shade100 : const Color(0xFF334155),
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 20),

            // Optional User-Initiated Alert Button for High Risk
            if (assessment.isHighRisk) ...[
              Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  final user = auth.user;
                  if (user == null || user.guardianMobile == null || user.guardianMobile!.isEmpty) {
                    return const SizedBox.shrink();
                  }

                  return SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: const Text('Send Alert to Guardian'),
                            content: Text(
                              'Send a digital addiction alert message to ${user.guardianName ?? 'Guardian'} (${user.formattedGuardianMobile})?',
                            ),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: const Text('Cancel'),
                              ),
                              ElevatedButton.icon(
                                onPressed: () async {
                                  Navigator.of(ctx).pop();
                                  await SmsService.sendHighRiskGuardianAlert(
                                    guardianName: user.guardianName ?? 'Guardian',
                                    guardianMobile: user.formattedGuardianMobile,
                                    userName: user.name,
                                    riskScore: assessment.score,
                                    riskLevel: assessment.level.label,
                                    screenTime: dailyUsage.formattedTotalTime,
                                  );
                                },
                                icon: const Icon(Icons.send_rounded, size: 16),
                                label: const Text('Send SMS'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: assessment.level.color,
                                  foregroundColor: Colors.white,
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                      icon: const Icon(Icons.sms_outlined, size: 18),
                      label: Text('Notify ${user.guardianName ?? 'Guardian'} (${assessment.level.label})'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: assessment.level.color,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  );
                },
              ),
              const SizedBox(height: 24),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryRow(AppCategory category, int minutes, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: category.color.withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(category.icon, size: 18, color: category.color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              category.displayName,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white : const Color(0xFF1E293B),
              ),
            ),
          ),
          Text(
            TimeFormatter.formatMinutes(minutes),
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDivider(bool isDark) {
    return Divider(
      height: 1,
      color: isDark ? Colors.blueGrey.shade800.withAlpha(60) : Colors.blueGrey.shade100,
    );
  }
}
