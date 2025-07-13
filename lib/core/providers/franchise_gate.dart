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

    // --- Show spinner until franchiseId loaded from storage ---
    if (franchiseProvider.loading) {
      return const MaterialApp(
        home: Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    if (!franchiseProvider.isFranchiseSelected) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FranchiseSelector(
          onSelected: (id) => franchiseProvider.setFranchiseId(id),
        ),
      );
    }

    return child;
  }
}
