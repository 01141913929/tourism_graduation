// File generated manually - replace with `flutterfire configure` output
// This is a placeholder file. Run `flutterfire configure` to generate the actual file.

import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default Firebase configuration options for the current platform.
///
/// IMPORTANT: This is a placeholder file. You need to:
/// 1. Install FlutterFire CLI: `dart pub global activate flutterfire_cli`
/// 2. Run: `flutterfire configure`
/// 3. Select your Firebase project
/// 4. This file will be replaced with actual configuration
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
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  // TODO: Replace these placeholder values with your actual Firebase configuration
  // Run `flutterfire configure` to generate the correct values

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD_D4KSkpjoDjN32xPVKcgOnCD30hqyHGw',
    appId: '1:730644883494:web:f8847dbb274019285c5ee7',
    messagingSenderId: '730644883494',
    projectId: 'egyptian-tourism-app',
    authDomain: 'egyptian-tourism-app.firebaseapp.com',
    storageBucket: 'egyptian-tourism-app.firebasestorage.app',
    measurementId: 'G-9CLQM5EYJ5',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyDSxc3g6k1eswoio2b8neQ4NRb63csJuI0',
    appId: '1:730644883494:android:ed9fe724e4422c795c5ee7',
    messagingSenderId: '730644883494',
    projectId: 'egyptian-tourism-app',
    storageBucket: 'egyptian-tourism-app.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDeyCDTH0C1bB1PGbh11mnB49X1ICDfBmg',
    appId: '1:730644883494:ios:c1760e878549411f5c5ee7',
    messagingSenderId: '730644883494',
    projectId: 'egyptian-tourism-app',
    storageBucket: 'egyptian-tourism-app.firebasestorage.app',
    iosClientId: '730644883494-hq5sdlbc8k8vm5qvhffrqk6bq8cq1e5f.apps.googleusercontent.com',
    iosBundleId: 'com.egyptiantourism.egyptianTourismApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDeyCDTH0C1bB1PGbh11mnB49X1ICDfBmg',
    appId: '1:730644883494:ios:c1760e878549411f5c5ee7',
    messagingSenderId: '730644883494',
    projectId: 'egyptian-tourism-app',
    storageBucket: 'egyptian-tourism-app.firebasestorage.app',
    iosClientId: '730644883494-hq5sdlbc8k8vm5qvhffrqk6bq8cq1e5f.apps.googleusercontent.com',
    iosBundleId: 'com.egyptiantourism.egyptianTourismApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyD_D4KSkpjoDjN32xPVKcgOnCD30hqyHGw',
    appId: '1:730644883494:web:0d28d9dfbe8f1e575c5ee7',
    messagingSenderId: '730644883494',
    projectId: 'egyptian-tourism-app',
    authDomain: 'egyptian-tourism-app.firebaseapp.com',
    storageBucket: 'egyptian-tourism-app.firebasestorage.app',
    measurementId: 'G-KXVYK4JY2Q',
  );

}