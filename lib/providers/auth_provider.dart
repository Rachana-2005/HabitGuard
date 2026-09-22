import 'package:flutter/material.dart';
import '../models/user_model.dart';
import '../services/auth_service.dart';
import '../services/notification_service.dart';
import '../services/sms_service.dart';

enum AuthStatus {
  initial,
  authenticating,
  authenticated,
  unauthenticated,
}

/// Provider managing authentication state, user profile, and session lifecycle
class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  final NotificationService _notificationService = NotificationService();

  AuthStatus _status = AuthStatus.initial;
  UserModel? _user;
  String? _errorMessage;

  AuthStatus get status => _status;
  UserModel? get user => _user;
  String? get errorMessage => _errorMessage;
  bool get isAuthenticated => _status == AuthStatus.authenticated && _user != null;
  bool get isProfileComplete => _user?.isProfileComplete ?? false;

  /// Initializes auth state on startup
  Future<void> initializeAuth() async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    try {
      final profile = await _authService.getCurrentUserProfile();
      if (profile != null) {
        _user = profile;
        _status = AuthStatus.authenticated;
        // Register push token
        _notificationService.registerDeviceToken(_user!.uid);
      } else {
        _status = AuthStatus.unauthenticated;
      }
    } catch (e) {
      debugPrint('Error in initializeAuth: $e');
      _status = AuthStatus.unauthenticated;
    }
    notifyListeners();
  }

  /// Sign in with Google
  Future<bool> signInWithGoogle() async {
    _status = AuthStatus.authenticating;
    _errorMessage = null;
    notifyListeners();

    try {
      final profile = await _authService.signInWithGoogle();
      if (profile != null) {
        _user = profile;
        _status = AuthStatus.authenticated;
        _notificationService.registerDeviceToken(_user!.uid);
        notifyListeners();
        return true;
      } else {
        _status = AuthStatus.unauthenticated;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = 'Google Sign-In failed: ${e.toString()}';
      _status = AuthStatus.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  /// Sign in with Demo / Mock Account (for fast development & testing)
  Future<void> signInWithDemo({String name = 'Demo User', String email = 'user@habitguard.app'}) async {
    _status = AuthStatus.authenticating;
    notifyListeners();

    _user = await _authService.signInWithDemoUser(name: name, email: email);
    _status = AuthStatus.authenticated;
    notifyListeners();
  }

  /// Updates Guardian and Profile information, and optionally sends notification SMS to guardian
  Future<bool> updateGuardianProfile({
    String? name,
    required String guardianName,
    required String guardianMobile,
    required String countryCode,
    required bool notificationEnabled,
    bool sendNotificationMessage = true,
  }) async {
    if (_user == null) return false;

    try {
      final updated = _user!.copyWith(
        name: (name != null && name.trim().isNotEmpty) ? name.trim() : _user!.name,
        guardianName: guardianName.trim(),
        guardianMobile: guardianMobile.trim(),
        countryCode: countryCode.trim(),
        notificationEnabled: notificationEnabled,
        isProfileComplete: true,
        updatedAt: DateTime.now(),
      );

      await _authService.updateUserProfile(updated);
      _user = updated;
      notifyListeners();

      // Dispatch welcome SMS to guardian if phone is provided and notifications enabled
      if (sendNotificationMessage &&
          notificationEnabled &&
          guardianMobile.trim().isNotEmpty) {
        await SmsService.sendGuardianWelcomeNotification(
          guardianName: guardianName,
          guardianMobile: updated.formattedGuardianMobile,
          userName: updated.name,
        );
      }

      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile: $e';
      notifyListeners();
      return false;
    }
  }

  /// Sends or resends the guardian registration welcome SMS
  Future<bool> sendGuardianWelcomeNotification() async {
    if (_user == null ||
        _user!.guardianMobile == null ||
        _user!.guardianMobile!.isEmpty) {
      return false;
    }

    return await SmsService.sendGuardianWelcomeNotification(
      guardianName: _user!.guardianName ?? 'Guardian',
      guardianMobile: _user!.formattedGuardianMobile,
      userName: _user!.name,
    );
  }

  /// Sign out
  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _status = AuthStatus.unauthenticated;
    notifyListeners();
  }
}
