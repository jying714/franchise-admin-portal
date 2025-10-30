import 'package:flutter/material.dart';

class DebugAdminDashboardScreen extends StatelessWidget {
  const DebugAdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    print('DebugAdminDashboardScreen build called!');
    return Scaffold(
      appBar: AppBar(title: Text('Debug Admin Dashboard Screen')),
      body: Center(
        child: Text(
          'If you see this, the dashboard widget tree is working.',
          style: TextStyle(fontSize: 24, color: Colors.blue),
        ),
      ),
    );
  }
}
