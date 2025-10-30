import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/utils/error_logger.dart';

class AddStaffDialog extends StatefulWidget {
  final AppLocalizations loc;
  const AddStaffDialog({super.key, required this.loc});

  @override
  State<AddStaffDialog> createState() => _AddStaffDialogState();
}

class _AddStaffDialogState extends State<AddStaffDialog> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _role = 'staff';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      ErrorLogger.log(
        message:
            'AppLocalizations.of(context) returned null in AddStaffDialog.',
        source: 'show_add_staff_dialog.dart',
        screen: 'AddStaffDialog',
        severity: 'error',
        contextData: {
          'widget': 'AddStaffDialog',
          'location': 'build()',
        },
      );
      return const AlertDialog(
        content: Text('Localization missing – AddStaffDialog'),
      );
    }

    final service = Provider.of<FirestoreService>(context, listen: false);
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      backgroundColor: colorScheme.background,
      surfaceTintColor: Colors.transparent,
      title: Text(
        loc.staffAddStaffDialogTitle,
        style: TextStyle(
          color: colorScheme.onBackground,
          fontWeight: FontWeight.bold,
          fontSize: 20,
        ),
      ),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                decoration: InputDecoration(
                  labelText: loc.staffNameLabel,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.staffNameRequired
                    : null,
                onSaved: (v) => _name = v!.trim(),
              ),
              const SizedBox(height: 8),
              TextFormField(
                decoration: InputDecoration(
                  labelText: loc.staffEmailLabel,
                ),
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? loc.staffEmailRequired
                    : null,
                onSaved: (v) => _email = v!.trim(),
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 8),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: InputDecoration(
                  labelText: loc.staffRoleLabel,
                ),
                items: [
                  DropdownMenuItem(
                      value: 'owner', child: Text(loc.staffRoleOwner)),
                  DropdownMenuItem(
                      value: 'manager', child: Text(loc.staffRoleManager)),
                  DropdownMenuItem(
                      value: 'staff', child: Text(loc.staffRoleStaff)),
                ],
                onChanged: (v) => setState(() => _role = v!),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: Text(
            loc.cancelButton,
            style: TextStyle(color: colorScheme.secondary),
          ),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
          onPressed: () async {
            if (_formKey.currentState!.validate()) {
              _formKey.currentState!.save();
              try {
                await service.addStaffUser(
                  name: _name,
                  email: _email,
                  roles: [_role],
                  franchiseIds: [franchiseId],
                );
                if (!mounted) return;
                Navigator.of(context).pop();
              } catch (e, stack) {
                await ErrorLogger.log(
                  message: e.toString(),
                  stack: stack.toString(),
                  source: 'staff_access_screen',
                  screen: 'AddStaffDialog',
                  severity: 'error',
                  contextData: {
                    'franchiseId': franchiseId,
                    'name': _name,
                    'email': _email,
                    'role': _role,
                    'operation': 'add_staff',
                  },
                );
              }
            }
          },
          child: Text(loc.staffAddButton),
        ),
      ],
    );
  }
}
