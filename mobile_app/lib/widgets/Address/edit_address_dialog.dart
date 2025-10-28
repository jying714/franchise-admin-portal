import 'package:flutter/material.dart';
import 'package:doughboys_pizzeria_final/config/design_tokens.dart';
import 'package:doughboys_pizzeria_final/core/models/address.dart';
import 'package:doughboys_pizzeria_final/widgets/Address/address_form.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class EditAddressDialog extends StatefulWidget {
  final Address initialValue;
  final Future<void> Function(Address updatedAddress) onSave;

  const EditAddressDialog({
    super.key,
    required this.initialValue,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required Address initialValue,
    required Future<void> Function(Address updatedAddress) onSave,
  }) {
    return showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: EditAddressDialog(
          initialValue: initialValue,
          onSave: onSave,
        ),
      ),
    );
  }

  @override
  State<EditAddressDialog> createState() => _EditAddressDialogState();
}

class _EditAddressDialogState extends State<EditAddressDialog> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late Address _editedAddress;

  @override
  void initState() {
    super.initState();
    _editedAddress = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              loc.editAddress,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: DesignTokens.primaryColor,
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 20),
            AddressForm(
              formKey: _formKey,
              initialValue: _editedAddress,
              submitLabel: loc.save,
              onSubmit: (updated) async {
                Navigator.of(context).pop(); // Close dialog
                await widget.onSave(updated);
              },
            ),
          ],
        ),
      ),
    );
  }
}
