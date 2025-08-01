import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/user_profile_notifier.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

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
  bool _subscribed = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);
    final franchiseProvider =
        Provider.of<FranchiseProvider>(context, listen: false);

    // Attach listener only if not already attached
    if (!_subscribed) {
      _subscribed = true;

      // ✅ Listen for user changes and rerun routing when ready
      notifier.addListener(() {
        final user = notifier.user;
        final loading = notifier.loading;
        if (user != null) {
          // ✅ Inject into AdminUserProvider
          Provider.of<AdminUserProvider>(context, listen: false).user = user;
        }

        if (!_navigated && !loading && firebaseUser != null && user != null) {
          _maybeLogProfileError(notifier, firebaseUser, firestoreService);
          _handleRouting(notifier, firebaseUser, franchiseProvider);
        }
      });
    }

    // Franchise-agnostic: only pass uid!
    notifier.listenToUser(firestoreService, firebaseUser?.uid);
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
  ) {
    final user = notifier.user;
    if (_navigated || firebaseUser == null || user == null || notifier.loading)
      return;

    // If user account is not active
    if (user.status.toLowerCase() != 'active') {
      _navigated = true;
      print(
          '[DEBUG-NAV] Attempting to navigate to /developer/select-franchise from <filename>:<linenumber>');
      Navigator.of(context).pushReplacementNamed('/unauthorized');
      return;
    }

    // HQ Owner/Manager: go to HQ dashboard
    if (user.isHqOwner || user.isHqManager) {
      _navigated = true;
      print(
          '[DEBUG-NAV] Attempting to navigate to /developer/select-franchise from <filename>:<linenumber>');
      Navigator.of(context).pushReplacementNamed('/hq-owner/dashboard');
      return;
    }

    // Developer: go to dev dashboard or franchise selector
    if (user.isDeveloper) {
      final selected = franchiseProvider.isFranchiseSelected;
      _navigated = true;
      print(
          '[DEBUG-NAV] AUTH PROFILE LISTENER Routing to dev dashboard or franchise selector screen');
      print(
          '[DEBUG-NAV] Attempting to navigate to /developer/select-franchise from <filename>:<linenumber>');

      Navigator.of(context).pushReplacementNamed(
        selected ? '/developer/dashboard' : '/developer/select-franchise',
      );
      return;
    }

    // Owner/Manager: only set franchise and route if defaultFranchise is available
    if (user.isOwner || user.isManager) {
      final lockedId = user.defaultFranchise;
      if (lockedId == null || lockedId.isEmpty) {
        // Optionally, route to an error page or franchise selector if needed
        _navigated = true;
        print(
            '[DEBUG-NAV] Attempting to navigate to /developer/select-franchise from <filename>:<linenumber>');

        Navigator.of(context).pushReplacementNamed('/unauthorized');
        return;
      }
      if (franchiseProvider.franchiseId != lockedId) {
        franchiseProvider.setFranchiseId(lockedId);
      }
      _navigated = true;
      print(
          '[DEBUG-NAV] Attempting to navigate to /developer/select-franchise from <filename>:<linenumber>');

      Navigator.of(context).pushReplacementNamed('/admin/dashboard');
      return;
    }

    // All other users: implement routing as needed
    // e.g. if customer, show a customer homepage, etc.
    // For now, do nothing; you may want to add additional cases
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
          await ErrorLogger.log(
            message: 'UserProfileNotifier error: ${notifier.lastError}',
            source: 'AuthProfileListener',
            screen: 'AuthProfileListener',
            stack: notifier.lastError is Error
                ? (notifier.lastError as Error).stackTrace?.toString()
                : null,
            contextData: {
              'userId': user?.uid,
              'email': user?.email,
              'profileLoading': notifier.loading,
            },
          );
        } catch (e, stack) {
          // Logging error; just print for dev, skip for prod
        }
      });
    }
  }
}
