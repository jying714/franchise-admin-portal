import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

import '../../core/utils/pin_hash.dart';
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
  final _staffIdController = TextEditingController();
  final _pinController = TextEditingController();
  final _posFs = PosFirestoreService();

  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _staffIdController.dispose();
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final staffId = _staffIdController.text.trim();
    final pin = _pinController.text.trim();

    if (staffId.isEmpty || pin.isEmpty) {
      setState(() => _error = 'Enter staff ID and PIN');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final staff = await _posFs.getStaff(widget.franchiseId, staffId);
      if (staff == null) {
        setState(() => _error = 'Staff not found');
        return;
      }
      if (staff.status != 'active') {
        setState(() => _error = 'Staff inactive');
        return;
      }
      if (!staff.posEnabled) {
        setState(() => _error = 'POS access disabled for this staff');
        return;
      }
      if (staff.pinHash == null || staff.pinHash!.isEmpty) {
        setState(() => _error = 'PIN not set — ask a manager');
        return;
      }
      if (!PinHash.verify(pin, staff.pinHash)) {
        setState(() => _error = 'Invalid PIN');
        return;
      }

      if (!mounted) return;
      Provider.of<PinSessionProvider>(context, listen: false).unlock(staff);
      _pinController.clear();
      widget.onUnlocked?.call();
    } catch (e) {
      setState(() => _error = 'Unlock failed');
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
                    'Franchise: ${widget.franchiseId}',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: scheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                  TextField(
                    controller: _staffIdController,
                    enabled: !_busy,
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(
                      labelText: 'Staff ID',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _pinController,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
