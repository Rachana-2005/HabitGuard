import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import '../core/constants/app_constants.dart';
import '../core/utils/time_formatter.dart';
import 'firestore_service.dart';

/// Top-level background message handler for FCM
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  debugPrint('Handling background FCM message: ${message.messageId}');
}

/// Service managing Push Notifications (FCM) and Local High-Risk Alerts
class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  FirebaseMessaging? get _fcm {
    try {
      return FirebaseMessaging.instance;
    } catch (_) {
      return null;
    }
  }
  final FirestoreService _firestoreService = FirestoreService();

  bool _isInitialized = false;

  /// Initializes local notifications and FCM listeners
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      // 1. Initialize Local Notifications Plugin
      const AndroidInitializationSettings androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');

      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );

      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications.initialize(
        initSettings,
        onDidReceiveNotificationResponse: (NotificationResponse response) {
          debugPrint('Notification clicked: ${response.payload}');
        },
      );

      // 2. Create High-Risk Alert Channel for Android 8.0+ (API 26+)
      const AndroidNotificationChannel highRiskChannel = AndroidNotificationChannel(
        AppConstants.notificationChannelHighRisk,
        AppConstants.notificationChannelName,
        description: AppConstants.notificationChannelDesc,
        importance: Importance.high,
        playSound: true,
        enableVibration: true,
      );

      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.createNotificationChannel(highRiskChannel);
        await androidPlugin.requestNotificationsPermission();
      }

      // 3. Initialize FCM if available
      try {
        FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

        // Request Push Permission
        await _fcm?.requestPermission(
          alert: true,
          badge: true,
          sound: true,
          provisional: false,
        );

        // Foreground Message Stream
        FirebaseMessaging.onMessage.listen((RemoteMessage message) {
          final notification = message.notification;
          if (notification != null) {
            _showPushNotification(
              title: notification.title ?? 'HabitGuard Notification',
              body: notification.body ?? '',
            );
          }
        });
      } catch (fcmError) {
        debugPrint('FCM initialization notice (may be offline/unconfigured): $fcmError');
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Error initializing NotificationService: $e');
    }
  }

  /// Registers user's FCM device token with Firestore
  Future<void> registerDeviceToken(String uid) async {
    try {
      final token = await _fcm?.getToken();
      if (token != null) {
        // Simple synthetic device ID or token hash
        final deviceId = 'device_${token.substring(0, 16)}';
        await _firestoreService.saveDeviceToken(uid, deviceId, token);
      }
    } catch (e) {
      debugPrint('Error registering FCM token: $e');
    }
  }

  /// Displays high-risk addiction alert notification on user device
  Future<void> showHighRiskLocalNotification({
    required int score,
    required int totalMinutes,
    required String riskLevel,
  }) async {
    try {
      final formattedTime = TimeFormatter.formatMinutes(totalMinutes);
      final isCritical = score > 80;

      final AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
        AppConstants.notificationChannelHighRisk,
        AppConstants.notificationChannelName,
        channelDescription: AppConstants.notificationChannelDesc,
        importance: Importance.max,
        priority: Priority.high,
        ticker: 'HabitGuard Risk Alert',
        color: const Color(0xFFEF4444),
        styleInformation: BigTextStyleInformation(
          'Your screen time today has reached $formattedTime with an Addiction Risk Score of $score/100 ($riskLevel). Take a healthy digital break now.',
          contentTitle: isCritical
              ? '🚨 HabitGuard Alert: CRITICAL Addiction Risk'
              : '⚠️ HabitGuard Alert: High Addiction Risk Detected',
        ),
      );

      const DarwinNotificationDetails iosDetails = DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      );

      final NotificationDetails platformDetails = NotificationDetails(
        android: androidDetails,
        iOS: iosDetails,
      );

      await _localNotifications.show(
        1001,
        isCritical
            ? '🚨 HabitGuard Alert: CRITICAL Addiction Risk'
            : '⚠️ HabitGuard Alert: High Addiction Risk Detected',
        'Risk Score: $score/100 ($riskLevel). Total screen time: $formattedTime.',
        platformDetails,
      );
    } catch (e) {
      debugPrint('Error presenting local notification: $e');
    }
  }

  /// Displays general push notification
  Future<void> _showPushNotification({required String title, required String body}) async {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'habitguard_general_channel',
      'HabitGuard Updates',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
    );

    await _localNotifications.show(
      DateTime.now().millisecondsSinceEpoch ~/ 1000,
      title,
      body,
      platformDetails,
    );
  }
}
