import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import 'firestore_service.dart';

/// Authentication Service managing Firebase Auth, Google Sign-In, and persistent sessions
class AuthService {
  final FirebaseAuth? _customAuth;
  AuthService([this._customAuth]);

  FirebaseAuth? get _auth {
    if (_customAuth != null) return _customAuth;
    try {
      return FirebaseAuth.instance;
    } catch (_) {
      return null;
    }
  }

  final GoogleSignIn _googleSignIn = GoogleSignIn(
    scopes: ['email', 'profile'],
  );
  final FirestoreService _firestoreService = FirestoreService();

  static const String _prefKeyCachedUser = 'habitguard_cached_user_profile';
  static const String _prefKeyIsDemo = 'habitguard_is_demo_user';

  // Local in-memory mock user for offline/emulator dev without active Firebase project
  UserModel? _mockUser;
  bool _useMockAuth = false;

  /// Stream of current Firebase Auth state
  Stream<User?> get authStateChanges => _auth?.authStateChanges() ?? const Stream.empty();

  /// Current authenticated Firebase User
  User? get currentUser => _auth?.currentUser;

  /// Check if mock user is active
  bool get isMockUserActive => _useMockAuth && _mockUser != null;

  /// Mock user accessor
  UserModel? get currentMockUser => _mockUser;

  /// Initiates Google Sign-In flow
  Future<UserModel?> signInWithGoogle() async {
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        // User canceled the sign-in dialog
        return null;
      }

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final OAuthCredential credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      final auth = _auth;
      if (auth == null) {
        throw Exception('Firebase Auth is not initialized');
      }

      final UserCredential userCredential = await auth.signInWithCredential(credential);
      final User? firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to retrieve Firebase user credentials');
      }

      // Extract accurate user details from Google & Firebase
      final String userName = (firebaseUser.displayName?.trim().isNotEmpty == true)
          ? firebaseUser.displayName!.trim()
          : (googleUser.displayName?.trim().isNotEmpty == true
              ? googleUser.displayName!.trim()
              : (firebaseUser.email?.split('@').first ?? 'HabitGuard User'));

      final String userEmail = firebaseUser.email ?? googleUser.email;
      final String? userPhoto = firebaseUser.photoURL ?? googleUser.photoUrl;

      // Check if user already exists in Firestore
      UserModel? profile;
      try {
        profile = await _firestoreService.getUserProfile(firebaseUser.uid);
      } catch (e) {
        debugPrint('Firestore read on sign in warning: $e');
      }

      if (profile != null) {
        // Update existing profile with verified Google credentials and timestamps
        profile = profile.copyWith(
          name: (profile.name.isNotEmpty &&
                  profile.name != 'Demo User' &&
                  profile.name != 'HabitGuard User')
              ? profile.name
              : userName,
          email: userEmail.isNotEmpty ? userEmail : profile.email,
          photoUrl: userPhoto ?? profile.photoUrl,
          lastLoginAt: DateTime.now(),
          updatedAt: DateTime.now(),
        );
      } else {
        // Create new user profile with Google account data
        profile = UserModel(
          uid: firebaseUser.uid,
          name: userName,
          email: userEmail,
          photoUrl: userPhoto,
          isProfileComplete: false,
          notificationEnabled: true,
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
          lastLoginAt: DateTime.now(),
        );
      }

      // Save to Firestore and persist locally
      await _firestoreService.saveUserProfile(profile);
      await _cacheUserLocally(profile, isDemo: false);

      _useMockAuth = false;
      _mockUser = null;

      return profile;
    } catch (e) {
      debugPrint('Google Sign-In error: $e');
      rethrow;
    }
  }

  /// One-tap demo / mock authentication for development
  Future<UserModel> signInWithDemoUser({String name = 'Demo User', String email = 'user@habitguard.app'}) async {
    _useMockAuth = true;
    final now = DateTime.now();
    _mockUser = UserModel(
      uid: 'demo_habitguard_user_101',
      name: name,
      email: email,
      photoUrl: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?auto=format&fit=crop&w=256&q=80',
      guardianName: 'Alex Smith',
      guardianMobile: '9876543210',
      countryCode: '+91',
      notificationEnabled: true,
      isProfileComplete: true,
      createdAt: now.subtract(const Duration(days: 30)),
      updatedAt: now,
      lastLoginAt: now,
    );

    await _cacheUserLocally(_mockUser!, isDemo: true);
    return _mockUser!;
  }

  /// Fetches current user profile from Firestore, persistent cache, or mock store
  Future<UserModel?> getCurrentUserProfile() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedJson = prefs.getString(_prefKeyCachedUser);
    final isDemo = prefs.getBool(_prefKeyIsDemo) ?? false;

    UserModel? localUser;
    if (cachedJson != null && cachedJson.isNotEmpty) {
      try {
        final map = jsonDecode(cachedJson) as Map<String, dynamic>;
        final uid = map['uid']?.toString() ?? 'cached_user';
        localUser = UserModel.fromMap(map, uid);
      } catch (e) {
        debugPrint('Error decoding cached user profile: $e');
      }
    }

    if (isDemo && localUser != null) {
      _useMockAuth = true;
      _mockUser = localUser;
      return localUser;
    }

    if (_useMockAuth && _mockUser != null) {
      return _mockUser;
    }

    final firebaseUser = _auth?.currentUser;
    if (firebaseUser == null) {
      if (isDemo && localUser != null) {
        _useMockAuth = true;
        _mockUser = localUser;
        return localUser;
      }
      return null;
    }

    // Try fetching fresh data from Firestore
    try {
      final remoteProfile = await _firestoreService.getUserProfile(firebaseUser.uid);
      if (remoteProfile != null) {
        await _cacheUserLocally(remoteProfile, isDemo: false);
        return remoteProfile;
      }
    } catch (e) {
      debugPrint('Error loading remote profile in getCurrentUserProfile: $e');
    }

    // If Firestore profile was null/offline, fall back to locally cached profile
    if (localUser != null && localUser.uid == firebaseUser.uid) {
      return localUser;
    }

    // Construct valid fallback UserModel from Firebase Auth currentUser so user is never logged out
    final fallbackUser = UserModel(
      uid: firebaseUser.uid,
      name: firebaseUser.displayName?.trim().isNotEmpty == true
          ? firebaseUser.displayName!.trim()
          : (firebaseUser.email?.split('@').first ?? 'HabitGuard User'),
      email: firebaseUser.email ?? '',
      photoUrl: firebaseUser.photoURL,
      isProfileComplete: localUser?.isProfileComplete ?? false,
      guardianName: localUser?.guardianName,
      guardianMobile: localUser?.guardianMobile,
      countryCode: localUser?.countryCode ?? '+91',
      notificationEnabled: localUser?.notificationEnabled ?? true,
      createdAt: localUser?.createdAt ?? DateTime.now(),
      updatedAt: DateTime.now(),
      lastLoginAt: DateTime.now(),
    );

    await _cacheUserLocally(fallbackUser, isDemo: false);
    return fallbackUser;
  }

  /// Updates user profile in Firestore and persistent local cache
  Future<void> updateUserProfile(UserModel updatedUser) async {
    if (_useMockAuth) {
      _mockUser = updatedUser;
      await _cacheUserLocally(updatedUser, isDemo: true);
      return;
    }

    await _cacheUserLocally(updatedUser, isDemo: false);
    await _firestoreService.saveUserProfile(updatedUser);
  }

  /// Helper to cache user to SharedPreferences
  Future<void> _cacheUserLocally(UserModel user, {required bool isDemo}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_prefKeyCachedUser, jsonEncode(user.toMap()));
      await prefs.setBool(_prefKeyIsDemo, isDemo);
    } catch (e) {
      debugPrint('Error caching user locally: $e');
    }
  }

  /// Signs out of Firebase, Google, and clears local persistent cache
  Future<void> signOut() async {
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
    try {
      await _auth?.signOut();
    } catch (_) {}

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_prefKeyCachedUser);
      await prefs.remove(_prefKeyIsDemo);
    } catch (_) {}

    _useMockAuth = false;
    _mockUser = null;
  }
}
