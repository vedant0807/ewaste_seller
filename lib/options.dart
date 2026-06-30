import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

/// Default [FirebaseOptions] for your project.
class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions are not configured for web.',
      );
    }

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

  /// Android Configuration
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: "AIzaSyD_8I-R9TeqYOS12sA086oFpuLVw9h5v64",
    appId: "1:286739534854:android:4d1a99c35adc398a135f87",
    messagingSenderId: "286739534854",
    projectId: "ewaste-9537d",
    storageBucket: "ewaste-9537d.firebasestorage.app",
  );

  /// iOS Configuration
  ///
  /// Replace these values with those from your GoogleService-Info.plist
  /// if you are building for iOS.
  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: "YOUR_IOS_API_KEY",
    appId: "YOUR_IOS_APP_ID",
    messagingSenderId: "286739534854",
    projectId: "ewaste-9537d",
    storageBucket: "ewaste-9537d.firebasestorage.app",
    iosBundleId: "com.ewaste.synise", // Change if your iOS bundle ID differs
  );
}