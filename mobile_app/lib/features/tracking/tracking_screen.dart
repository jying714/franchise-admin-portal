import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class TrackingScreen extends StatelessWidget {
  final String orderId;
  const TrackingScreen({super.key, required this.orderId});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.trackOrder,
          style: TextStyle(
            fontSize: shared.DesignTokens.titleFontSize,
            color: UiConfig.foregroundColor,
            fontWeight: UiConfig.bold,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: UiConfig.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: UiConfig.foregroundColor),
      ),
      backgroundColor: UiConfig.backgroundColor,
      body: Center(
        child: Text(
          '${localizations.orderNumber}: $orderId\n\nTracking info coming soon!',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: shared.DesignTokens.bodyFontSize,
            color: UiConfig.textColor,
            fontFamily: shared.DesignTokens.fontFamily,
            fontWeight: UiConfig.normal,
          ),
        ),
      ),
    );
  }
}
