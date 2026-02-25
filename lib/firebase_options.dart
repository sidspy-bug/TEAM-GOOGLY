import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

/// Firebase configuration for GrowthOS.
///
/// TODO: Replace these placeholder values with your actual Firebase project config.
/// You can find these in: Firebase Console → Project Settings → Web app.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    // Fallback to web for now (web-only app)
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCp8yy3ArPfiIBggD4pW8eevWIkDOTvzIA',
    appId: '1:257087354059:web:5a984cb4431e30313dd74e',
    messagingSenderId: '257087354059',
    projectId: 'team-googly',
    authDomain: 'team-googly.firebaseapp.com',
    storageBucket: 'team-googly.firebasestorage.app',
  );
}
