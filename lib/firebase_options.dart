import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

class DefaultFirebaseOptions {
  const DefaultFirebaseOptions._();

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
          'Firebase options have not been configured for Linux.',
        );
      case TargetPlatform.fuchsia:
        throw UnsupportedError(
          'Firebase options have not been configured for Fuchsia.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyAXPSYLzIv1OWfpa4RSPes_RvJM9BqGJfs',
    appId: '1:200583921993:web:1e0057c76de2eaf5435a98',
    messagingSenderId: '200583921993',
    projectId: 'cce106-3e137',
    authDomain: 'cce106-3e137.firebaseapp.com',
    storageBucket: 'cce106-3e137.firebasestorage.app',
    measurementId: 'G-GRZFJNQ3QB',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAcaa4qPpLcX3viH362p2g7z_jUVQCY5M4',
    appId: '1:200583921993:android:af033c55642fff43435a98',
    messagingSenderId: '200583921993',
    projectId: 'cce106-3e137',
    storageBucket: 'cce106-3e137.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCw56AwiBPaf7ClDxVvgGEaS--i9o8MWLU',
    appId: '1:200583921993:ios:2b91ecbc9c8d2d86435a98',
    messagingSenderId: '200583921993',
    projectId: 'cce106-3e137',
    storageBucket: 'cce106-3e137.firebasestorage.app',
    iosBundleId: 'com.example.pharmacyMarketplaceApp',
  );

  static const FirebaseOptions macos = ios;

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyAXPSYLzIv1OWfpa4RSPes_RvJM9BqGJfs',
    appId: '1:200583921993:web:1e0057c76de2eaf5435a98',
    messagingSenderId: '200583921993',
    projectId: 'cce106-3e137',
    authDomain: 'cce106-3e137.firebaseapp.com',
    storageBucket: 'cce106-3e137.firebasestorage.app',
    measurementId: 'G-GRZFJNQ3QB',
  );
}
