import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usage_provider.dart';
import '../main_screen.dart';

/// Permission Gate Screen guiding the user to grant Android Usage Access
class PermissionScreen extends StatefulWidget {
  const PermissionScreen({super.key});

  @override
  State<PermissionScreen> createState() => _PermissionScreenState();
}

class _PermissionScreenState extends State<PermissionScreen> with WidgetsBindingObserver {
  bool _isChecking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkPermissionAndProceed();
    }
  }

  Future<void> _checkPermissionAndProceed() async {
    if (_isChecking) return;
    setState(() => _isChecking = true);

    final usage = Provider.of<UsageProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    final granted = await usage.checkPermission();
    setState(() => _isChecking = false);

    if (granted && mounted) {
      await usage.fetchTodayUsage(auth.user?.uid);
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
    }
  }

  Future<void> _handleGrantPermission() async {
    final usage = Provider.of<UsageProvider>(context, listen: false);
    await usage.requestPermission();
  }

  Future<void> _handleUseMockData() async {
    final usage = Provider.of<UsageProvider>(context, listen: false);
    final auth = Provider.of<AuthProvider>(context, listen: false);

    await usage.setMockMode(true, uid: auth.user?.uid);
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MainScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Spacer(),

              // Security & Usage Permission Graphic
              Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  color: AppTheme.primarySeed.withAlpha(isDark ? 40 : 25),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.app_settings_alt_rounded,
                  size: 52,
                  color: AppTheme.primarySeed,
                ),
              ),
              const SizedBox(height: 28),

              // Title
              Text(
                'Allow HabitGuard to access app usage data',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 12),

              // Subtitle / Privacy Notice
              Text(
                'HabitGuard needs Android Usage Access to calculate screen time, detect addiction risk, and alert your guardian during critical periods.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  height: 1.4,
                  color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                ),
              ),
              const SizedBox(height: 28),

              // Privacy Guarantees Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                  ),
                ),
                child: Column(
                  children: [
                    _buildPrivacyItem(
                      icon: Icons.check_circle_outline_rounded,
                      text: 'Tracks foreground screen duration only',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildPrivacyItem(
                      icon: Icons.lock_outline_rounded,
                      text: 'Never accesses messages, passwords, or personal files',
                      isDark: isDark,
                    ),
                    const SizedBox(height: 10),
                    _buildPrivacyItem(
                      icon: Icons.verified_user_outlined,
                      text: 'Encrypted and private under your account',
                      isDark: isDark,
                    ),
                  ],
                ),
              ),

              const Spacer(),

              // Grant Permission Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _handleGrantPermission,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primarySeed,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Icon(Icons.open_in_new_rounded, size: 20),
                      SizedBox(width: 10),
                      Text(
                        'Grant Usage Access',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // "I have granted access" Re-check button
              SizedBox(
                width: double.infinity,
                height: 48,
                child: OutlinedButton(
                  onPressed: _isChecking ? null : _checkPermissionAndProceed,
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text(
                          'I have granted access',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                ),
              ),
              const SizedBox(height: 12),

              // Developer Mock Mode Option (for testing on emulators)
              TextButton(
                onPressed: _handleUseMockData,
                child: const Text(
                  '💻 Test in Emulator / Mock Mode',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPrivacyItem({
    required IconData icon,
    required String text,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFF10B981), size: 20),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.blueGrey.shade200 : const Color(0xFF334155),
            ),
          ),
        ),
      ],
    );
  }
}
