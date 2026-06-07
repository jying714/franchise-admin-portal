import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/core/providers/user_profile_notifier_impl.dart'
    show UserProfileNotifier;

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
    final firestoreService = Provider.of<shared.FirestoreService>(
      context,
      listen: false,
    );
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);
    final franchiseProvider = Provider.of<shared.FranchiseProvider>(
      context,
      listen: false,
    );

    if (!_subscribed) {
      _subscribed = true;

      notifier.addListener(() {
        final user = notifier.user;
        final loading = notifier.loading;

        if (!_navigated && !loading && firebaseUser != null && user != null) {
          _maybeLogProfileError(notifier, firebaseUser, firestoreService);
          _handleRouting(notifier, firebaseUser, franchiseProvider);
        }
      });
    }

    notifier.listenToUser(firebaseUser?.uid);
  }

  @override
  void didUpdateWidget(AuthProfileListener oldWidget) {
    super.didUpdateWidget(oldWidget);
    final firebaseUser = Provider.of<fb_auth.User?>(context, listen: false);
    final firestoreService = Provider.of<shared.FirestoreService>(
      context,
      listen: false,
    );
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);

    _maybeLogProfileError(notifier, firebaseUser, firestoreService);
  }

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final firestoreService = Provider.of<shared.FirestoreService>(
      context,
      listen: false,
    );
    final notifier = Provider.of<UserProfileNotifier>(context, listen: false);

    _maybeLogProfileError(notifier, firebaseUser, firestoreService);
    return widget.child;
  }

  void _handleRouting(
    UserProfileNotifier notifier,
    fb_auth.User? firebaseUser,
    shared.FranchiseProvider franchiseProvider,
  ) {
    if (!mounted) return;

    final user = notifier.user;
    if (_navigated ||
        firebaseUser == null ||
        user == null ||
        notifier.loading) {
      return;
    }

    // Skip navigation for HQ Owner since we are already in the correct dashboard
    if (user.isHqOwner || user.isHqManager) {
      _navigated = true;
      debugPrint(
          '[AuthProfileListener] HQ Owner detected - skipping navigation');
      return;
    }

    if (user.status.toLowerCase() != 'active') {
      _navigated = true;
      if (mounted) Navigator.of(context).pushReplacementNamed('/unauthorized');
      return;
    }

    if (user.isDeveloper) {
      final selected = franchiseProvider.isFranchiseSelected;
      _navigated = true;
      if (mounted) {
        Navigator.of(context).pushReplacementNamed(
          selected ? '/developer/dashboard' : '/developer/select-franchise',
        );
      }
      return;
    }

    if (user.isOwner || user.isManager) {
      final lockedId = user.defaultFranchise;
      if (lockedId == null || lockedId.isEmpty) {
        _navigated = true;
        if (mounted)
          Navigator.of(context).pushReplacementNamed('/unauthorized');
        return;
      }
      if (franchiseProvider.franchiseId != lockedId) {
        franchiseProvider.setFranchiseId(lockedId);
      }
      _navigated = true;
      if (mounted)
        Navigator.of(context).pushReplacementNamed('/admin/dashboard');
      return;
    }
  }

  void _maybeLogProfileError(
    UserProfileNotifier notifier,
    fb_auth.User? user,
    shared.FirestoreService firestoreService,
  ) {
    if (notifier.lastError != null && notifier.lastError != _lastLoggedError) {
      _lastLoggedError = notifier.lastError;
      debugPrint(
          '[AuthProfileListener] UserProfileNotifier error: ${notifier.lastError}');
    }
  }
}
