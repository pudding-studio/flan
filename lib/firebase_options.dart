// File generated based on FlutterFire configuration.
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for macos - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      case TargetPlatform.windows:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
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

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyD40jClAGm5q1zqPAyTaCzdZzl9LE05Ijg',
    appId: '1:136734250749:web:d4586e170a16e8d6f5d094',
    messagingSenderId: '136734250749',
    projectId: 'flan-9926c',
    authDomain: 'flan-9926c.firebaseapp.com',
    storageBucket: 'flan-9926c.firebasestorage.app',
    measurementId: 'G-BRQ0E8F2SS',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyAPFlGq4sYaMxN32Uk3D9_sHEllnMSaL38',
    appId: '1:136734250749:android:5b48d3d1810f5825f5d094',
    messagingSenderId: '136734250749',
    projectId: 'flan-9926c',
    storageBucket: 'flan-9926c.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyD_noeGCtRmnNfsHbaqTBMpIIxkHLOM9FM',
    appId: '1:136734250749:ios:0554adc49bdd69d1f5d094',
    messagingSenderId: '136734250749',
    projectId: 'flan-9926c',
    storageBucket: 'flan-9926c.firebasestorage.app',
    iosBundleId: 'com.example.flan',
  );
}
