// Firebase options for this project.
//
// Note: These values were filled from:
// - android/app/google-services.json
// - ios/Runner/GoogleService-Info.plist
//
// If you later add Web/macOS/Windows apps in Firebase, prefer regenerating this
// file via FlutterFire CLI (`flutterfire configure`) to include those platforms.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) return web;
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyBMN3YpVwaEvvhv_b8ZxZUOTg79WmTqvjk',
    appId: '1:737044049717:android:8ccce8d76982c269b2667c',
    messagingSenderId: '737044049717',
    projectId: 'hr-sys-fa9d3',
    storageBucket: 'hr-sys-fa9d3.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCjtlFVwOP1gEfrHUqn7JJhucOtuSpulBQ',
    appId: '1:737044049717:ios:a2b248b1629990b3b2667c',
    messagingSenderId: '737044049717',
    projectId: 'hr-sys-fa9d3',
    storageBucket: 'hr-sys-fa9d3.firebasestorage.app',
    iosBundleId: 'com.company.hrsysapp',
  );

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'YOUR_WEB_API_KEY',
    appId: 'YOUR_WEB_APP_ID',
    messagingSenderId: 'YOUR_MESSAGING_SENDER_ID',
    projectId: 'YOUR_PROJECT_ID',
    storageBucket: 'YOUR_PROJECT_ID.appspot.com',
    authDomain: 'YOUR_PROJECT_ID.firebaseapp.com',
  );
}
