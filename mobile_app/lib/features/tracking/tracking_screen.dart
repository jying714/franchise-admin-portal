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
        backgroundColor: shared.UiConfig.primaryColor,
        foregroundColor: shared.UiConfig.foregroundColor,
        centerTitle: true,
        elevation: 0,
      ),
      backgroundColor: shared.UiConfig.backgroundColor,
      body: Center(
        child: Text(
          '${localizations.orderNumber}: $orderId\n\nTracking info coming soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: shared.DesignTokens.bodyFontSize,
            color: shared.UiConfig.textColor,
            fontFamily: shared.DesignTokens.fontFamily,
            fontWeight: shared.UiConfig.normal,
          ),
        ),
      ),
    );
  }
}
