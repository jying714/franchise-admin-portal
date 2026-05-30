import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';

/// Button for launching customization modal before adding to cart.
/// Accepts loading state and a callback for tap.
class CustomizeAndAddToCartButton extends StatelessWidget {
  final bool isProcessing;
  final VoidCallback? onPressed;
  final String? label;

  const CustomizeAndAddToCartButton({
    super.key,
    required this.isProcessing,
    required this.onPressed,
    this.label,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: UiConfig.secondaryColor,
        foregroundColor: UiConfig.foregroundColor,
        padding: UiConfig.defaultPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shared.DesignTokens.buttonRadius),
        ),
        elevation: shared.DesignTokens.buttonElevation,
        textStyle: TextStyle(
          fontSize: shared.DesignTokens.bodyFontSize,
          fontWeight: UiConfig.fontWeightBold,
          fontFamily: shared.DesignTokens.fontFamily,
        ),
      ),
      onPressed: isProcessing ? null : onPressed,
      child: isProcessing
          ? const SizedBox(
              width: 22,
              height: 22,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Text(label ?? 'Customize'),
    );
  }
}
