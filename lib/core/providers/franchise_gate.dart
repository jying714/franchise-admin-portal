import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'franchise_selector.dart';
import 'franchise_provider.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';

class FranchiseGate extends StatelessWidget {
  final Widget child;
  const FranchiseGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final franchiseProvider = Provider.of<FranchiseProvider>(context);
    final user = Provider.of<UserProfileNotifier>(context).user;
    print('[FranchiseGate] build called with child=${child.runtimeType}');

    // Wait for provider to finish loading franchiseId from storage
    if (franchiseProvider.loading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    // Determine roles
    final roles = user?.roles ?? [];
    final isHqOrDev = roles.contains('hq_owner') ||
        roles.contains('hq_manager') ||
        roles.contains('developer');

    // Only force franchise selection for users that MUST select a franchise
    if (!franchiseProvider.isFranchiseSelected && !isHqOrDev) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FranchiseSelector(
          onSelected: (id) => franchiseProvider.setFranchiseId(id),
        ),
      );
    }

    // All good: render the protected child
    return child;
  }
}
