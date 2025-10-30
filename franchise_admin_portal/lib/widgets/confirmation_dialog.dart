import 'package:flutter/material.dart';

class ConfirmationDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final String cancelLabel;
  final VoidCallback onConfirm;
  final VoidCallback? onCancel;
  final IconData? icon;
  final Color? confirmColor;
  final Color? cancelColor;
  final bool showCancel;

  const ConfirmationDialog({
    Key? key,
    required this.title,
    required this.message,
    required this.onConfirm,
    this.confirmLabel = 'Confirm',
    this.cancelLabel = 'Cancel',
    this.onCancel,
    this.icon,
    this.confirmColor,
    this.cancelColor,
    this.showCancel = true,
  }) : super(key: key);

  static Future<bool?> show(
    BuildContext context, {
    required String title,
    required String message,
    required VoidCallback onConfirm,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    VoidCallback? onCancel,
    IconData? icon,
    Color? confirmColor,
    Color? cancelColor,
    bool showCancel = true,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (_) => ConfirmationDialog(
        title: title,
        message: message,
        onConfirm: onConfirm,
        confirmLabel: confirmLabel,
        cancelLabel: cancelLabel,
        onCancel: onCancel,
        icon: icon,
        confirmColor: confirmColor,
        cancelColor: cancelColor,
        showCancel: showCancel,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8.0),
              child: Icon(icon,
                  color: confirmColor ?? Theme.of(context).primaryColor),
            ),
          Expanded(child: Text(title)),
        ],
      ),
      content: Text(message),
      actions: [
        if (showCancel)
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              if (onCancel != null) onCancel!();
            },
            style: TextButton.styleFrom(
              foregroundColor:
                  cancelColor ?? Theme.of(context).colorScheme.secondary,
            ),
            child: Text(cancelLabel),
          ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(true);
            onConfirm();
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: confirmColor ?? Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
          child: Text(confirmLabel),
        ),
      ],
    );
  }
}
