import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/services/auth_service.dart';

class ProfileLoadingGate extends StatelessWidget {
  final Widget Function(BuildContext, dynamic /*app.User*/) builder;
  const ProfileLoadingGate({required this.builder, Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final profileUser = Provider.of<AuthService>(context).profileUser;
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
