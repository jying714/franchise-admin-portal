import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/services.dart';
import 'package:cloud_functions/cloud_functions.dart';

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
  String _role = 'manager';

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      shared.ErrorLogger.log(
        message:
            'AppLocalizations.of(context) returned null in AddStaffDialog.',
        source: 'show_add_staff_dialog.dart',
        severity: 'error',
        contextData: {
          'widget': 'AddStaffDialog',
          'location': 'build()',
        },
      );
      return const AlertDialog(
        content: Text('Localization missing â€“ AddStaffDialog'),
      );
    }

    final service =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;
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
            if (!_formKey.currentState!.validate()) return;
            _formKey.currentState!.save();

            final fid = (franchiseId ?? '').trim();
            if (fid.isEmpty || fid == 'unknown') {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Select a franchise first')),
              );
              return;
            }

            final inviterId =
                Provider.of<shared.AdminUserProvider>(context, listen: false)
                        .user
                        ?.id ??
                    '';

            try {
              final token = FirebaseFirestore.instance
                  .collection('franchisee_invitations')
                  .doc()
                  .id;

              // Production URL for email; local origin for HQ copy-paste testing.
              final productionAcceptUrl =
                  'https://franchisehq.io/#/invite-accept?token=$token';
              final localAcceptUrl =
                  '${Uri.base.origin}/#/invite-accept?token=$token';

              await FirebaseFirestore.instance
                  .collection('franchisee_invitations')
                  .doc(token)
                  .set({
                'email': _email.trim().toLowerCase(),
                'name': _name.trim(),
                'role': _role,
                'roles': [_role],
                'franchiseId': fid,
                'franchiseIds': [fid],
                'inviterUserId': inviterId,
                'status': 'pending',
                'token': token,
                'inviteType': 'portal_staff',
                'inviteUrl': productionAcceptUrl,
                'createdAt': FieldValue.serverTimestamp(),
                'lastSentAt': FieldValue.serverTimestamp(),
              });

              String emailStatus = 'Email sent.';
              try {
                await FirebaseFunctions.instance
                    .httpsCallable('sendPortalStaffInviteEmail')
                    .call(<String, dynamic>{'token': token});
              } catch (mailErr, mailStack) {
                emailStatus = 'Email failed (link still works).';
                shared.ErrorLogger.log(
                  message: mailErr.toString(),
                  stack: mailStack.toString(),
                  source: 'show_add_staff_dialog',
                  severity: 'warning',
                  contextData: {
                    'franchiseId': fid,
                    'email': _email,
                    'token': token,
                    'operation': 'send_portal_invite_email',
                  },
                );
              }

              if (!mounted) return;
              Navigator.of(context).pop();

              await Clipboard.setData(ClipboardData(text: localAcceptUrl));
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Invite created for $_email. Accept link copied. $emailStatus',
                  ),
                  action: SnackBarAction(
                    label: 'Copy again',
                    onPressed: () {
                      Clipboard.setData(ClipboardData(text: localAcceptUrl));
                    },
                  ),
                  duration: const Duration(seconds: 8),
                ),
              );
            } catch (e, stack) {
              shared.ErrorLogger.log(
                message: e.toString(),
                stack: stack.toString(),
                source: 'show_add_staff_dialog',
                severity: 'error',
                contextData: {
                  'franchiseId': fid,
                  'name': _name,
                  'email': _email,
                  'role': _role,
                  'operation': 'create_portal_invite',
                },
              );
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Invite failed: $e')),
              );
            }
          },
          child: Text(loc.staffAddButton),
        ),
      ],
    );
  }
}
