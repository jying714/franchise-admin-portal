import 'package:flutter/material.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';

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
        backgroundColor: DesignTokens.secondaryColor,
        foregroundColor: DesignTokens.foregroundColor,
        padding: DesignTokens.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        elevation: DesignTokens.buttonElevation,
        textStyle: const TextStyle(
          fontSize: DesignTokens.bodyFontSize,
          fontWeight: DesignTokens.titleFontWeight,
          fontFamily: DesignTokens.fontFamily,
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


