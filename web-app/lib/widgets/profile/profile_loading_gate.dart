import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/

class ProfileLoadingGate extends StatelessWidget {
  final Widget Function(BuildContext, dynamic /*app.User*/) builder;
  const ProfileLoadingGate({required this.builder, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profileUser = Provider.of<shared.AuthService>(context).currentUser;
    if (profileUser == null) {
      return const Scaffold(
        body: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }
    return builder(context, profileUser);
  }
}
