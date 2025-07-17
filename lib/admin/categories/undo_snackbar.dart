import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

/// Shows a snackbar with "Undo" action.
/// Usage:
///   UndoSnackbar.show(context, message: "...", onUndo: () { ... });
class UndoSnackbar {
  static void show(
    BuildContext context, {
    required String message,
    required VoidCallback onUndo,
    Duration duration = const Duration(seconds: 6),
    String? undoLabel,
    void Function(SnackBarClosedReason reason)? onClosed,
  }) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Localization missing! [debug]')),
      );
      return;
    }
    final scaffold = ScaffoldMessenger.of(context);

    scaffold.hideCurrentSnackBar();
    scaffold
        .showSnackBar(
          SnackBar(
            content: Text(message),
            action: SnackBarAction(
              label: undoLabel ?? loc.undo,
              onPressed: onUndo,
            ),
            duration: duration,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            margin: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        )
        .closed
        .then((reason) {
      if (onClosed != null) onClosed(reason);
    });
  }
}
