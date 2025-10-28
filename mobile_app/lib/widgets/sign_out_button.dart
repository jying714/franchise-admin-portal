import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/widgets/confirmation_dialog.dart';

/// A reusable sign out button with built-in confirmation dialog.
/// Use in any screen where sign-out is needed for consistent UX.
class SignOutButton extends StatelessWidget {
  final String signOutLabel;
  final String confirmationTitle;
  final String confirmationMessage;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onSignOut;

  const SignOutButton({
    Key? key,
    required this.signOutLabel,
    required this.confirmationTitle,
    required this.confirmationMessage,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onSignOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.errorColor,
        foregroundColor: DesignTokens.foregroundColor,
        padding: DesignTokens.buttonPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DesignTokens.buttonRadius),
        ),
        elevation: DesignTokens.buttonElevation,
      ),
      onPressed: () async {
        final shouldSignOut = await ConfirmationDialog.show(
          context,
          title: confirmationTitle,
          message: confirmationMessage,
          icon: Icons.logout,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          confirmColor: DesignTokens.errorColor,
          onConfirm: () {}, // ConfirmationDialog requires onConfirm
        );
        if (shouldSignOut == true) {
          onSignOut();
        }
      },
      child: Text(
        signOutLabel,
        style: const TextStyle(
          fontSize: DesignTokens.bodyFontSize,
          fontFamily: DesignTokens.fontFamily,
          fontWeight: DesignTokens.bodyFontWeight,
        ),
      ),
    );
  }
}
