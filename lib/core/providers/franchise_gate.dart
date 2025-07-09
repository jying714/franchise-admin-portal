import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'franchise_selector.dart';
import 'franchise_provider.dart';

class FranchiseGate extends StatelessWidget {
  final Widget child;
  const FranchiseGate({required this.child, super.key});

  @override
  Widget build(BuildContext context) {
    final franchiseProvider = Provider.of<FranchiseProvider>(context);
    if (franchiseProvider.franchiseId == null) {
      // Wrap FranchiseSelector in MaterialApp so Scaffold gets Directionality
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: FranchiseSelector(
          onSelected: (id) => franchiseProvider.setFranchiseId(id),
        ),
      );
    }
    // FranchiseId is set, show the real app (which will itself be a MaterialApp)
    return child;
  }
}
