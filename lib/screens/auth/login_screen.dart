import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usage_provider.dart';
import '../main_screen.dart';
import '../onboarding/profile_setup_screen.dart';
import '../permission/permission_screen.dart';

/// Login Screen with Google Sign-In and Demo Login option
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _isSigningIn = false;

  Future<void> _handleGoogleSignIn() async {
    setState(() => _isSigningIn = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final usageProvider = Provider.of<UsageProvider>(context, listen: false);

    final success = await authProvider.signInWithGoogle();
    setState(() => _isSigningIn = false);

    if (success && mounted) {
      _proceedAfterLogin(authProvider, usageProvider);
    } else if (authProvider.errorMessage != null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(authProvider.errorMessage!),
          backgroundColor: RiskColors.critical,
        ),
      );
    }
  }

  Future<void> _handleDemoSignIn() async {
    setState(() => _isSigningIn = true);
    final authProvider = Provider.of<AuthProvider>(context, listen: false);
    final usageProvider = Provider.of<UsageProvider>(context, listen: false);

    await authProvider.signInWithDemo();
    setState(() => _isSigningIn = false);

    if (mounted) {
      _proceedAfterLogin(authProvider, usageProvider);
    }
  }

  void _proceedAfterLogin(AuthProvider auth, UsageProvider usage) async {
    if (!auth.isProfileComplete) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const ProfileSetupScreen()),
      );
      return;
    }

    final hasPermission = await usage.checkPermission();
    if (!mounted) return;

    if (!hasPermission && !usage.isMockMode) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const PermissionScreen()),
      );
    } else {
      await usage.fetchTodayUsage(auth.user?.uid);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 36),

              // HabitGuard Brand Icon
              Container(
                width: 84,
                height: 84,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFF6366F1), Color(0xFF4338CA)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFF6366F1).withAlpha(90),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: const Icon(
                  Icons.shield_rounded,
                  size: 46,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 20),

              // Title
              Text(
                'HabitGuard',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w900,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),

              // Description
              Text(
                'Protect your digital focus and monitor smartphone addiction risks with smart wellbeing insights.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                ),
              ),
              const SizedBox(height: 36),

              // Value Pillars
              _buildFeaturePill(
                icon: Icons.timer_outlined,
                title: 'Screen-Time Monitoring',
                subtitle: 'Accurate Android native foreground app tracking',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildFeaturePill(
                icon: Icons.psychology_outlined,
                title: 'Addiction Risk Scoring',
                subtitle: 'AI-based 0-100 risk score and habit recommendations',
                isDark: isDark,
              ),
              const SizedBox(height: 12),
              _buildFeaturePill(
                icon: Icons.notifications_active_outlined,
                title: 'Guardian Alert System',
                subtitle: 'Automatic emergency alerts sent to guardian on high risk',
                isDark: isDark,
              ),
              const SizedBox(height: 48),

              // Google Sign-In Button
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isSigningIn ? null : _handleGoogleSignIn,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    foregroundColor: isDark ? const Color(0xFF0F172A) : Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isSigningIn
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2.5),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              alignment: Alignment.center,
                              decoration: const BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                              ),
                              child: const Text(
                                'G',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: Color(0xFF4285F4),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            const Text(
                              'Continue with Google',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 14),

              // Demo / Quick Sign-In Option
              TextButton(
                onPressed: _isSigningIn ? null : _handleDemoSignIn,
                style: TextButton.styleFrom(
                  foregroundColor: AppTheme.primarySeed,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                ),
                child: const Text(
                  '⚡ Quick Demo Sign-In (Instant Access)',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeaturePill({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E293B) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? Colors.blueGrey.shade800.withAlpha(90) : Colors.blueGrey.shade100,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppTheme.primarySeed.withAlpha(isDark ? 40 : 25),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppTheme.primarySeed, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF1E293B),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
