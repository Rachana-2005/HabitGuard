import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../core/constants/app_constants.dart';
import '../models/application_usage.dart';
import '../models/daily_usage.dart';
import '../models/user_model.dart';
import 'mock_usage_service.dart';
import 'usage_service.dart';

/// Service managing all Cloud Firestore operations for profiles, usage logs, and devices
class FirestoreService {
  final FirebaseFirestore? _customFirestore;
  FirestoreService([this._customFirestore]);

  FirebaseFirestore get _firestore => _customFirestore ?? FirebaseFirestore.instance;

  // Local memory cache for mock/offline sessions
  static final Map<String, UserModel> _inMemoryUsers = {};
  static final Map<String, Map<String, DailyUsage>> _inMemoryDailyUsage = {};

  // ----------------------------------------------------
  // USER PROFILES (users/{uid})
  // ----------------------------------------------------

  /// Saves or updates a user profile document
  Future<void> saveUserProfile(UserModel user) async {
    try {
      debugPrint('[Firestore] 🔄 Saving user profile to users/${user.uid}...');
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(user.uid)
          .set(user.toMap(), SetOptions(merge: true));
      debugPrint('[Firestore] ✅ User profile saved in Cloud Firestore (users/${user.uid})');
      _inMemoryUsers[user.uid] = user;
    } catch (e) {
      debugPrint('[Firestore ❌ ERROR] Could not save user profile: $e');
      _inMemoryUsers[user.uid] = user;
    }
  }

  /// Retrieves user profile by UID
  Future<UserModel?> getUserProfile(String uid) async {
    try {
      final doc = await _firestore.collection(AppConstants.collectionUsers).doc(uid).get();
      if (doc.exists && doc.data() != null) {
        debugPrint('[Firestore] ✅ Loaded profile for $uid from Firestore');
        return UserModel.fromMap(doc.data()!, uid);
      }
    } catch (e) {
      debugPrint('[Firestore ❌ ERROR] getUserProfile failed: $e');
    }
    return _inMemoryUsers[uid];
  }

  // ----------------------------------------------------
  // DAILY USAGE (users/{uid}/dailyUsage/{date})
  // ----------------------------------------------------

  /// Saves aggregated daily usage record and individual applications
  Future<void> saveDailyUsage(String uid, DailyUsage dailyUsage) async {
    try {
      debugPrint('[Firestore] 🔄 Syncing daily usage to users/$uid/dailyUsage/${dailyUsage.date}...');
      final userDailyRef = _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .collection(AppConstants.collectionDailyUsage)
          .doc(dailyUsage.date);

      await userDailyRef.set(dailyUsage.toMap(), SetOptions(merge: true));

      // Batch save individual applications in subcollection
      final batch = _firestore.batch();
      for (final app in dailyUsage.applications) {
        final cleanDocId = app.packageName.replaceAll('/', '_');
        final appDocRef = userDailyRef.collection(AppConstants.collectionApplications).doc(cleanDocId);
        batch.set(appDocRef, app.toMap(), SetOptions(merge: true));
      }
      await batch.commit();
      debugPrint('[Firestore] ✅ Daily usage (${dailyUsage.formattedTotalTime}) saved in Firestore!');
      _inMemoryDailyUsage.putIfAbsent(uid, () => {})[dailyUsage.date] = dailyUsage;
    } catch (e) {
      debugPrint('[Firestore ❌ ERROR] Failed to save daily usage: $e');
      _inMemoryDailyUsage.putIfAbsent(uid, () => {})[dailyUsage.date] = dailyUsage;
    }
  }

  /// Retrieves daily usage for a specific date
  Future<DailyUsage?> getDailyUsage(String uid, String dateKey) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .collection(AppConstants.collectionDailyUsage)
          .doc(dateKey)
          .get();

      if (doc.exists && doc.data() != null) {
        // Fetch applications subcollection
        final appsSnapshot = await doc.reference
            .collection(AppConstants.collectionApplications)
            .get();

        final List<ApplicationUsage> apps = appsSnapshot.docs
            .map((appDoc) => ApplicationUsage.fromMap(appDoc.data()))
            .toList();

        return DailyUsage.fromMap(doc.data()!, apps: apps);
      }
    } catch (e) {
      debugPrint('[Firestore ❌ ERROR] getDailyUsage failed: $e');
    }

    return _inMemoryDailyUsage[uid]?[dateKey];
  }

  /// Retrieves usage history for the last N days (synced with Firestore and Android native data)
  Future<List<DailyUsage>> getUsageHistory(String uid, {int limitDays = 30}) async {
    List<DailyUsage> firestoreRecords = [];
    try {
      final snapshot = await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .collection(AppConstants.collectionDailyUsage)
          .orderBy('date', descending: true)
          .limit(limitDays)
          .get();

      if (snapshot.docs.isNotEmpty) {
        firestoreRecords = snapshot.docs.map((doc) => DailyUsage.fromMap(doc.data())).toList();
      }
    } catch (e) {
      debugPrint('[Firestore ❌ ERROR] getUsageHistory error: $e');
    }

    // If Firestore already has enough days of records, return them directly
    if (firestoreRecords.length >= limitDays || (firestoreRecords.length >= 7 && limitDays <= 7)) {
      return firestoreRecords;
    }

    // If Firestore has fewer historical days (e.g. freshly installed), retrieve past days directly from Android
    try {
      final nativeHistory = await UsageService().getPastDaysUsage(limitDays);
      if (nativeHistory.isNotEmpty) {
        final Map<String, DailyUsage> merged = {};
        for (final day in nativeHistory) {
          merged[day.date] = day;
        }
        for (final day in firestoreRecords) {
          merged[day.date] = day;
        }

        final resultList = merged.values.toList()..sort((a, b) => b.date.compareTo(a.date));

        // Save past days to Firestore in the background for permanent storage
        if (uid.isNotEmpty) {
          for (final day in resultList) {
            if (!firestoreRecords.any((f) => f.date == day.date)) {
              saveDailyUsage(uid, day).catchError((_) {});
            }
          }
        }

        return resultList.take(limitDays).toList();
      }
    } catch (e) {
      debugPrint('Native history retrieval error: $e');
    }

    if (firestoreRecords.isNotEmpty) {
      return firestoreRecords;
    }

    // Return in-memory or mock history dataset
    final userLocal = _inMemoryDailyUsage[uid]?.values.toList() ?? [];
    if (userLocal.isNotEmpty) {
      userLocal.sort((a, b) => b.date.compareTo(a.date));
      return userLocal.take(limitDays).toList();
    }

    return MockUsageService.getMockHistoryList(daysCount: limitDays);
  }

  // ----------------------------------------------------
  // FCM DEVICE TOKENS (users/{uid}/devices/{deviceId})
  // ----------------------------------------------------

  /// Stores device FCM push token in Firestore
  Future<void> saveDeviceToken(String uid, String deviceId, String token) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .collection(AppConstants.collectionDevices)
          .doc(deviceId)
          .set({
        'token': token,
        'platform': defaultTargetPlatform.name,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Error saving device token: $e');
    }
  }

  // ----------------------------------------------------
  // BEHAVIORAL FEATURES (users/{uid}/behaviorFeatures/{date})
  // ----------------------------------------------------

  /// Saves behavioral features for longitudinal ML analysis
  Future<void> saveBehavioralFeatures(String uid, String dateKey, Map<String, dynamic> featuresMap) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .collection(AppConstants.collectionBehaviorFeatures)
          .doc(dateKey)
          .set(featuresMap, SetOptions(merge: true));
      debugPrint('[Firestore] ✅ Behavioral features saved for $dateKey');
    } catch (e) {
      debugPrint('[Firestore] Error saving behavioral features: $e');
    }
  }

  // ----------------------------------------------------
  // ALERTS (users/{uid}/alerts/{alertId})
  // ----------------------------------------------------

  /// Logs guardian high-risk alert event
  Future<void> logGuardianAlert(String uid, Map<String, dynamic> alertData) async {
    try {
      await _firestore
          .collection(AppConstants.collectionUsers)
          .doc(uid)
          .collection(AppConstants.collectionAlerts)
          .add({
        ...alertData,
        'timestamp': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error logging guardian alert: $e');
    }
  }
}
