import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/time_formatter.dart';
import '../models/risk_assessment.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';
import 'notification_service.dart';
import 'sms_service.dart';

/// Service responsible for managing high-risk detection, 24h cooldown deduplication,
/// and triggering guardian alerts via the backend notification architecture.
class GuardianAlertService {
  final FirestoreService _firestoreService = FirestoreService();
  final NotificationService _notificationService = NotificationService();

  /// Evaluates risk score, verifies user preferences and cooldown, and dispatches alerts.
  Future<bool> evaluateAndDispatchAlert({
    required UserModel user,
    required RiskAssessment assessment,
    required int totalScreenMinutes,
  }) async {
    // 1. Check if score qualifies for High-Risk alert (>= 61)
    if (assessment.score < AppConstants.riskThresholdHighAlert) {
      return false;
    }

    // 2. Check if user enabled high-risk alerts and has configured a guardian
    if (!user.notificationEnabled ||
        user.guardianMobile == null ||
        user.guardianMobile!.trim().isEmpty) {
      debugPrint('Guardian notification skipped: user disabled alerts or guardian mobile is missing.');
      return false;
    }

    // 3. Check 24-Hour Alert Cooldown Deduplication
    final bool canSend = await _checkCooldownAndMarkSent(assessment.score >= 81);
    if (!canSend) {
      debugPrint('Guardian notification skipped: 24h alert cooldown is currently active.');
      return false;
    }

    // 4. Send Local High-Risk Push Notification to User Device
    await _notificationService.showHighRiskLocalNotification(
      score: assessment.score,
      totalMinutes: totalScreenMinutes,
      riskLevel: assessment.level.label,
    );

    // 5. Dispatch Alert Payload via Backend Architecture (Firestore Alert Queue)
    final formattedDuration = TimeFormatter.formatMinutes(totalScreenMinutes);
    final alertPayload = {
      'uid': user.uid,
      'userName': user.name,
      'guardianName': user.guardianName ?? 'Guardian',
      'guardianMobile': user.formattedGuardianMobile,
      'riskScore': assessment.score,
      'riskLevel': assessment.level.label,
      'totalScreenTime': formattedDuration,
      'topCategory': assessment.topCategory.displayName,
      'message': 'HabitGuard Alert: ${user.name}\'s digital addiction risk score is currently ${assessment.level.label} '
          '(Score: ${assessment.score}/100, Screen Time: $formattedDuration). Please check in with them.',
      'status': 'PENDING_DISPATCH',
    };

    await _firestoreService.logGuardianAlert(user.uid, alertPayload);

    // 6. Simulate / Trigger backend SMS provider dispatcher
    _dispatchToSmsProvider(alertPayload);

    return true;
  }

  /// Dispatches direct high-risk alert SMS to guardian mobile via native SMS intent
  Future<bool> dispatchDirectGuardianAlertSms({
    required UserModel user,
    required RiskAssessment assessment,
    required int totalScreenMinutes,
  }) async {
    final formattedDuration = TimeFormatter.formatMinutes(totalScreenMinutes);
    return await SmsService.sendHighRiskGuardianAlert(
      guardianName: user.guardianName ?? 'Guardian',
      guardianMobile: user.formattedGuardianMobile,
      userName: user.name,
      riskScore: assessment.score,
      riskLevel: assessment.level.label,
      screenTime: formattedDuration,
    );
  }

  /// Verifies if 24 hours have passed since the last guardian alert.
  /// If [isCritical] is true, cooldown can be relaxed for emergency escalation.
  Future<bool> _checkCooldownAndMarkSent(bool isCritical) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final lastAlertStr = prefs.getString(AppConstants.prefKeyLastGuardianAlertDate);

      if (lastAlertStr != null) {
        final lastAlert = DateTime.tryParse(lastAlertStr);
        if (lastAlert != null) {
          final difference = DateTime.now().difference(lastAlert);
          if (difference < AppConstants.guardianAlertCooldown && !isCritical) {
            return false; // Cooldown active
          }
        }
      }

      // Record current timestamp
      await prefs.setString(
        AppConstants.prefKeyLastGuardianAlertDate,
        DateTime.now().toIso8601String(),
      );
      return true;
    } catch (e) {
      debugPrint('Error managing alert cooldown: $e');
      return true;
    }
  }

  /// Backend SMS Dispatcher interface.
  /// In production, Firebase Cloud Functions listen to Firestore alert logs or triggers Twilio/SMS API.
  void _dispatchToSmsProvider(Map<String, dynamic> payload) {
    debugPrint('==================================================');
    debugPrint('🔔 HABITGUARD GUARDIAN SMS DISPATCH TRIGGERED:');
    debugPrint('To: ${payload['guardianName']} (${payload['guardianMobile']})');
    debugPrint('Body: ${payload['message']}');
    debugPrint('==================================================');
  }
}
