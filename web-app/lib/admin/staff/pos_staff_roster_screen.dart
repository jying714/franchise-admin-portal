import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/design_tokens.dart';

/// Day-2 ops roster for station staff (PIN / schedule / clock).
/// Path: franchises/{franchiseId}/staff/{id}
class PosStaffRosterScreen extends StatefulWidget {
  const PosStaffRosterScreen({super.key});

  @override
  State<PosStaffRosterScreen> createState() => _PosStaffRosterScreenState();
}

class _PosStaffRosterScreenState extends State<PosStaffRosterScreen> {
  final _posFs = shared.PosFirestoreService();

  String get _franchiseId {
    return Provider.of<shared.FranchiseProvider>(context, listen: false)
        .franchiseId;
  }

  Future<void> _openEditor({shared.Staff? existing}) async {
    final fid = _franchiseId;
    if (fid.isEmpty || fid == 'unknown') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Select a franchise first')),
      );
      return;
    }

    final result = await showDialog<_StaffDraft>(
      context: context,
      builder: (ctx) => _StaffEditorDialog(existing: existing),
    );
    if (result == null || !mounted) return;

    final id = existing?.id.isNotEmpty == true
        ? existing!.id
        : DateTime.now().millisecondsSinceEpoch.toString();

    final String? pinHash = result.newPin != null && result.newPin!.isNotEmpty
        ? shared.PinHash.hashPin(result.newPin!)
        : existing?.pinHash;

    final staff = shared.Staff(
      id: id,
      name: result.name,
      email: result.email,
      phoneNumber: result.phone.isEmpty ? null : result.phone,
      role: result.role,
      status: result.active ? 'active' : 'inactive',
      permissions: result.permissions,
      franchiseId: fid,
      hourlyPay: result.hourlyPay,
      pinHash: pinHash,
      posEnabled: result.posEnabled,
    );

    try {
      await _posFs.saveStaff(fid, staff);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text(existing == null ? 'Staff added' : 'Staff updated')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Save failed: $e')),
      );
    }
  }

  Future<void> _setActive(shared.Staff staff, bool active) async {
    final fid = _franchiseId;
    try {
      await _posFs.saveStaff(
        fid,
        staff.copyWith(status: active ? 'active' : 'inactive'),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Update failed: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fid = context.watch<shared.FranchiseProvider>().franchiseId;
    final hasFranchise = fid.isNotEmpty && fid != 'unknown';

    return Scaffold(
      backgroundColor: theme.colorScheme.surface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Station staff',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const Spacer(),
                FilledButton.icon(
                  onPressed: hasFranchise ? () => _openEditor() : null,
                  icon: const Icon(Icons.person_add_outlined, size: 18),
                  label: const Text('Add staff'),
                  style: FilledButton.styleFrom(
                    backgroundColor: DesignTokens.primaryColor,
                    foregroundColor: DesignTokens.foregroundColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              'Used for schedule assignment and POS PIN clock-in.',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: !hasFranchise
                  ? const Center(child: Text('Select a franchise first'))
                  : StreamBuilder<List<shared.Staff>>(
                      stream: _posFs.streamStaff(fid),
                      builder: (context, snap) {
                        if (snap.hasError) {
                          return Center(child: Text('Error: ${snap.error}'));
                        }
                        if (!snap.hasData) {
                          return const Center(
                            child: CircularProgressIndicator(),
                          );
                        }
                        final list = List<shared.Staff>.from(snap.data!)
                          ..sort((a, b) => a.name.compareTo(b.name));
                        if (list.isEmpty) {
                          return const Center(
                            child: Text(
                                'No station staff yet. Add your first employee.'),
                          );
                        }
                        return ListView.separated(
                          itemCount: list.length,
                          separatorBuilder: (_, __) => const Divider(height: 1),
                          itemBuilder: (context, i) {
                            final s = list[i];
                            final active = s.status.toLowerCase() == 'active';
                            return ListTile(
                              leading: CircleAvatar(
                                backgroundColor: DesignTokens.primaryColor
                                    .withValues(alpha: 0.15),
                                child: Text(
                                  s.name.isNotEmpty
                                      ? s.name[0].toUpperCase()
                                      : '?',
                                  style: TextStyle(
                                    color: DesignTokens.primaryColor,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                              title: Text(s.name),
                              subtitle: Text(
                                [
                                  s.role,
                                  if (s.hourlyPay != null)
                                    '\$${s.hourlyPay!.toStringAsFixed(2)}/hr',
                                  if (s.posEnabled) 'POS',
                                  active ? 'Active' : 'Inactive',
                                  if (s.permissions.isEmpty)
                                    'No permissions'
                                  else if (s.permissions.length <= 4)
                                    s.permissions.join(' · ')
                                  else
                                    '${s.permissions.take(3).join(' · ')} +${s.permissions.length - 3}',
                                ].join(' · '),
                              ),
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Switch(
                                    value: active,
                                    onChanged: (v) => _setActive(s, v),
                                  ),
                                  IconButton(
                                    tooltip: 'Edit',
                                    icon: const Icon(Icons.edit_outlined),
                                    onPressed: () => _openEditor(existing: s),
                                  ),
                                ],
                              ),
                              onTap: () => _openEditor(existing: s),
                            );
                          },
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StaffDraft {
  final String name;
  final String email;
  final String phone;
  final String role;
  final double? hourlyPay;
  final bool active;
  final bool posEnabled;
  final List<String> permissions;

  /// Null = leave existing pinHash unchanged; non-null = replace.
  final String? newPin;

  _StaffDraft({
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.hourlyPay,
    required this.active,
    required this.posEnabled,
    required this.permissions,
    this.newPin,
  });
}

class _StaffEditorDialog extends StatefulWidget {
  final shared.Staff? existing;

  const _StaffEditorDialog({this.existing});

  @override
  State<_StaffEditorDialog> createState() => _StaffEditorDialogState();
}

class _StaffEditorDialogState extends State<_StaffEditorDialog> {
  static const _roles = ['owner', 'manager', 'cashier', 'cook', 'driver'];

  /// Must match POS PosPermissions string values.
  static const _allPermissions = <String>[
    'view_orders',
    'take_order',
    'take_payment',
    'open_drawer',
    'void_item',
    'void_order',
    'refund',
    'discount',
    '86_item',
    'manage_tables',
    'change_settings',
    'approve_large_order',
    'manager_override',
  ];

  static const _permissionLabels = <String, String>{
    'view_orders': 'View orders',
    'take_order': 'Take / send orders',
    'take_payment': 'Take payment',
    'open_drawer': 'Open cash drawer',
    'void_item': 'Void item',
    'void_order': 'Void order',
    'refund': 'Refund',
    'discount': 'Discount',
    '86_item': '86 item',
    'manage_tables': 'Manage tables',
    'change_settings': 'Change settings',
    'approve_large_order': 'Approve large order',
    'manager_override': 'Manager override',
  };

  /// Baseline by role; manager can add extras per person below.
  static List<String> _defaultsForRole(String role) {
    switch (role.trim().toLowerCase()) {
      case 'owner':
      case 'manager':
        return List<String>.from(_allPermissions);
      case 'cashier':
        return const [
          'view_orders',
          'take_order',
          'take_payment',
          'open_drawer',
          'discount',
          'manage_tables',
        ];
      case 'cook':
        return const [
          'view_orders',
          'take_order',
          '86_item',
        ];
      case 'driver':
        return const [
          'view_orders',
          'take_payment',
          'open_drawer',
        ];
      default:
        return const ['view_orders'];
    }
  }

  late final TextEditingController _name;
  late final TextEditingController _email;
  late final TextEditingController _phone;
  late final TextEditingController _pay;
  late final TextEditingController _pin;
  late final TextEditingController _pinConfirm;
  late String _role;
  late bool _active;
  late bool _posEnabled;
  late Set<String> _permissions;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _email = TextEditingController(text: e?.email ?? '');
    _phone = TextEditingController(text: e?.phoneNumber ?? '');
    _pay = TextEditingController(
      text: e?.hourlyPay != null ? e!.hourlyPay!.toStringAsFixed(2) : '',
    );
    _pin = TextEditingController();
    _pinConfirm = TextEditingController();
    _role = e?.role ?? 'cashier';
    if (!_roles.contains(_role)) {
      _role = 'cashier';
    }
    _active = (e?.status ?? 'active').toLowerCase() == 'active';
    _posEnabled = e?.posEnabled ?? true;
    if (e != null && e.permissions.isNotEmpty) {
      _permissions = Set<String>.from(e.permissions);
    } else {
      _permissions = Set<String>.from(_defaultsForRole(_role));
    }
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _pay.dispose();
    _pin.dispose();
    _pinConfirm.dispose();
    super.dispose();
  }

  void _onRoleChanged(String role) {
    setState(() {
      _role = role;
      // New staff: always reset to role defaults.
      // Edit: offer defaults for the new role (manager can still tick extras).
      _permissions = Set<String>.from(_defaultsForRole(role));
    });
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.existing != null;
    final theme = Theme.of(context);
    return AlertDialog(
      title: Text(isEdit ? 'Edit staff' : 'Add staff'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _name,
                textCapitalization: TextCapitalization.words,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'Email (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _phone,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Phone (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                items: _roles
                    .map(
                      (r) => DropdownMenuItem(value: r, child: Text(r)),
                    )
                    .toList(),
                onChanged: (v) {
                  if (v != null) _onRoleChanged(v);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pay,
                keyboardType: const TextInputType.numberWithOptions(
                  decimal: true,
                ),
                decoration: const InputDecoration(
                  labelText: 'Hourly pay (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Active'),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('POS enabled'),
                subtitle: const Text('May unlock station / clock with PIN'),
                value: _posEnabled,
                onChanged: (v) => setState(() => _posEnabled = v),
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'Permissions',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                'Role sets a baseline. Tick extra grants for this person.',
                style: theme.textTheme.bodySmall,
              ),
              const SizedBox(height: 4),
              ..._allPermissions.map((perm) {
                final selected = _permissions.contains(perm);
                return CheckboxListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  controlAffinity: ListTileControlAffinity.leading,
                  title: Text(_permissionLabels[perm] ?? perm),
                  value: selected,
                  onChanged: (v) {
                    setState(() {
                      if (v == true) {
                        _permissions.add(perm);
                      } else {
                        _permissions.remove(perm);
                      }
                    });
                  },
                );
              }),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  isEdit &&
                          widget.existing?.pinHash != null &&
                          widget.existing!.pinHash!.isNotEmpty
                      ? 'Leave PIN blank to keep current PIN'
                      : 'PIN (optional)',
                  style: theme.textTheme.bodySmall,
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _pin,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(
                  labelText: 'PIN (optional)',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pinConfirm,
                obscureText: true,
                keyboardType: TextInputType.number,
                inputFormatters: [
                  FilteringTextInputFormatter.digitsOnly,
                  LengthLimitingTextInputFormatter(8),
                ],
                decoration: const InputDecoration(
                  labelText: 'Confirm PIN',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            final name = _name.text.trim();
            if (name.isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Name is required')),
              );
              return;
            }
            final payRaw = _pay.text.trim();
            final pay = payRaw.isEmpty ? null : double.tryParse(payRaw);
            if (payRaw.isNotEmpty && pay == null) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Invalid hourly pay')),
              );
              return;
            }
            final pin = _pin.text.trim();
            final pinConfirm = _pinConfirm.text.trim();
            if (pin.isNotEmpty || pinConfirm.isNotEmpty) {
              if (pin.length < 4) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN must be at least 4 digits'),
                  ),
                );
                return;
              }
              if (pin != pinConfirm) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('PIN confirmation does not match'),
                  ),
                );
                return;
              }
            }

            final ordered =
                _allPermissions.where((p) => _permissions.contains(p)).toList();

            Navigator.pop(
              context,
              _StaffDraft(
                name: name,
                email: _email.text.trim(),
                phone: _phone.text.trim(),
                role: _role,
                hourlyPay: pay,
                active: _active,
                posEnabled: _posEnabled,
                permissions: ordered,
                newPin: pin.isEmpty ? null : pin,
              ),
            );
          },
          child: Text(isEdit ? 'Save' : 'Add'),
        ),
      ],
    );
  }
}
