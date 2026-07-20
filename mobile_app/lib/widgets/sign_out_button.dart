import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/confirmation_dialog.dart';

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
    super.key,
    required this.signOutLabel,
    required this.confirmationTitle,
    required this.confirmationMessage,
    required this.confirmLabel,
    required this.cancelLabel,
    required this.onSignOut,
  });

  @override
  Widget build(BuildContext context) {
    return ElevatedButton(
      style: ElevatedButton.styleFrom(
        backgroundColor: shared.UiConfig.errorColor,
        foregroundColor: shared.UiConfig.foregroundColor,
        padding: shared.UiConfig.defaultPadding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(shared.DesignTokens.buttonRadius),
        ),
        elevation: shared.DesignTokens.buttonElevation,
      ),
      onPressed: () async {
        final shouldSignOut = await ConfirmationDialog.show(
          context,
          title: confirmationTitle,
          message: confirmationMessage,
          icon: Icons.logout,
          confirmLabel: confirmLabel,
          cancelLabel: cancelLabel,
          confirmColor: shared.UiConfig.errorColor,
          onConfirm: () {}, // ConfirmationDialog requires onConfirm
        );
        if (shouldSignOut == true) {
          onSignOut();
        }
      },
      child: Text(
        signOutLabel,
        style: shared.UiConfig.bodyStyle.copyWith(
          fontWeight: shared.UiConfig.fontWeightBold,
        ),
      ),
    );
  }
}
