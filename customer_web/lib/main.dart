// customer_web/lib/main.dart
import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:firebase_auth/firebase_auth.dart';
import 'app.dart';
import 'core/app_local_storage.dart';
import 'firebase_options.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:flutter_stripe_web/flutter_stripe_web.dart';

void main() {
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
  };

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final storage = AppLocalStorage();
      // Touch prefs once so getString can use the cache later.
      await SharedPreferencesBootstrap.warm(storage);

      final firestoreService = shared.FirestoreServiceImpl();

      const stripePk = String.fromEnvironment('STRIPE_PK', defaultValue: '');
      if (stripePk.isNotEmpty) {
        Stripe.publishableKey = stripePk;
        await Stripe.instance.applySettings();
        debugPrint('[stripe] ready (${stripePk.substring(0, 12)}…)');
      } else {
        debugPrint(
          '[stripe] STRIPE_PK empty — set --dart-define=STRIPE_PK=pk_test_…',
        );
      }

      runApp(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<shared.FranchiseProvider>(
              lazy: false,
              create: (_) => shared.FranchiseProvider(storage),
            ),
            Provider<shared.FirestoreService>.value(value: firestoreService),
            Provider<shared.LocalStorage>.value(value: storage),
            StreamProvider<User?>.value(
              value: FirebaseAuth.instance.authStateChanges(),
              initialData: FirebaseAuth.instance.currentUser,
            ),
          ],
          child: const CustomerWebApp(),
        ),
      );
    },
    (Object error, StackTrace stack) {
      debugPrint('[customer_web] uncaught: $error\n$stack');
    },
  );
}

/// One-shot warm so SharedPreferences is loaded before any sync getString.
class SharedPreferencesBootstrap {
  static Future<void> warm(AppLocalStorage storage) async {
    // Force the late Future to complete by writing a no-op touch key then removing.
    await storage.setString('_warm', '1');
    await storage.remove('_warm');
  }
}
