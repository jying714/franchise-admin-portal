import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AdminDeleteConfirmDialog extends StatelessWidget {
  /// Number of items to delete, for localization prompt.
  final int itemCount;

  /// Optionally override title/content if needed.
  final String? titleOverride;
  final String? contentOverride;

  const AdminDeleteConfirmDialog({
    Key? key,
    required this.itemCount,
    this.titleOverride,
    this.contentOverride,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    return AlertDialog(
      title: Text(titleOverride ?? loc.deleteItemsTitle),
      content: Text(
        contentOverride ?? loc.deleteItemsPrompt(itemCount),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: Text(loc.cancel),
        ),
        ElevatedButton(
          onPressed: () => Navigator.of(context).pop(true),
          child: Text(loc.delete),
        ),
      ],
    );
  }
}


