import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/branded_loading_screen.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';

import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/developer/developer_dashboard_screen.dart';
import 'package:franchise_admin_portal/admin/franchise/franchise_selector_screen.dart';

class HomeWrapper extends StatelessWidget {
  final String franchiseId;
  const HomeWrapper({required this.franchiseId, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final profileNotifier = Provider.of<UserProfileNotifier>(context);
    final franchiseProvider =
        Provider.of<FranchiseProvider>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;

    // 1. Not logged in
    if (firebaseUser == null) {
      return const SignInScreen();
    }

    // 2. Loading
    if (profileNotifier.loading || franchiseProvider.loading) {
      return const BrandedLoadingScreen();
    }

    // 3. Error loading profile
    if (profileNotifier.lastError != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        try {
          await firestoreService.logError(
            franchiseProvider.franchiseId,
            message: 'User profile load error: ${profileNotifier.lastError}',
            source: 'HomeWrapper',
            userId: firebaseUser.uid,
            screen: 'HomeWrapper',
            stackTrace: profileNotifier.lastError is Error
                ? (profileNotifier.lastError as Error).stackTrace?.toString()
                : null,
            contextData: {
              'email': firebaseUser.email,
              'profileLoading': profileNotifier.loading,
            },
          );
        } catch (e, stack) {
          print('[HomeWrapper] Failed to log error: $e\n$stack');
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

    // 4. Fallback check
    if (appUser == null) {
      return const BrandedLoadingScreen();
    }

    // 5. Status check
    if (appUser.status?.toLowerCase() != 'active') {
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

    // 6. Developer flow: show franchise selector first
    if (appUser.isDeveloper) {
      if (!franchiseProvider.isFranchiseSelected) {
        return const FranchiseSelectorScreen();
      }
      return const DeveloperDashboardScreen();
    }

    // 7. Admin/Manager/Owner flow: auto-lock to defaultFranchise
    final lockedFranchise = appUser.defaultFranchise ?? 'unknown';
    if (franchiseProvider.franchiseId != lockedFranchise) {
      franchiseProvider.setFranchiseId(lockedFranchise);
      return const BrandedLoadingScreen();
    }

    // 8. All good — show Admin Dashboard
    Widget result = const AdminDashboardScreen();

    // 9. Fallback (should never hit)
    if (result == null) {
      print('[HomeWrapper] Fallback reached — unexpected state.');
      return Scaffold(
        appBar: AppBar(title: Text(loc.adminDashboardTitle)),
        body: const Center(
          child: Text('Unexpected state. Please restart the app.'),
        ),
      );
    }

    return result;
  }
}
