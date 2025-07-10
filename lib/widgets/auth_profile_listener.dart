import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;

class AuthProfileListener extends StatefulWidget {
  final Widget child;

  const AuthProfileListener({
    required this.child,
    super.key,
  });

  @override
  State<AuthProfileListener> createState() => _AuthProfileListenerState();
}

class _AuthProfileListenerState extends State<AuthProfileListener> {
  Object? _lastLoggedError;
  bool _navigated = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);
    final franchiseProvider =
        Provider.of<FranchiseProvider>(context, listen: false);

    // Subscribe to user profile based on current firebase user
    notifier.listenToUser(firestoreService, firebaseUser?.uid, '');

    // Log errors and route after profile loads
    _maybeLogProfileError(notifier, firebaseUser, firestoreService);
    _handleRouting(notifier, firebaseUser, franchiseProvider);
  }

  @override
  void didUpdateWidget(AuthProfileListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    final firebaseUser = Provider.of<fb_auth.User?>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);

    _maybeLogProfileError(notifier, firebaseUser, firestoreService);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);

    _maybeLogProfileError(notifier, firebaseUser, firestoreService);
    return widget.child;
  }

  void _handleRouting(
    UserProfileNotifier notifier,
    fb_auth.User? firebaseUser,
    FranchiseProvider franchiseProvider,
  ) async {
    final user = notifier.user;
    if (_navigated || firebaseUser == null || user == null || notifier.loading)
      return;

    if (user.status != 'active') {
      _navigated = true;
      Navigator.of(context).pushReplacementNamed('/unauthorized');
      return;
    }

    _navigated = true;
    franchiseProvider.setAdminUser(user);

    if (user.isDeveloper) {
      Navigator.of(context).pushReplacementNamed('/developer/dashboard');
    } else {
      await franchiseProvider
          .setInitialFranchiseId(user.defaultFranchise ?? '');
      Navigator.of(context).pushReplacementNamed('/admin/dashboard');
    }
  }

  void _maybeLogProfileError(
    UserProfileNotifier notifier,
    fb_auth.User? user,
    FirestoreService firestoreService,
  ) {
    if (notifier.lastError != null && notifier.lastError != _lastLoggedError) {
      _lastLoggedError = notifier.lastError;
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await firestoreService.logError(
            '', // fallback franchise context unavailable here
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
          print('[AuthProfileListener] Failed to log error: $e\n$stack');
        }
      });
    }
  }
}
