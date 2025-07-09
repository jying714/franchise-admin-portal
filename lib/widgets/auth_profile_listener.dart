import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'user_profile_notifier.dart';

class AuthProfileListener extends StatefulWidget {
  final String franchiseId; // Added franchiseId here
  final Widget child;

  const AuthProfileListener({
    required this.child,
    required this.franchiseId, // Require franchiseId
    super.key,
  });

  @override
  State<AuthProfileListener> createState() => _AuthProfileListenerState();
}

class _AuthProfileListenerState extends State<AuthProfileListener> {
  Object? _lastLoggedError;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);

    // Subscribe/re-subscribe to user profile on every dependency change.
    notifier.listenToUser(
        firestoreService, firebaseUser?.uid, widget.franchiseId);

    // Immediately check and log any error.
    _maybeLogProfileError(
        notifier, firebaseUser, firestoreService, widget.franchiseId);
  }

  @override
  void didUpdateWidget(AuthProfileListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    final firebaseUser = Provider.of<fb_auth.User?>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);

    _maybeLogProfileError(
        notifier, firebaseUser, firestoreService, widget.franchiseId);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);

    // If error is present and not logged, log it
    _maybeLogProfileError(
        notifier, firebaseUser, firestoreService, widget.franchiseId);

    return widget.child;
  }

  void _maybeLogProfileError(UserProfileNotifier notifier, fb_auth.User? user,
      FirestoreService firestoreService, String franchiseId) {
    if (notifier.lastError != null && notifier.lastError != _lastLoggedError) {
      _lastLoggedError = notifier.lastError;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await firestoreService.logError(
            franchiseId,
            message: 'UserProfileNotifier error: ${notifier.lastError}',
            source: 'AuthProfileListener',
            userId: user?.uid,
            screen: 'AuthProfileListener',
            stackTrace: notifier.lastError is Error
                ? (notifier.lastError as Error).stackTrace?.toString()
                : null,
            contextData: {
              'email': user?.email,
              'profileLoading': notifier.loading,
            },
          );
        } catch (e, stack) {
          print(
              '[AuthProfileListener] Failed to log error to Firestore: $e\n$stack');
        }
      });
    }
  }
}
