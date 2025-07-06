import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';

/// This widget gates all admin/dashboard content based on user and profile state.
class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final profileNotifier = Provider.of<UserProfileNotifier>(context);
    final loc = AppLocalizations.of(context)!;

    print('HomeWrapper build called');
    print('firebaseUser: $firebaseUser');
    print('appUser: ${profileNotifier.user}');
    print('appUser runtimeType: ${profileNotifier.user?.runtimeType}');

    // 1. Not logged in (no Firebase user) => Sign-in
    if (firebaseUser == null) {
      print('firebaseUser: null (not signed in)');
      return const SignInScreen();
    }

    // 2. Loading Firestore user profile
    if (profileNotifier.loading) {
      print('appUser loading...');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 3. Profile loading error
    if (profileNotifier.lastError != null) {
      print('Profile load error: ${profileNotifier.lastError}');
      // Log to Firestore once (you can debounce or track state if needed)
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          final firestoreService =
              Provider.of<FirestoreService>(context, listen: false);
          final user = Provider.of<fb_auth.User?>(context, listen: false);
          await firestoreService.logError(
            message: 'User profile load error: ${profileNotifier.lastError}',
            source: 'HomeWrapper',
            userId: user?.uid,
            screen: 'HomeWrapper',
            stackTrace: profileNotifier.lastError is Error
                ? (profileNotifier.lastError as Error).stackTrace?.toString()
                : null,
            contextData: {
              'email': user?.email,
              'profileLoading': profileNotifier.loading,
            },
          );
        } catch (e, stack) {
          print('[HomeWrapper] Failed to log error to Firestore: $e\n$stack');
        }
      });
      return Scaffold(
        appBar: AppBar(title: Text(loc.adminDashboardTitle)),
        body: Center(
          child: Text(
            'Error loading user profile: ${profileNotifier.lastError}',
            style: const TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    final appUser = profileNotifier.user;

    // 4. Still null for some reason (shouldn't happen, but fallback)
    if (appUser == null) {
      print('appUser is null, still loading user profile...');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // 5. Profile loaded, but not an admin/manager/owner (not authorized)
    if (!(appUser.isOwner || appUser.isAdmin || appUser.isManager)) {
      print('User is not authorized (role: ${appUser.role})');
      return Scaffold(
        appBar: AppBar(title: Text(loc.adminDashboardTitle)),
        body: Center(
          child: Text(
            loc.unauthorizedAccess,
            style: const TextStyle(fontSize: 18, color: Colors.red),
          ),
        ),
      );
    }

    // 6. All checks pass—show the real dashboard
    print('User is authorized: ${appUser.role}');
    return const AdminDashboardScreen();
  }
}
