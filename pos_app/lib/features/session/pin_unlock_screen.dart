import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

import '../../providers/pin_session_provider.dart';

class PinUnlockScreen extends StatefulWidget {
  final String franchiseId;
  final VoidCallback? onUnlocked;

  const PinUnlockScreen({
    super.key,
    required this.franchiseId,
    this.onUnlocked,
  });

  @override
  State<PinUnlockScreen> createState() => _PinUnlockScreenState();
}

class _PinUnlockScreenState extends State<PinUnlockScreen> {
  final _pinController = TextEditingController();
  final _posFs = PosFirestoreService();
  final _labor = LaborFirestoreService();
  final _pinFocus = FocusNode();

  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _pinFocus.requestFocus();
    });
  }

  @override
  void dispose() {
    _pinController.dispose();
    _pinFocus.dispose();
    super.dispose();
  }

  Future<Staff> _matchStaffByPin(String pin) async {
    final staffList = await _posFs.getStaffList(
      widget.franchiseId,
      fromServer: true,
    );
    if (staffList.isEmpty) {
      throw StateError(
        'No staff loaded for ${widget.franchiseId} (rules / claims)',
      );
    }

    final checkedNames = <String>[];
    for (final staff in staffList) {
      if (staff.status.toLowerCase() != 'active') continue;
      if (!staff.posEnabled) continue;
      final hash = staff.pinHash?.trim();
      if (hash == null || hash.isEmpty) continue;
      checkedNames.add(staff.name);
      if (PinHash.verify(pin, hash)) {
        return staff;
      }
    }
    if (checkedNames.isEmpty) {
      throw StateError(
        'No active POS staff has a PIN set (${staffList.length} staff loaded)',
      );
    }
    throw StateError(
      'Invalid PIN (checked ${checkedNames.length}: ${checkedNames.join(", ")})',
    );
  }

  Future<void> _submit() async {
    final pin = _pinController.text.trim();

    if (pin.isEmpty) {
      setState(() => _error = 'Enter PIN');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final matched = await _matchStaffByPin(pin);

      if (!mounted) return;
      final session = Provider.of<PinSessionProvider>(context, listen: false);
      try {
        final settings = await _posFs.getPosSettings(widget.franchiseId);
        session.setTimeoutMinutes(settings.pinSessionTimeoutMinutes);
      } catch (_) {
        // Keep provider default (15)
      }
      session.unlock(matched);
      _pinController.clear();
      widget.onUnlocked?.call();
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() => _error = 'Unlock failed: $e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _clock({required bool clockIn}) async {
    final pin = _pinController.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Enter PIN');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final matched = await _matchStaffByPin(pin);

      if (clockIn) {
        final open = await _labor.getOpenEntryForStaff(
          widget.franchiseId,
          matched.id,
        );
        if (open != null) {
          setState(() => _error = 'Already clocked in');
          return;
        }
        await _labor.clockIn(
          franchiseId: widget.franchiseId,
          staffId: matched.id,
          staffName: matched.name,
          source: 'pos',
          actedByStaffId: matched.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${matched.name} clocked in')));
      } else {
        await _labor.clockOut(
          franchiseId: widget.franchiseId,
          staffId: matched.id,
          actedByStaffId: matched.id,
        );
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('${matched.name} clocked out')));
      }

      _pinController.clear();
      _pinFocus.requestFocus();
    } on StateError catch (e) {
      setState(() => _error = e.message);
    } catch (e) {
      setState(() {
        _error = clockIn ? 'Clock in failed: $e' : 'Clock out failed: $e';
      });
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Station unlock',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      color: scheme.onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Enter PIN',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _pinController,
                    focusNode: _pinFocus,
                    enabled: !_busy,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
                    textInputAction: TextInputAction.done,
                    onSubmitted: (_) => _submit(),
                    decoration: const InputDecoration(
                      labelText: 'PIN',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _error!,
                      textAlign: TextAlign.center,
                      style: TextStyle(color: scheme.error),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: _busy
                        ? const SizedBox(
                            height: 22,
                            width: 22,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Unlock'),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy ? null : () => _clock(clockIn: true),
                          child: const Text('Clock in'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _busy
                              ? null
                              : () => _clock(clockIn: false),
                          child: const Text('Clock out'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
