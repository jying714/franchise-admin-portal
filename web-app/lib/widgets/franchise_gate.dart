// web_app/lib/core/widgets/franchise_gate.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/franchise_selector.dart';

class FranchiseGate extends StatelessWidget {
  final Widget child;
  const FranchiseGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final shared.franchiseProvider = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final user = shared.franchiseProvider.adminUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final roles = user.roles;
    final isFranchiseOptionalRole = roles.contains('platform_owner') ||
        roles.contains('developer') ||
        roles.contains('hq_owner');

    if (shared.franchiseProvider.loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (!shared.franchiseProvider.isFranchiseSelected && !isFranchiseOptionalRole) {
      return Scaffold(
        body: FranchiseSelector(
          onSelected: (id) => shared.franchiseProvider.setFranchiseId(id),
        ),
      );
    }

    return child;
  }
}


