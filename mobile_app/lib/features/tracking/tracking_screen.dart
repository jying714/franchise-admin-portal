import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/generated/app_localizations.dart';

class TrackingScreen extends StatelessWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: FranchiseAppBar(
        title: localizations.trackOrder,
        showLogo: false,
        backgroundColor: Theme.of(context).colorScheme.primary,
        foregroundColor: Theme.of(context).colorScheme.onPrimary,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: Theme.of(context).colorScheme.background,
      body: Center(
        child: Text(
          '${localizations.orderNumber}: $orderId\n\nTracking info coming soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: shared.DesignTokens.bodyFontSize,
            color: Theme.of(context).colorScheme.onSurface,
            fontFamily: shared.DesignTokens.fontFamily,
            fontWeight: shared.UiConfig.normal,
          ),
        ),
      ),
    );
  }
}
