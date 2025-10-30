import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'franchise_selector.dart';
import 'franchise_provider.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';

class FranchiseGate extends StatelessWidget {
  final Widget child;
  const FranchiseGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final franchiseProvider = Provider.of<FranchiseProvider>(context);
    final user = Provider.of<AdminUserProvider>(context).user;

    if (user == null) {
      print('[FranchiseGate] ⏳ Admin user not yet available.');
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final roles = user.roles;
    final isFranchiseOptionalRole = roles.contains('platform_owner') ||
        roles.contains('developer') ||
        roles.contains('hq_owner');

    print('[FranchiseGate] build() for ${child.runtimeType}');
    print('[FranchiseGate] Roles: $roles');
    print(
        '[FranchiseGate] Franchise selected: ${franchiseProvider.isFranchiseSelected}');
    print(
        '[FranchiseGate] FranchiseProvider loading: ${franchiseProvider.loading}');

    if (franchiseProvider.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!franchiseProvider.isFranchiseSelected && !isFranchiseOptionalRole) {
      return Scaffold(
        body: FranchiseSelector(
          onSelected: (id) => franchiseProvider.setFranchiseId(id),
        ),
      );
    }

    return child;
  }
}
