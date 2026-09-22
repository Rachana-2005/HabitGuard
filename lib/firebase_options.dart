import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for HabitGuard.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCi9WBtveG2EiWap3phUMy1pJKgwJkbhLQ',
    appId: '1:369224148417:web:b01754ab21da47cb2dfb40',
    messagingSenderId: '369224148417',
    projectId: 'habitguard-b169e',
    authDomain: 'habitguard-b169e.firebaseapp.com',
    storageBucket: 'habitguard-b169e.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCi9WBtveG2EiWap3phUMy1pJKgwJkbhLQ',
    appId: '1:369224148417:android:b01754ab21da47cb2dfb40',
    messagingSenderId: '369224148417',
    projectId: 'habitguard-b169e',
    storageBucket: 'habitguard-b169e.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCi9WBtveG2EiWap3phUMy1pJKgwJkbhLQ',
    appId: '1:369224148417:ios:b01754ab21da47cb2dfb40',
    messagingSenderId: '369224148417',
    projectId: 'habitguard-b169e',
    storageBucket: 'habitguard-b169e.firebasestorage.app',
    iosBundleId: 'com.habitguard.habitguard',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCi9WBtveG2EiWap3phUMy1pJKgwJkbhLQ',
    appId: '1:369224148417:ios:b01754ab21da47cb2dfb40',
    messagingSenderId: '369224148417',
    projectId: 'habitguard-b169e',
    storageBucket: 'habitguard-b169e.firebasestorage.app',
    iosBundleId: 'com.habitguard.habitguard',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCi9WBtveG2EiWap3phUMy1pJKgwJkbhLQ',
    appId: '1:369224148417:web:b01754ab21da47cb2dfb40',
    messagingSenderId: '369224148417',
    projectId: 'habitguard-b169e',
    authDomain: 'habitguard-b169e.firebaseapp.com',
    storageBucket: 'habitguard-b169e.firebasestorage.app',
  );
}
