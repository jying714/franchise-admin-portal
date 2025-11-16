// web_app/lib/core/widgets/franchise_gate.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

class FranchiseGate extends StatelessWidget {
  final Widget child;
  const FranchiseGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final franchiseProvider = Provider.of<FranchiseProvider>(context);
    final user = Provider.of<AdminUserProvider>(context).user;

    if (user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final roles = user.roles;
    final isFranchiseOptionalRole = roles.contains('platform_owner') ||
        roles.contains('developer') ||
        roles.contains('hq_owner');

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
