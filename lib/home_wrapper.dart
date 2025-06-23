import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/user.dart';
import 'package:franchise_admin_portal/admin/sign_in/sign_in_screen.dart';
import 'package:franchise_admin_portal/admin/dashboard/admin_dashboard_screen.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class HomeWrapper extends StatelessWidget {
  const HomeWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<User?>(context);
    final loc = AppLocalizations.of(context)!;

    if (user == null) {
      // Not signed in: show sign in
      return const SignInScreen();
    }

    if (!(user.isOwner || user.isAdmin || user.isManager)) {
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
