import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
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
          localizations.trackOrder, // "Track Order" from ARB
          style: const TextStyle(
            fontSize: DesignTokens.titleFontSize,
            color: DesignTokens.foregroundColor,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: DesignTokens.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColor),
      ),
      backgroundColor: DesignTokens.backgroundColor,
      body: Center(
        child: Text(
          '${localizations.orderNumber}: $orderId\n\nTracking info coming soon!',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: DesignTokens.bodyFontSize,
            color: DesignTokens.textColor,
            fontFamily: DesignTokens.fontFamily,
            fontWeight: DesignTokens.bodyFontWeight,
          ),
        ),
      ),
    );
  }
}
