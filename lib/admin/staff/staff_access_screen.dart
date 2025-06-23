import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/user.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StaffAccessScreen extends StatefulWidget {
  const StaffAccessScreen({super.key});

  @override
  State<StaffAccessScreen> createState() => _StaffAccessScreenState();
}

class _StaffAccessScreenState extends State<StaffAccessScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _email = '';
  String _role = 'staff'; // default

  bool _canEditStaff(BuildContext context) {
    final user = Provider.of<User?>(context, listen: false);
    return user != null && (user.role == 'owner' || user.role == 'manager');
  }

  @override
  Widget build(BuildContext context) {
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context)!;
    final canEdit = _canEditStaff(context);

    // Security: Only owners/managers can access. Others see branded error.
    if (!canEdit) {
      return Scaffold(
        appBar: AppBar(
          title: Text(loc.staffAccessTitle),
          backgroundColor: BrandingConfig.brandRed,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(32.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.lock_outline, size: 64, color: Colors.red.shade300),
                const SizedBox(height: 16),
                Text(
                  loc.unauthorizedAdminMessage,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                      fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: () => Navigator.of(context)
                      .pushNamedAndRemoveUntil('/', (_) => false),
                  icon: const Icon(Icons.home),
                  label: Text(loc.returnToHomeButton),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: BrandingConfig.brandRed,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(loc.staffAccessTitle),
        backgroundColor: BrandingConfig.brandRed,
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.primaryColor,
        tooltip: loc.staffAddStaffTooltip,
        child: const Icon(Icons.person_add),
        onPressed: () => _showAddStaffDialog(context, firestoreService, loc),
      ),
      body: StreamBuilder<List<User>>(
        stream: firestoreService.getStaffUsers(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerWidget();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return EmptyStateWidget(
              title: loc.staffNoStaffTitle,
              message: loc.staffNoStaffMessage,
              imageAsset: BrandingConfig.adminEmptyStateImage,
              isAdmin: true,
            );
          }
          final staff = snapshot.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: staff.length,
            separatorBuilder: (_, __) => const Divider(),
            itemBuilder: (context, i) {
              final user = staff[i];
              return ListTile(
                leading: CircleAvatar(
                  backgroundColor: DesignTokens.secondaryColor,
                  child: Text(
                    user.name.isNotEmpty ? user.name[0] : '?',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(user.name,
                    style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text('${user.email} • ${user.role}'),
                trailing: IconButton(
                  icon: const Icon(Icons.delete, color: Colors.red),
                  tooltip: loc.staffRemoveTooltip,
                  onPressed: () =>
                      _confirmRemoveStaff(context, firestoreService, user, loc),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showAddStaffDialog(
      BuildContext context, FirestoreService service, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(loc.staffAddStaffDialogTitle),
          content: Form(
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
                      value: 'owner',
                      child: Text(loc.staffRoleOwner),
                    ),
                    DropdownMenuItem(
                      value: 'manager',
                      child: Text(loc.staffRoleManager),
                    ),
                    DropdownMenuItem(
                      value: 'staff',
                      child: Text(loc.staffRoleStaff),
                    ),
                  ],
                  onChanged: (v) {
                    setState(() {
                      _role = v!;
                    });
                  },
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(loc.cancelButton)),
            ElevatedButton(
              onPressed: () async {
                if (_formKey.currentState!.validate()) {
                  _formKey.currentState!.save();
                  await service.addStaffUser(
                    name: _name,
                    email: _email,
                    role: _role,
                  );
                  Navigator.of(context).pop();
                }
              },
              child: Text(loc.staffAddButton),
            ),
          ],
        );
      },
    );
  }

  void _confirmRemoveStaff(BuildContext context, FirestoreService service,
      User user, AppLocalizations loc) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(loc.staffRemoveDialogTitle),
        content:
            Text('${loc.staffRemoveDialogBody}\n${user.name} (${user.email})'),
        actions: [
          TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(loc.cancelButton)),
          ElevatedButton(
            onPressed: () async {
              await service.removeStaffUser(user.id);
              Navigator.of(context).pop();
            },
            child: Text(loc.staffRemoveButton),
          ),
        ],
      ),
    );
  }
}
