import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

import '../../core/constants/pos_permissions.dart';
import '../../core/utils/pin_hash.dart';
import '../../providers/pin_session_provider.dart';

/// Assign a delivery driver by verifying **that driver's** PIN.
///
/// - Unlocked staff with [role] `driver` → self-assign only (own PIN).
/// - Manager / take_order → pick any active driver, confirm with **driver** PIN.
class DriverAssignSheet extends StatefulWidget {
  final String franchiseId;
  final String orderId;

  const DriverAssignSheet({
    super.key,
    required this.franchiseId,
    required this.orderId,
  });

  static Future<bool> show(
    BuildContext context, {
    required String franchiseId,
    required String orderId,
  }) async {
    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          DriverAssignSheet(franchiseId: franchiseId, orderId: orderId),
    );
    return result == true;
  }

  @override
  State<DriverAssignSheet> createState() => _DriverAssignSheetState();
}

class _DriverAssignSheetState extends State<DriverAssignSheet> {
  final _posFs = PosFirestoreService();
  final _pinController = TextEditingController();

  Staff? _selected;
  bool _busy = false;
  String? _error;
  List<Staff> _drivers = const [];
  bool _loading = true;

  bool _isDriverRole(Staff? s) {
    if (s == null) return false;
    return s.role.trim().toLowerCase() == 'driver';
  }

  bool _canPickAnyDriver(PinSessionProvider session) {
    return session.hasPermission(PosPermissions.takeOrder) ||
        session.hasPermission(PosPermissions.managerOverride);
  }

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  Future<void> _bootstrap() async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final self = session.staff;

    try {
      final all = await _posFs.streamStaff(widget.franchiseId).first;
      final drivers = all
          .where(
            (s) =>
                s.status == 'active' && s.role.trim().toLowerCase() == 'driver',
          )
          .toList();

      if (!mounted) return;

      // Driver session → only self, pre-selected.
      if (_isDriverRole(self)) {
        final me = drivers.where((d) => d.id == self!.id).toList();
        setState(() {
          _drivers = me.isNotEmpty ? me : (self != null ? [self] : const []);
          _selected = _drivers.isNotEmpty ? _drivers.first : null;
          _loading = false;
        });
        return;
      }

      setState(() {
        _drivers = drivers;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load drivers';
      });
    }
  }

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _confirm() async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final self = session.staff;
    if (self == null) {
      setState(() => _error = 'Session locked — unlock again');
      return;
    }

    final driver = _selected;
    if (driver == null) {
      setState(() => _error = 'Select a driver');
      return;
    }

    // Drivers may only assign themselves.
    if (_isDriverRole(self) && driver.id != self.id) {
      setState(() => _error = 'Drivers can only assign themselves');
      return;
    }

    // Non-drivers need take_order / manager_override to assign others.
    if (!_isDriverRole(self) && !_canPickAnyDriver(session)) {
      setState(() => _error = 'No permission to assign driver');
      return;
    }

    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Enter driver PIN');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      // Always verify the **selected driver's** pinHash (not manager session).
      final fresh =
          await _posFs.getStaff(widget.franchiseId, driver.id) ?? driver;
      if (fresh.pinHash == null || fresh.pinHash!.isEmpty) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'Driver has no PIN set';
        });
        return;
      }

      final ok = PinHash.verify(pin, fresh.pinHash);
      if (!ok) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'Invalid driver PIN';
          _pinController.clear();
        });
        return;
      }

      final now = DateTime.now();
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(widget.franchiseId)
          .collection('orders')
          .doc(widget.orderId)
          .set({
            'status': OrderStatus.outForDelivery,
            'driverId': fresh.id,
            'driverName': fresh.name,
            if (fresh.phoneNumber != null) 'driverPhone': fresh.phoneNumber,
            'assignedAt': now.toIso8601String(),
            'timestamps.driver_assigned': now.toIso8601String(),
            'timestamps.out_for_delivery': now.toIso8601String(),
          }, SetOptions(merge: true));

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Assign failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<PinSessionProvider>();
    final selfIsDriver = _isDriverRole(session.staff);
    final canPick = !selfIsDriver && _canPickAnyDriver(session);

    return AlertDialog(
      title: Text(selfIsDriver ? 'Take this delivery' : 'Assign driver'),
      content: SizedBox(
        width: 400,
        child: _loading
            ? const SizedBox(
                height: 120,
                child: Center(child: CircularProgressIndicator()),
              )
            : SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Text(
                      selfIsDriver
                          ? 'Confirm with your driver PIN to assign yourself.'
                          : 'Select a driver, then enter **that driver’s** PIN.',
                      style: TextStyle(
                        color: scheme.onSurfaceVariant,
                        fontSize: 13,
                      ),
                    ),
                    const SizedBox(height: 12),
                    if (_drivers.isEmpty)
                      Text(
                        'No active drivers found',
                        style: TextStyle(color: scheme.error),
                      )
                    else if (selfIsDriver)
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: Icon(Icons.person, color: scheme.primary),
                        title: Text(_selected?.name ?? session.staff!.name),
                        subtitle: const Text('You'),
                      )
                    else
                      ..._drivers.map((d) {
                        final selected = _selected?.id == d.id;
                        return ListTile(
                          contentPadding: EdgeInsets.zero,
                          selected: selected,
                          title: Text(d.name),
                          subtitle: Text(
                            [
                              if (d.phoneNumber != null &&
                                  d.phoneNumber!.isNotEmpty)
                                d.phoneNumber!,
                              d.email,
                            ].where((e) => e.isNotEmpty).join(' · '),
                          ),
                          trailing: selected
                              ? Icon(Icons.check_circle, color: scheme.primary)
                              : null,
                          onTap: (_busy || !canPick)
                              ? null
                              : () => setState(() {
                                  _selected = d;
                                  _error = null;
                                  _pinController.clear();
                                }),
                        );
                      }),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _pinController,
                      autofocus: true,
                      obscureText: true,
                      enabled: !_busy && _selected != null,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(8),
                      ],
                      decoration: InputDecoration(
                        labelText: selfIsDriver
                            ? 'Your PIN'
                            : 'Driver PIN'
                                  '${_selected != null ? ' (${_selected!.name})' : ''}',
                        border: const OutlineInputBorder(),
                      ),
                      onSubmitted: (_) => _confirm(),
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        _error!,
                        style: TextStyle(color: scheme.error, fontSize: 13),
                      ),
                    ],
                  ],
                ),
              ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy || _selected == null ? null : _confirm,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : Text(selfIsDriver ? 'Assign me' : 'Assign driver'),
        ),
      ],
    );
  }
}
