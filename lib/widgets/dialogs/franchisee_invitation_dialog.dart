import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/financials/franchisee_invitation_service.dart';
import 'package:franchise_admin_portal/core/providers/franchisee_invitation_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';

class FranchiseeInvitationDialog extends StatefulWidget {
  const FranchiseeInvitationDialog({super.key});

  @override
  State<FranchiseeInvitationDialog> createState() =>
      _FranchiseeInvitationDialogState();
}

class _FranchiseeInvitationDialogState
    extends State<FranchiseeInvitationDialog> {
  final _formKey = GlobalKey<FormState>();
  String? _email;
  String? _franchiseName;
  String? _role;
  String? _notes;
  bool _isLoading = false;
  String? _error;
  String? _success;

  // Adjust these roles as appropriate
  static const _roleOptions = [
    'hq_owner',
    'owner',
    'admin',
    'manager',
    'staff',
  ];

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[${runtimeType}] loc is null! Localization not available for this context.');
      // Fallback UI for missing localization:
      return Scaffold(
        body: Center(child: Text('Localization missing! [debug]')),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;

    return AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.dialogBorderRadius),
      ),
      title: Text(loc.inviteFranchisee),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _error!,
                    style: TextStyle(
                        color: colorScheme.error, fontWeight: FontWeight.w600),
                  ),
                ),
              if (_success != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Text(
                    _success!,
                    style: TextStyle(
                        color: colorScheme.primary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
              TextFormField(
                decoration: InputDecoration(
                  labelText: loc.email,
                  hintText: 'franchisee@email.com',
                ),
                keyboardType: TextInputType.emailAddress,
                validator: (val) {
                  if (val == null || val.isEmpty) {
                    return loc.requiredField;
                  }
                  final emailReg = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
                  if (!emailReg.hasMatch(val)) {
                    return loc.invalidEmail;
                  }
                  return null;
                },
                onSaved: (val) => _email = val,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: loc.franchiseName,
                  hintText: loc.franchiseNameHint,
                ),
                onSaved: (val) => _franchiseName = val,
                enabled: !_isLoading,
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<String>(
                decoration: InputDecoration(
                  labelText: loc.role,
                ),
                value: _role,
                items: _roleOptions
                    .map((role) => DropdownMenuItem(
                          value: role,
                          child: Text(loc.roleLabel(role)),
                        ))
                    .toList(),
                onChanged:
                    _isLoading ? null : (val) => setState(() => _role = val),
                validator: (val) => val == null ? loc.requiredField : null,
              ),
              const SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(
                  labelText: loc.notes,
                ),
                onSaved: (val) => _notes = val,
                enabled: !_isLoading,
                maxLines: 2,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text(loc.cancel),
        ),
        ElevatedButton.icon(
          icon: _isLoading
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.send),
          onPressed: _isLoading ? null : _submit,
          label: Text(loc.invite),
          style: ElevatedButton.styleFrom(
            backgroundColor: colorScheme.primary,
            foregroundColor: colorScheme.onPrimary,
          ),
        ),
      ],
    );
  }

  Future<void> _submit() async {
    setState(() {
      _error = null;
      _success = null;
    });
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final invitationProvider =
          Provider.of<FranchiseeInvitationProvider>(context, listen: false);

      await invitationProvider.sendInvitation(
        email: _email!,
        franchiseName: _franchiseName ?? '',
        role: _role!,
        notes: _notes ?? '',
      );

      setState(() {
        _success = AppLocalizations.of(context)!.invitationSent;
        _isLoading = false;
      });

      // Optionally, close after a short delay
      Future.delayed(const Duration(milliseconds: 1200), () {
        if (mounted) Navigator.of(context).pop(true);
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to send franchisee invitation',
        stack: stack.toString(),
        severity: 'error',
        source: 'FranchiseeInvitationDialog',
        screen: 'PlatformOwnerDashboardScreen',
        contextData: {
          'exception': e.toString(),
        },
      );
      setState(() {
        _error = AppLocalizations.of(context)!.inviteErrorGeneric;
        _isLoading = false;
      });
    }
  }
}
