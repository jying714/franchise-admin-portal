// File generated for Franchise Admin Web (Web-only project)
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart' show kIsWeb;

class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (!kIsWeb) {
      throw UnsupportedError('This config is only for web platform.');
    }
    return web;
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyBBlWVSua4QfPefy4TRPmOT_7ErfgAuZZ4',
    appId: '1:739021537990:web:e3804e106daad32cfe0dc7',
    messagingSenderId: '739021537990',
    projectId: 'doughboyspizzeria-2b3d2',
    authDomain: 'doughboyspizzeria-2b3d2.firebaseapp.com',
    storageBucket: 'doughboyspizzeria-2b3d2.firebasestorage.app',
    measurementId: 'G-SJRBLVVV5Z',
  );
}


