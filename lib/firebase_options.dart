// lib/firebase_options.dart (Template)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      throw UnsupportedError(
        'DefaultFirebaseOptions have not been configured for web - '
        'you can reconfigure this by running the FlutterFire CLI again.',
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

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyARU_2NKAla4Kd_me9rTx2vnCAVjEv6bs4',
    appId: '1:933358808445:android:9df9647c260303b4c7b014',
    messagingSenderId: '933358808445',
    projectId: 'nounmobilelibrary',
    storageBucket: 'nounmobilelibrary.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyC6FGcGjc66xMkZfm8L1Iov6uNjv1MvMkc',
    appId: '1:933358808445:ios:f6699dc7cfdd813fc7b014',
    messagingSenderId: '933358808445',
    projectId: 'nounmobilelibrary',
    storageBucket: 'nounmobilelibrary.firebasestorage.app',
    iosBundleId: 'com.example.nounmobilelibrary',
  );
}
