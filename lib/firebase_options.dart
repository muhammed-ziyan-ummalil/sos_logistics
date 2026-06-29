// Firebase options for the dedicated logistics app (com.sossss.logistics) in
// the sos-6b1be project. Values mirror android/app/google-services.json. To
// regenerate, run `flutterfire configure --project=sos-6b1be` from this
// directory and select the com.sossss.logistics app.

import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform;
import 'package:firebase_core/firebase_core.dart';

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      default:
        throw UnsupportedError(
            'DefaultFirebaseOptions have not been configured for platform: '
            '$defaultTargetPlatform. Run flutterfire configure.');
    }
  }

  // Dedicated logistics Android app (com.sossss.logistics) in the sos-6b1be
  // Firebase project. Values from the project's google-services.json.
  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCmxmaKVuCx-oG6gcR13qZkYKhMTwcoPYQ',
    appId: '1:954237017102:android:7227d90bb07f981919305f',
    messagingSenderId: '954237017102',
    projectId: 'sos-6b1be',
    storageBucket: 'sos-6b1be.firebasestorage.app',
  );
}
