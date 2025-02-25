import 'package:firebase_core/firebase_core.dart';
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

  // Method to initialize Firebase
  static Future<void> initializeFirebase() async {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyARE9dfde51ctB02Z2CG1eppzjZ6aQwLYw',
    appId: '1:278338625204:web:913f66a5782e8a7d86c1e1',
    messagingSenderId: '278338625204',
    projectId: 'safetrack-c363a',
    authDomain: 'safetrack-c363a.firebaseapp.com',
    storageBucket: 'safetrack-c363a.firebasestorage.app',
    measurementId: 'G-FB9W7KEKE4',
    databaseURL:
        'https://safetrack-c363a-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCe_TTIp2nVAEcooFTbTCMB_mZrS0FSXo0',
    appId: '1:278338625204:android:919b2805b97f396086c1e1',
    messagingSenderId: '278338625204',
    projectId: 'safetrack-c363a',
    storageBucket: 'safetrack-c363a.firebasestorage.app',
    databaseURL:
        'https://safetrack-c363a-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyDtaWjDYQH2sfx_sO2-DRk5dA3Lphezhwg',
    appId: '1:278338625204:ios:f461399923ec42ff86c1e1',
    messagingSenderId: '278338625204',
    projectId: 'safetrack-c363a',
    storageBucket: 'safetrack-c363a.firebasestorage.app',
    iosBundleId: 'com.example.capstone1',
    databaseURL:
        'https://safetrack-c363a-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyDtaWjDYQH2sfx_sO2-DRk5dA3Lphezhwg',
    appId: '1:278338625204:ios:f461399923ec42ff86c1e1',
    messagingSenderId: '278338625204',
    projectId: 'safetrack-c363a',
    storageBucket: 'safetrack-c363a.firebasestorage.app',
    iosBundleId: 'com.example.capstone1',
    databaseURL:
        'https://safetrack-c363a-default-rtdb.asia-southeast1.firebasedatabase.app',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyARE9dfde51ctB02Z2CG1eppzjZ6aQwLYw',
    appId: '1:278338625204:web:802e61be9d3e121e86c1e1',
    messagingSenderId: '278338625204',
    projectId: 'safetrack-c363a',
    authDomain: 'safetrack-c363a.firebaseapp.com',
    storageBucket: 'safetrack-c363a.firebasestorage.app',
    measurementId: 'G-THEVQSXY5C',
    databaseURL:
        'https://safetrack-c363a-default-rtdb.asia-southeast1.firebasedatabase.app',
  );
}
