import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'core/theme/app_theme.dart';
import 'providers/ai_provider.dart';
import 'providers/auth_provider.dart';
import 'providers/history_provider.dart';
import 'providers/risk_provider.dart';
import 'providers/usage_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with graceful offline catch
  try {
    await Firebase.initializeApp();
  } catch (e) {
    debugPrint('Firebase initialization notice (may be using offline/demo mode): $e');
  }

  // Initialize Local Notifications & FCM Channels
  try {
    await NotificationService().initialize();
  } catch (e) {
    debugPrint('Notification service init notice: $e');
  }

  runApp(const HabitGuardApp());
}

/// Root Application Widget for HabitGuard
class HabitGuardApp extends StatelessWidget {
  const HabitGuardApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthProvider>(create: (_) => AuthProvider()),
        ChangeNotifierProvider<UsageProvider>(create: (_) => UsageProvider()),
        ChangeNotifierProvider<RiskProvider>(create: (_) => RiskProvider()),
        ChangeNotifierProvider<HistoryProvider>(create: (_) => HistoryProvider()),
        ChangeNotifierProvider<AiProvider>(create: (_) => AiProvider()),
      ],
      child: MaterialApp(
        title: 'HabitGuard',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.system,
        home: const SplashScreen(),
      ),
    );
  }
}
