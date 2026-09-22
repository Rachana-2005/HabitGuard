import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_constants.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/ai_provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/risk_provider.dart';
import '../../providers/usage_provider.dart';
import '../../services/mock_usage_service.dart';
import '../../services/sms_service.dart';
import '../auth/login_screen.dart';

/// Profile & Settings Screen allowing guardian details update, mock preset switching, and alerts testing
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  void _showEditProfileNameDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final nameCtrl = TextEditingController(text: auth.user?.name ?? '');
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: const Text('Edit Your Name'),
          content: Form(
            key: formKey,
            child: TextFormField(
              controller: nameCtrl,
              decoration: const InputDecoration(labelText: 'Full Name', prefixIcon: Icon(Icons.person)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () async {
                if (formKey.currentState!.validate()) {
                  final user = auth.user;
                  if (user != null) {
                    await auth.updateGuardianProfile(
                      name: nameCtrl.text.trim(),
                      guardianName: user.guardianName ?? 'Guardian',
                      guardianMobile: user.guardianMobile ?? '',
                      countryCode: user.countryCode,
                      notificationEnabled: user.notificationEnabled,
                      sendNotificationMessage: false,
                    );
                  }
                  if (ctx.mounted) Navigator.of(ctx).pop();
                }
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  void _showEditMlUrlDialog() {
    final ai = Provider.of<AiProvider>(context, listen: false);
    final urlCtrl = TextEditingController(text: ai.mlService.mlApiUrl);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure ML Service URL'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Specify the local or remote URL of the Python FastAPI service.\nDefault: http://10.0.2.2:8000 (Android Emulator) or http://localhost:8000 (Desktop/Web/Reverse Proxy)',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: urlCtrl,
              decoration: const InputDecoration(
                labelText: 'ML API URL',
                hintText: 'http://10.0.2.2:8000',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              await ai.mlService.setMlApiUrl(urlCtrl.text.trim());
              await ai.checkAiServicesHealth();
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditGenAiKeyDialog() {
    final ai = Provider.of<AiProvider>(context, listen: false);
    final keyCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Configure Gemini API Key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Enter your Google Gemini API key to enable live AI Wellness Coach generation. Your key is stored securely in local device storage.',
              style: TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: keyCtrl,
              obscureText: true,
              decoration: const InputDecoration(
                labelText: 'Gemini API Key',
                hintText: 'AIzaSy...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              if (keyCtrl.text.trim().isNotEmpty) {
                await ai.genAiService.setApiKey(keyCtrl.text.trim());
                await ai.checkAiServicesHealth();
              }
              if (ctx.mounted) Navigator.of(ctx).pop();
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  void _showEditGuardianDialog() {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final guardianNameCtrl = TextEditingController(text: auth.user?.guardianName ?? '');
    final guardianMobileCtrl = TextEditingController(text: auth.user?.guardianMobile ?? '');
    String countryCode = auth.user?.countryCode ?? '+91';
    final formKey = GlobalKey<FormState>();

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Edit Guardian Contact'),
              content: Form(
                key: formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: guardianNameCtrl,
                      decoration: const InputDecoration(labelText: 'Guardian Name'),
                      validator: Validators.validateGuardianName,
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        DropdownButton<String>(
                          value: countryCode,
                          items: ['+91', '+1', '+44', '+61', '+65', '+81', '+49', '+33', '+971'].map((c) {
                            return DropdownMenuItem(value: c, child: Text(c));
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setDialogState(() => countryCode = val);
                          },
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            controller: guardianMobileCtrl,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(labelText: 'Mobile Number'),
                            validator: Validators.validateMobileNumber,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      await auth.updateGuardianProfile(
                        guardianName: guardianNameCtrl.text,
                        guardianMobile: guardianMobileCtrl.text,
                        countryCode: countryCode,
                        notificationEnabled: auth.user?.notificationEnabled ?? true,
                        sendNotificationMessage: true,
                      );
                      if (ctx.mounted) {
                        Navigator.of(ctx).pop();
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              '✅ Guardian saved & notification message opened for ${guardianNameCtrl.text}',
                            ),
                            backgroundColor: const Color(0xFF10B981),
                          ),
                        );
                      }
                    }
                  },
                  child: const Text('Save & Notify'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _handleSendGuardianWelcomeSms() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final user = auth.user;

    if (user == null || user.guardianMobile == null || user.guardianMobile!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add a guardian mobile number first.'),
          backgroundColor: RiskColors.moderate,
        ),
      );
      return;
    }

    final success = await auth.sendGuardianWelcomeNotification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            success
              ? '📱 Opening messaging app to notify guardian (${user.formattedGuardianMobile})'
              : 'Could not open SMS app.',
          ),
          backgroundColor: success ? const Color(0xFF10B981) : RiskColors.moderate,
        ),
      );
    }
  }

  Future<void> _handleTestAlert() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final risk = Provider.of<RiskProvider>(context, listen: false);

    if (auth.user == null) return;

    final user = auth.user!;
    if (user.guardianMobile == null || user.guardianMobile!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please configure guardian mobile number first.'),
          backgroundColor: RiskColors.moderate,
        ),
      );
      return;
    }

    // Trigger in-app & backend alert
    await risk.triggerTestAlert(user: user, mockScore: 78);

    // Open direct emergency SMS in native messaging app
    final smsOpened = await SmsService.sendHighRiskGuardianAlert(
      guardianName: user.guardianName ?? 'Guardian',
      guardianMobile: user.formattedGuardianMobile,
      userName: user.name,
      riskScore: 78,
      riskLevel: 'HIGH RISK',
      screenTime: '5h 45m',
    );

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            smsOpened
                ? '🚨 Emergency high-risk alert message opened for guardian (${user.formattedGuardianMobile})'
                : '✅ High-Risk Guardian Alert recorded in Firestore!',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );
    }
  }

  Future<void> _handleLogout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Log Out'),
        content: const Text('Are you sure you want to log out of HabitGuard?'),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: RiskColors.critical),
            child: const Text('Log Out', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true && mounted) {
      await Provider.of<AuthProvider>(context, listen: false).signOut();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final auth = Provider.of<AuthProvider>(context);
    final usage = Provider.of<UsageProvider>(context);
    final user = auth.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile & Settings'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // User Profile Header Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
                ),
              ),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: AppTheme.primarySeed.withAlpha(40),
                    backgroundImage: user?.photoUrl != null ? NetworkImage(user!.photoUrl!) : null,
                    child: user?.photoUrl == null
                        ? const Icon(Icons.person_rounded, size: 36, color: AppTheme.primarySeed)
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Flexible(
                              child: Text(
                                user?.name ?? 'HabitGuard User',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            ),
                            const SizedBox(width: 6),
                            InkWell(
                              onTap: _showEditProfileNameDialog,
                              borderRadius: BorderRadius.circular(12),
                              child: const Padding(
                                padding: EdgeInsets.all(4.0),
                                child: Icon(Icons.edit, size: 16, color: AppTheme.primarySeed),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 2),
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 13,
                            color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 1: Guardian Details
            _buildSectionTitle('Guardian Emergency Contact', isDark),
            const SizedBox(height: 10),
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
                  _buildSettingRow(
                    icon: Icons.person_outline_rounded,
                    title: 'Guardian Name',
                    value: user?.guardianName ?? 'Not configured',
                    isDark: isDark,
                  ),
                  Divider(
                    height: 16,
                    color: isDark ? Colors.blueGrey.shade800.withAlpha(60) : Colors.blueGrey.shade100,
                  ),
                  _buildSettingRow(
                    icon: Icons.phone_outlined,
                    title: 'Guardian Mobile',
                    value: user?.formattedGuardianMobile.isNotEmpty == true
                        ? user!.formattedGuardianMobile
                        : 'Not configured',
                    isDark: isDark,
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: _showEditGuardianDialog,
                          icon: const Icon(Icons.edit_outlined, size: 16),
                          label: const Text('Edit Contact'),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: _handleSendGuardianWelcomeSms,
                          icon: const Icon(Icons.sms_outlined, size: 16),
                          label: const Text('Send SMS'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF0F766E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 2: Notification & Alert Preferences
            _buildSectionTitle('Notification Preferences', isDark),
            const SizedBox(height: 10),
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
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'High Risk Guardian Alerts',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Alert guardian when digital risk score >= 61 (HIGH or CRITICAL)',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: user?.notificationEnabled ?? true,
                    activeThumbColor: AppTheme.primarySeed,
                    onChanged: (val) {
                      if (user != null) {
                        auth.updateGuardianProfile(
                          guardianName: user.guardianName ?? '',
                          guardianMobile: user.guardianMobile ?? '',
                          countryCode: user.countryCode,
                          notificationEnabled: val,
                        );
                      }
                    },
                  ),
                  Divider(
                    height: 16,
                    color: isDark ? Colors.blueGrey.shade800.withAlpha(60) : Colors.blueGrey.shade100,
                  ),
                  ElevatedButton.icon(
                    onPressed: _handleTestAlert,
                    icon: const Icon(Icons.notifications_active_outlined, size: 18),
                    label: const Text('Dispatch Test Guardian Alert'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarySeed,
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 3: Android Permission & Developer Mock Options
            _buildSectionTitle('System & Developer Testing', isDark),
            const SizedBox(height: 10),
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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        usage.hasPermission ? Icons.check_circle : Icons.warning_amber_rounded,
                        color: usage.hasPermission ? const Color(0xFF10B981) : RiskColors.moderate,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          usage.hasPermission ? 'Usage Access Granted' : 'Usage Access Not Granted',
                          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                        ),
                      ),
                      TextButton(
                        onPressed: () => usage.requestPermission(),
                        child: const Text('Settings'),
                      ),
                    ],
                  ),
                  Divider(
                    height: 16,
                    color: isDark ? Colors.blueGrey.shade800.withAlpha(60) : Colors.blueGrey.shade100,
                  ),
                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Mock Data Mode',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Toggle simulated screen time data for emulator/testing',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: usage.isMockMode,
                    activeThumbColor: AppTheme.primarySeed,
                    onChanged: (val) {
                      usage.setMockMode(val, uid: user?.uid);
                    },
                  ),
                  if (usage.isMockMode) ...[
                    const SizedBox(height: 8),
                    const Text(
                      'Simulate Risk Preset:',
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 6),
                    DropdownButtonFormField<MockRiskPreset>(
                      initialValue: usage.currentMockPreset,
                      decoration: const InputDecoration(
                        contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                      ),
                      items: MockRiskPreset.values.map((preset) {
                        return DropdownMenuItem(
                          value: preset,
                          child: Text(preset.title, style: const TextStyle(fontSize: 13)),
                        );
                      }).toList(),
                      onChanged: (preset) {
                        if (preset != null) {
                          usage.switchMockPreset(preset, uid: user?.uid);
                        }
                      },
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Section 4: AI Services Live Connectivity Status
            _buildSectionTitle('AI Services & Connectivity', isDark),
            const SizedBox(height: 10),
            Consumer<AiProvider>(
              builder: (context, ai, _) {
                final usage = Provider.of<UsageProvider>(context);
                return Container(
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
                      _buildStatusRow(
                        title: 'Android Usage Tracking',
                        subtitle: usage.hasPermission ? 'Native UsageStatsManager' : 'Permission Required',
                        connected: usage.hasPermission,
                        icon: Icons.smartphone_rounded,
                        isDark: isDark,
                      ),
                      Divider(
                        height: 16,
                        color: isDark ? Colors.blueGrey.shade800.withAlpha(60) : Colors.blueGrey.shade100,
                      ),
                      _buildStatusRow(
                        title: 'ML Risk Prediction',
                        subtitle: ai.mlService.useMockML
                            ? 'Development Mock Active'
                            : (ai.mlConnected ? 'Random Forest (Connected)' : 'Service Offline / Degraded'),
                        connected: ai.mlConnected,
                        isMock: ai.mlService.useMockML,
                        icon: Icons.psychology_outlined,
                        isDark: isDark,
                      ),
                      Divider(
                        height: 16,
                        color: isDark ? Colors.blueGrey.shade800.withAlpha(60) : Colors.blueGrey.shade100,
                      ),
                      _buildStatusRow(
                        title: 'Generative AI Wellness Coach',
                        subtitle: ai.genAiService.useMockGenAI
                            ? 'Development Mock Active'
                            : (ai.genAiService.isConfigured ? 'Gemini API Connected' : 'Not Configured'),
                        connected: ai.genAiService.isConfigured || ai.genAiService.useMockGenAI,
                        isMock: ai.genAiService.useMockGenAI,
                        icon: Icons.auto_awesome_rounded,
                        isDark: isDark,
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Section 5: AI & Service Configuration
            _buildSectionTitle('AI & Backend Configuration', isDark),
            const SizedBox(height: 10),
            Consumer<AiProvider>(
              builder: (context, ai, _) {
                return Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.link_rounded, color: AppTheme.primarySeed),
                        title: const Text('ML Service Endpoint', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(ai.mlService.mlApiUrl, style: const TextStyle(fontSize: 12)),
                        trailing: OutlinedButton(
                          onPressed: _showEditMlUrlDialog,
                          child: const Text('Edit', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Use Mock ML Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Enable realistic simulated risk predictions for testing', style: TextStyle(fontSize: 12)),
                        value: ai.mlService.useMockML,
                        activeThumbColor: AppTheme.primarySeed,
                        onChanged: (val) async {
                          await ai.mlService.setUseMockML(val);
                          await ai.checkAiServicesHealth();
                        },
                      ),
                      Divider(height: 16, color: isDark ? Colors.blueGrey.shade800.withAlpha(60) : Colors.blueGrey.shade100),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.vpn_key_outlined, color: AppTheme.primarySeed),
                        title: const Text('Gemini API Key', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: Text(
                          ai.genAiService.isConfigured ? '••••••••••••••••' : 'Not configured',
                          style: const TextStyle(fontSize: 12),
                        ),
                        trailing: OutlinedButton(
                          onPressed: _showEditGenAiKeyDialog,
                          child: const Text('Configure', style: TextStyle(fontSize: 12)),
                        ),
                      ),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: const Text('Use Mock GenAI Mode', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                        subtitle: const Text('Enable contextual simulated coach responses', style: TextStyle(fontSize: 12)),
                        value: ai.genAiService.useMockGenAI,
                        activeThumbColor: AppTheme.primarySeed,
                        onChanged: (val) async {
                          await ai.genAiService.setUseMockGenAI(val);
                          await ai.checkAiServicesHealth();
                        },
                      ),
                    ],
                  ),
                );
              },
            ),
            const SizedBox(height: 24),

            // Section 6: Medical & Privacy Disclaimer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF1E293B) : Colors.blueGrey.shade50.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade200,
                ),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.verified_user_outlined, size: 20, color: AppTheme.primarySeed),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Academic Digital Wellbeing Disclaimer',
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                        SizedBox(height: 4),
                        Text(
                          AppConstants.medicalDisclaimer,
                          style: TextStyle(fontSize: 11, color: Colors.grey, height: 1.4),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Logout Button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: OutlinedButton.icon(
                onPressed: _handleLogout,
                icon: const Icon(Icons.logout_rounded, color: RiskColors.critical, size: 20),
                label: const Text(
                  'Log Out',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: RiskColors.critical,
                  ),
                ),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: RiskColors.critical),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
              ),
            ),
            const SizedBox(height: 36),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.w800,
        color: isDark ? Colors.white : const Color(0xFF0F172A),
      ),
    );
  }

  Widget _buildStatusRow({
    required String title,
    required String subtitle,
    required bool connected,
    bool isMock = false,
    required IconData icon,
    required bool isDark,
  }) {
    Color statusColor = connected ? const Color(0xFF10B981) : Colors.grey;
    String statusText = connected ? 'Connected' : 'Unavailable';
    if (isMock) {
      statusColor = const Color(0xFF6366F1);
      statusText = 'Mock Mode';
    }

    return Row(
      children: [
        Icon(icon, size: 22, color: AppTheme.primarySeed),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              Text(subtitle, style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withAlpha(isDark ? 40 : 25),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: statusColor.withAlpha(120)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
              ),
              const SizedBox(width: 6),
              Text(
                statusText,
                style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: statusColor),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSettingRow({
    required IconData icon,
    required String title,
    required String value,
    required bool isDark,
  }) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primarySeed),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              color: isDark ? Colors.blueGrey.shade300 : Colors.blueGrey.shade700,
            ),
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}
