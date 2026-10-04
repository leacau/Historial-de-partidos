import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart' show defaultTargetPlatform, TargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      default:
        return android;
    }
  }

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyB2YOtlvwoLijU4mriwsO3LUTysQojHhv8',
    appId: '1:561211790247:android:2a560cbe1ee617591e1c82',
    messagingSenderId: '561211790247',
    projectId: 'futbol-salvi',
    storageBucket: 'futbol-salvi.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyB2YOtlvwoLijU4mriwsO3LUTysQojHhv8',
    appId: '1:561211790247:ios:2a560cbe1ee617591e1c82',
    messagingSenderId: '561211790247',
    projectId: 'futbol-salvi',
    storageBucket: 'futbol-salvi.firebasestorage.app',
    iosBundleId: 'com.leaestudio.partidosPro',
  );
}
