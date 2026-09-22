import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../models/risk_assessment.dart';
import '../core/theme/app_theme.dart';
import '../services/sms_service.dart';

/// Banner displaying guardian protection status and student-controlled emergency high-risk alert triggers
class GuardianAlertBanner extends StatelessWidget {
  final UserModel? user;
  final RiskAssessment? assessment;
  final VoidCallback onConfigureTap;

  const GuardianAlertBanner({
    super.key,
    required this.user,
    required this.assessment,
    required this.onConfigureTap,
  });

  void _showSendAlertConfirmDialog(BuildContext context) {
    if (user == null || user!.guardianMobile == null || user!.guardianMobile!.isEmpty) {
      onConfigureTap();
      return;
    }

    final guardianName = user!.guardianName ?? 'Guardian';
    final guardianMobile = user!.formattedGuardianMobile;

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: RiskColors.critical),
            SizedBox(width: 8),
            Text('Notify Guardian'),
          ],
        ),
        content: Text(
          'Would you like to send a digital addiction wellbeing alert SMS to $guardianName ($guardianMobile)?',
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
                guardianName: guardianName,
                guardianMobile: guardianMobile,
                userName: user!.name,
                riskScore: assessment?.score ?? 75,
                riskLevel: assessment?.level.label ?? 'HIGH RISK',
                screenTime: '${assessment?.score ?? 75} Risk Points',
              );
            },
            icon: const Icon(Icons.send_rounded, size: 16),
            label: const Text('Send Alert SMS'),
            style: ElevatedButton.styleFrom(
              backgroundColor: RiskColors.critical,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isHighRisk = assessment?.isHighRisk ?? false;
    final hasGuardian = user?.guardianMobile != null && user!.guardianMobile!.isNotEmpty;

    if (isHighRisk && hasGuardian) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RiskColors.criticalLight.withAlpha(isDark ? 40 : 255),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RiskColors.critical.withAlpha(120), width: 1.5),
        ),
        child: Column(
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: const BoxDecoration(
                    color: RiskColors.critical,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'High Addiction Risk Detected (${assessment?.score ?? 0}/100)',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: RiskColors.critical,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Guardian: ${user?.guardianName ?? 'Parent'} (${user?.formattedGuardianMobile})',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark ? Colors.blueGrey.shade200 : const Color(0xFF7F1D1D),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              height: 38,
              child: ElevatedButton.icon(
                onPressed: () => _showSendAlertConfirmDialog(context),
                icon: const Icon(Icons.sms_outlined, size: 16),
                label: Text('Send Alert to ${user?.guardianName ?? 'Parent'}'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RiskColors.critical,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      );
    }

    if (!hasGuardian) {
      return Container(
        margin: const EdgeInsets.symmetric(vertical: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? Colors.indigo.shade800 : Colors.indigo.shade200,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.shield_outlined, color: AppTheme.primarySeed, size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Set Up Guardian Protection',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : const Color(0xFF1E1B4B),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Add a parent or guardian number to receive emergency wellbeing alerts.',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? Colors.blueGrey.shade300 : const Color(0xFF4338CA),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            TextButton(
              onPressed: onConfigureTap,
              style: TextButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                backgroundColor: AppTheme.primarySeed,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              child: const Text('Setup', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
