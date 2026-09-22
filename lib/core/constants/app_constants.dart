/// Application-wide constants, keys, thresholds, and routing identifiers.
class AppConstants {
  // Application Info
  static const String appName = 'HabitGuard';
  static const String appTagline = 'AI-Based Digital Addiction & Screen-Time Monitoring';
  static const String appVersion = '1.0.0';

  // Method Channel
  static const String usageChannelName = 'com.habitguard/usage';

  // Risk Score Thresholds (0 - 100 Scale)
  static const int riskThresholdLowMax = 30;
  static const int riskThresholdModerateMax = 60;
  static const int riskThresholdHighMax = 80;
  static const int riskThresholdHighAlert = 61; // Triggers High-Risk Guardian Alert

  // Risk Weights in Calculation Algorithm (Total = 1.0)
  static const double weightTotalScreenTime = 0.40;
  static const double weightSocialMedia = 0.25;
  static const double weightGaming = 0.20;
  static const double weightEntertainment = 0.10;
  static const double weightOther = 0.05;

  // Daily Healthy Usage Baselines (in minutes)
  static const int baselineHealthyDailyMinutes = 120; // 2 hours
  static const int moderateThresholdMinutes = 240;    // 4 hours
  static const int highThresholdMinutes = 360;        // 6 hours
  static const int criticalThresholdMinutes = 480;    // 8+ hours

  // Cooldown Constants
  static const Duration guardianAlertCooldown = Duration(hours: 24);

  // Firestore Collections
  static const String collectionUsers = 'users';
  static const String collectionDailyUsage = 'dailyUsage';
  static const String collectionApplications = 'applications';
  static const String collectionBehaviorFeatures = 'behaviorFeatures';
  static const String collectionDevices = 'devices';
  static const String collectionAlerts = 'alerts';

  // ML Service Configurations
  static const String defaultMlApiUrl = 'http://10.0.2.2:8000';
  static const String defaultMlLocalUrl = 'http://localhost:8000';

  // SharedPreferences Keys
  static const String prefKeyMockDataEnabled = 'habitguard_mock_data_enabled';
  static const String prefKeyUseMockML = 'habitguard_use_mock_ml';
  static const String prefKeyUseMockGenAI = 'habitguard_use_mock_genai';
  static const String prefKeyUseMockUsage = 'habitguard_use_mock_usage';
  static const String prefKeyMlApiUrl = 'habitguard_ml_api_url';
  static const String prefKeyGenAiKey = 'habitguard_genai_key';
  static const String prefKeyMockRiskPreset = 'habitguard_mock_risk_preset';
  static const String prefKeyLastGuardianAlertDate = 'habitguard_last_guardian_alert_date';
  static const String prefKeyThemeMode = 'habitguard_theme_mode';

  // Disclaimers
  static const String medicalDisclaimer =
      'HabitGuard provides a digital wellbeing risk indicator based on smartphone usage behavior. '
      'It is not a medical diagnosis and should not be used as a substitute for professional advice.';

  // Notification Channel IDs
  static const String notificationChannelHighRisk = 'habitguard_high_risk_channel';
  static const String notificationChannelName = 'HabitGuard High Risk Alerts';
  static const String notificationChannelDesc = 'Alerts sent when digital addiction risk exceeds safety thresholds';
}
