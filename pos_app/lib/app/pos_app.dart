import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../features/home/station_home_screen.dart';
import '../features/session/pin_unlock_screen.dart';
import '../providers/pin_session_provider.dart';
import 'theme.dart';

class PosApp extends StatelessWidget {
  final String franchiseId;

  const PosApp({super.key, required this.franchiseId});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'POS Station',
      debugShowCheckedModeBanner: false,
      theme: buildPosTheme(),
      home: Consumer<PinSessionProvider>(
        builder: (context, session, _) {
          if (!session.isUnlocked) {
            return PinUnlockScreen(
              franchiseId: franchiseId,
              onUnlocked: () {
                // Consumer rebuilds on notifyListeners from unlock().
              },
            );
          }
          return StationHomeScreen(franchiseId: franchiseId);
        },
      ),
    );
  }
}

/// Shown when no franchise is bound to this device.
class PosBindRequiredScreen extends StatelessWidget {
  const PosBindRequiredScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: buildPosTheme(),
      home: Scaffold(
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Station not bound to a franchise.\n\n'
              'Launch with:\n'
              '--dart-define=STATION_FRANCHISE_ID=<franchiseId>',
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }
}
