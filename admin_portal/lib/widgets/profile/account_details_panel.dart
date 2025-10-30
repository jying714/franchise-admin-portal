// File: lib/widgets/profile/account_details_panel.dart

import 'package:flutter/material.dart';
import 'package:admin_portal/core/models/user.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class AccountDetailsPanel extends StatefulWidget {
  final User user;
  final VoidCallback? onProfileUpdated;

  const AccountDetailsPanel({
    Key? key,
    required this.user,
    this.onProfileUpdated,
  }) : super(key: key);

  @override
  State<AccountDetailsPanel> createState() => _AccountDetailsPanelState();
}

class _AccountDetailsPanelState extends State<AccountDetailsPanel> {
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late String _language;
  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user.name);
    _phoneController =
        TextEditingController(text: widget.user.phoneNumber ?? '');
    _language = widget.user.language;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _saveChanges() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await FirestoreService().updateUserProfile(widget.user.id, {
        'name': _nameController.text.trim(),
        'phoneNumber': _phoneController.text.trim(),
        'language': _language,
      });
      setState(() => _editing = false);
      widget.onProfileUpdated?.call();
    } catch (e, st) {
      setState(() => _error = e.toString());
      await ErrorLogger.log(
        message: 'Failed to update profile: $e',
        stack: st.toString(),
        source: 'AccountDetailsPanel',
        screen: 'account_details_panel',
        severity: 'error',
      );
    } finally {
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[AccountDetailsPanel] loc is null! Localization not available for this context.');
      // Return a minimal error card or placeholder (never Scaffold from a widget)
      return Card(
        color: Colors.red.shade100,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Localization missing! [debug]',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ),
      );
    }
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      margin: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.13),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.person_outline, color: colorScheme.primary),
                const SizedBox(width: 8),
                Text(loc.accountDetails,
                    style: Theme.of(context).textTheme.titleMedium),
                const Spacer(),
                if (!_editing)
                  IconButton(
                    icon: Icon(Icons.edit),
                    tooltip: loc.edit,
                    onPressed: () => setState(() => _editing = true),
                  ),
              ],
            ),
            const SizedBox(height: 18),
            if (_error != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child:
                    Text(_error!, style: TextStyle(color: colorScheme.error)),
              ),
            _editing
                ? _buildEditFields(context, loc)
                : _buildViewFields(context, loc),
            if (_editing)
              Row(
                children: [
                  ElevatedButton(
                    onPressed: _saving ? null : _saveChanges,
                    child:
                        _saving ? CircularProgressIndicator() : Text(loc.save),
                  ),
                  const SizedBox(width: 12),
                  OutlinedButton(
                    onPressed:
                        _saving ? null : () => setState(() => _editing = false),
                    child: Text(loc.cancel),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildViewFields(BuildContext context, AppLocalizations loc) {
    final user = widget.user;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('${loc.name}: ${user.name}',
            style: Theme.of(context).textTheme.bodyMedium),
        const SizedBox(height: 4),
        Text('${loc.email}: ${user.email}',
            style: Theme.of(context).textTheme.bodyMedium),
        if (user.phoneNumber != null && user.phoneNumber!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text('${loc.phone}: ${user.phoneNumber}',
                style: Theme.of(context).textTheme.bodyMedium),
          ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${loc.language}: ${user.language}',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${loc.roles}: ${user.roles.join(", ")}',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
        Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text('${loc.status}: ${user.status}',
              style: Theme.of(context).textTheme.bodyMedium),
        ),
      ],
    );
  }

  Widget _buildEditFields(BuildContext context, AppLocalizations loc) {
    final languageOptions = [
      DropdownMenuItem(value: 'en', child: Text('English')),
      // Add other supported languages here.
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        TextFormField(
          controller: _nameController,
          decoration: InputDecoration(labelText: loc.name),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: _phoneController,
          decoration: InputDecoration(labelText: loc.phone),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _language,
          decoration: InputDecoration(labelText: loc.language),
          items: languageOptions,
          onChanged: (val) => setState(() => _language = val ?? 'en'),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
