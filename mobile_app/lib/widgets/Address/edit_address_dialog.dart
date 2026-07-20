import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/Address/address_form.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

// P1 Batch 2: Duplicated widgets cleanup (Address/ + categories/ + header/)

class EditAddressDialog extends StatefulWidget {
  final shared.Address initialValue;
  final Future<void> Function(shared.Address updatedAddress) onSave;

  const EditAddressDialog({
    super.key,
    required this.initialValue,
    required this.onSave,
  });

  static Future<void> show(
    BuildContext context, {
    required shared.Address initialValue,
    required Future<void> Function(shared.Address updatedAddress) onSave,
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
  late shared.Address _editedAddress;

  @override
  void initState() {
    super.initState();
    _editedAddress = widget.initialValue;
  }

  @override
  Widget build(BuildContext context) {
    // FranchiseProvider injected for franchise/{franchiseId}/ scoping (Batch 2)
    Provider.of<shared.FranchiseProvider>(context, listen: false);

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
                    color: shared.UiConfig.primaryColor,
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
