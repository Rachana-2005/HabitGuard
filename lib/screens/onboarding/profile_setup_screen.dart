import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/validators.dart';
import '../../providers/auth_provider.dart';
import '../../providers/usage_provider.dart';
import '../main_screen.dart';
import '../permission/permission_screen.dart';

/// Profile & Guardian Setup Screen after authentication
class ProfileSetupScreen extends StatefulWidget {
  const ProfileSetupScreen({super.key});

  @override
  State<ProfileSetupScreen> createState() => _ProfileSetupScreenState();
}

class _ProfileSetupScreenState extends State<ProfileSetupScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _guardianNameController;
  late TextEditingController _guardianMobileController;

  String _countryCode = '+91';
  bool _notificationEnabled = true;
  bool _isSaving = false;

  final List<String> _countryCodes = ['+91', '+1', '+44', '+61', '+65', '+81', '+49', '+33', '+971'];

  @override
  void initState() {
    super.initState();
    final auth = Provider.of<AuthProvider>(context, listen: false);
    _nameController = TextEditingController(text: auth.user?.name ?? '');
    _emailController = TextEditingController(text: auth.user?.email ?? '');
    _guardianNameController = TextEditingController(text: auth.user?.guardianName ?? 'Parent');
    _guardianMobileController = TextEditingController(text: auth.user?.guardianMobile ?? '');
    _countryCode = auth.user?.countryCode ?? '+91';
    _notificationEnabled = auth.user?.notificationEnabled ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _guardianNameController.dispose();
    _guardianMobileController.dispose();
    super.dispose();
  }

  Future<void> _handleSaveProfile() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isSaving = true);
    final auth = Provider.of<AuthProvider>(context, listen: false);
    final usage = Provider.of<UsageProvider>(context, listen: false);

    final success = await auth.updateGuardianProfile(
      name: _nameController.text.trim(),
      guardianName: _guardianNameController.text.trim(),
      guardianMobile: _guardianMobileController.text.trim(),
      countryCode: _countryCode,
      notificationEnabled: _notificationEnabled,
      sendNotificationMessage: false,
    );

    setState(() => _isSaving = false);

    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '✅ Guardian linked! Welcome message prepared for ${_guardianNameController.text.trim()}',
          ),
          backgroundColor: const Color(0xFF10B981),
        ),
      );

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
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Setup Guardian Profile'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Banner
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFEEF2FF),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.indigo.shade800 : Colors.indigo.shade200,
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.shield_outlined, color: AppTheme.primarySeed, size: 28),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Text(
                          'Configure emergency guardian alerts so someone you trust is notified when addiction risk becomes critical.',
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.35,
                            color: isDark ? Colors.blueGrey.shade200 : const Color(0xFF3730A3),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Section 1: User Info
                Text(
                  'Your Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Full Name',
                    prefixIcon: Icon(Icons.person_outline_rounded),
                  ),
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter your name' : null,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _emailController,
                  readOnly: true,
                  decoration: const InputDecoration(
                    labelText: 'Email Address',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                ),
                const SizedBox(height: 28),

                // Section 2: Guardian Info
                Text(
                  'Guardian Information',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),

                TextFormField(
                  controller: _guardianNameController,
                  decoration: const InputDecoration(
                    labelText: 'Guardian Name',
                    hintText: 'e.g. Parent, Alex Smith',
                    prefixIcon: Icon(Icons.favorite_border_rounded),
                  ),
                  validator: Validators.validateGuardianName,
                ),
                const SizedBox(height: 14),

                // Country Code & Mobile Number
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Country Code Dropdown
                    Container(
                      width: 100,
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: _countryCode,
                          isExpanded: true,
                          items: _countryCodes.map((code) {
                            return DropdownMenuItem(
                              value: code,
                              child: Text(
                                code,
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                                ),
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => _countryCode = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    // Mobile Number Input
                    Expanded(
                      child: TextFormField(
                        controller: _guardianMobileController,
                        keyboardType: TextInputType.phone,
                        decoration: const InputDecoration(
                          labelText: 'Guardian Mobile Number',
                          hintText: '9876543210',
                          prefixIcon: Icon(Icons.phone_outlined),
                        ),
                        validator: Validators.validateMobileNumber,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // High Risk Alerts Switch
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? Colors.blueGrey.shade800 : Colors.blueGrey.shade100,
                    ),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'High Risk Notifications',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                    subtitle: const Text(
                      'Send emergency wellbeing alert to guardian when risk score >= 61',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _notificationEnabled,
                    activeThumbColor: AppTheme.primarySeed,
                    onChanged: (val) => setState(() => _notificationEnabled = val),
                  ),
                ),
                const SizedBox(height: 36),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isSaving ? null : _handleSaveProfile,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primarySeed,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                    ),
                    child: _isSaving
                        ? const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                          )
                        : const Text(
                            'Save & Continue',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
