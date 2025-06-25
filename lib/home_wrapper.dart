import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/user.dart';
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final firebaseUser = Provider.of<fb_auth.User?>(context);
    final appUser = Provider.of<User?>(context);
    final loc = AppLocalizations.of(context)!;

    if (firebaseUser == null) {
      // Not signed in: show sign in
      return const SignInScreen();
    }

    // If Firestore user not loaded yet, show loading
    if (appUser == null) {
      // Optionally, you can trigger loading user profile here if needed
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!(appUser.isOwner || appUser.isAdmin || appUser.isManager)) {
      // Signed in, but not authorized
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

    // Authorized admin user: show dashboard
    return const AdminDashboardScreen();
  }
}
