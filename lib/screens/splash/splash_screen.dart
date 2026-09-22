import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usage_provider.dart';
import '../auth/login_screen.dart';
import '../main_screen.dart';
import '../onboarding/profile_setup_screen.dart';
import '../permission/permission_screen.dart';

/// Animated Splash Screen that verifies auth state, profile completeness, and usage permissions
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeIn),
    );

    _animController.forward();
    _bootstrapApp();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _bootstrapApp() async {
    // Wait minimum splash time for brand animation
    await Future.delayed(const Duration(milliseconds: 1600));
    if (!mounted) return;

    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final usageProvider = Provider.of<UsageProvider>(context, listen: false);

    await authProvider.initializeAuth();
    if (!mounted) return;

    if (!authProvider.isAuthenticated) {
      // 1. Not authenticated -> Login Screen
      _navigateTo(const LoginScreen());
      return;
    }

    if (!authProvider.isProfileComplete) {
      // 2. Profile incomplete -> Profile & Guardian setup
      _navigateTo(const ProfileSetupScreen());
      return;
    }

    // Check usage permission
    final hasPermission = await usageProvider.checkPermission();
    if (!mounted) return;

    if (!hasPermission && !usageProvider.isMockMode) {
      // 3. Permission not granted -> Permission Gate Screen
      _navigateTo(const PermissionScreen());
    } else {
      // 4. All ready -> Open Main Application
      await usageProvider.fetchTodayUsage(authProvider.user?.uid);
      if (!mounted) return;
      _navigateTo(const MainScreen());
    }
  }

  void _navigateTo(Widget screen) {
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, anim, _) => screen,
        transitionsBuilder: (context, anim, _, child) {
          return FadeTransition(opacity: anim, child: child);
        },
        transitionDuration: const Duration(milliseconds: 500),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [const Color(0xFF0F172A), const Color(0xFF020617)]
                : [const Color(0xFFEEF2FF), Colors.white],
          ),
        ),
        child: Center(
          child: FadeTransition(
            opacity: _fadeAnimation,
            child: ScaleTransition(
              scale: _scaleAnimation,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // App Icon Shield
                  Container(
                    width: 96,
                    height: 96,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(28),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6366F1).withAlpha(100),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.shield_rounded,
                      size: 52,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Brand Name
                  Text(
                    'HabitGuard',
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      letterSpacing: -0.5,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Tagline
                  Text(
                    'AI Digital Addiction Monitoring',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 48),

                  // Subtle Loader
                  SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      valueColor: AlwaysStoppedAnimation<Color>(
                        isDark ? const Color(0xFF818CF8) : const Color(0xFF4F46E5),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
