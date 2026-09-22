import 'package:flutter/foundation.dart';
import 'package:url_launcher/url_launcher.dart';

/// Service for sending SMS messages to Guardian phone numbers via native SMS apps and intents
class SmsService {
  /// Opens the device's default SMS application with pre-filled recipient and message
  static Future<bool> sendSms({
    required String phoneNumber,
    required String message,
  }) async {
    try {
      final cleanNumber = phoneNumber.replaceAll(RegExp(r'[^\d+]'), '');
      
      // Standard SMS scheme
      final Uri smsUri = Uri(
        scheme: 'sms',
        path: cleanNumber,
        queryParameters: <String, String>{
          'body': message,
        },
      );

      if (await canLaunchUrl(smsUri)) {
        final success = await launchUrl(
          smsUri,
          mode: LaunchMode.externalApplication,
        );
        return success;
      } else {
        // Fallback for Android OEMs requiring encoded query string
        final fallbackUri = Uri.parse('sms:$cleanNumber?body=${Uri.encodeComponent(message)}');
        if (await canLaunchUrl(fallbackUri)) {
          final success = await launchUrl(
            fallbackUri,
            mode: LaunchMode.externalApplication,
          );
          return success;
        }
      }
      debugPrint('Could not launch native SMS for phone: $cleanNumber');
      return false;
    } catch (e) {
      debugPrint('Error launching SMS app: $e');
      return false;
    }
  }

  /// Sends a welcome / link notification message to the guardian upon registration
  static Future<bool> sendGuardianWelcomeNotification({
    required String guardianName,
    required String guardianMobile,
    required String userName,
  }) async {
    final cleanName = guardianName.trim().isEmpty ? 'Guardian' : guardianName.trim();
    final cleanUser = userName.trim().isEmpty ? 'Your family member' : userName.trim();
    
    final message = 'HabitGuard: Hi $cleanName, $cleanUser has registered your number as their Digital Wellbeing Guardian on HabitGuard. You will receive alerts if their smartphone addiction risk becomes high.';
    
    return await sendSms(phoneNumber: guardianMobile, message: message);
  }

  /// Sends a high-risk addiction alert message to the guardian
  static Future<bool> sendHighRiskGuardianAlert({
    required String guardianName,
    required String guardianMobile,
    required String userName,
    required int riskScore,
    required String riskLevel,
    required String screenTime,
  }) async {
    final cleanName = guardianName.trim().isEmpty ? 'Guardian' : guardianName.trim();
    final cleanUser = userName.trim().isEmpty ? 'HabitGuard User' : userName.trim();

    final message = '⚠️ HabitGuard Alert: Hi $cleanName, $cleanUser\'s smartphone addiction risk is currently $riskLevel (Score: $riskScore/100, Screen Time: $screenTime). Please check in with them to encourage a healthy digital break.';

    return await sendSms(phoneNumber: guardianMobile, message: message);
  }
}
