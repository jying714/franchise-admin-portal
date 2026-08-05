import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/widgets.dart';
import 'package:shared_core/shared_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import '../firebase_options.dart';

class PosBootstrap {
  PosBootstrap._();

  static Future<void> initFirebase() async {
    WidgetsFlutterBinding.ensureInitialized();
    if (Firebase.apps.isEmpty) {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    }
    // Same publishable key as mobile (never sk_). Empty → card falls back to mock.
    const stripePk = String.fromEnvironment('STRIPE_PK', defaultValue: '');
    if (stripePk.isNotEmpty) {
      Stripe.publishableKey = stripePk;
    }
    await ensureStationAuth();
  }

  /// Station needs a signed-in Auth user for staff get rules.
  /// Anonymous is MVP smoke only — replace with station/custom claims later.
  static Future<void> ensureStationAuth() async {
    final auth = FirebaseAuth.instance;
    if (auth.currentUser != null) {
      await auth.currentUser!.getIdToken(true);
      return;
    }

    const email = String.fromEnvironment(
      'STATION_AUTH_EMAIL',
      defaultValue: '',
    );
    const password = String.fromEnvironment(
      'STATION_AUTH_PASSWORD',
      defaultValue: '',
    );

    if (email.isEmpty || password.isEmpty) {
      throw StateError(
        'Station Auth required. Enable Anonymous in Firebase Console, '
        'or run with --dart-define=STATION_AUTH_EMAIL=... '
        'and --dart-define=STATION_AUTH_PASSWORD=...',
      );
    }

    await auth.signInWithEmailAndPassword(email: email, password: password);
    // Force claims/email onto the token used by Firestore rules.
    await auth.currentUser?.getIdToken(true);
  }

  /// Bound franchise for this station. No silent default tenant.
  /// Pass at run time: --dart-define=STATION_FRANCHISE_ID=<id>
  static Future<String?> loadFranchiseId() async {
    const fromDefine = String.fromEnvironment(
      'STATION_FRANCHISE_ID',
      defaultValue: '',
    );
    final id = fromDefine.trim();
    return id.isEmpty ? null : id;
  }

  /// FranchiseProvider requires a [LocalStorage] positional argument.
  static FranchiseProvider createFranchiseProvider(
    LocalStorage storage,
    String franchiseId,
  ) {
    final provider = FranchiseProvider(storage);
    // ignore: discarded_futures
    provider.setFranchiseId(franchiseId);
    return provider;
  }
}
