import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'app/bootstrap.dart';
import 'app/pos_app.dart';
import 'providers/pin_session_provider.dart';
import 'services/pos_printer_config.dart';

Future<void> main() async {
  await PosBootstrap.initFirebase();
  await PosPrinterConfig.load();

  final franchiseId = await PosBootstrap.loadFranchiseId();
  if (franchiseId == null) {
    runApp(const PosBindRequiredScreen());
    return;
  }

  // Optional: attach FranchiseProvider when setFranchiseId API is confirmed.
  // final franchiseProvider = PosBootstrap.createFranchiseProvider(franchiseId);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => PinSessionProvider()),
        // ChangeNotifierProvider.value(value: franchiseProvider),
      ],
      child: PosApp(franchiseId: franchiseId),
    ),
  );
}
