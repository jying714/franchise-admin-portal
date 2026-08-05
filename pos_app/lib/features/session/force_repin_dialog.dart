import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

import '../../providers/pin_session_provider.dart';

/// Fresh PIN check for elevated actions without locking the station session.
///
/// Do **not** call [PinSessionProvider.lockForRepin] here: that sets
/// `isUnlocked == false` and rebuilds the app to [PinUnlockScreen], which
/// tears down open dialogs (void, assign driver, etc.).
class ForceRepinDialog extends StatefulWidget {
  final String franchiseId;
  final String reasonLabel;

  const ForceRepinDialog({
    super.key,
    required this.franchiseId,
    required this.reasonLabel,
  });

  static Future<bool> show(
    BuildContext context, {
    required String franchiseId,
    required String reasonLabel,
  }) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (session.staff == null) return false;

    final result = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) =>
          ForceRepinDialog(franchiseId: franchiseId, reasonLabel: reasonLabel),
    );
    return result == true;
  }

  @override
  State<ForceRepinDialog> createState() => _ForceRepinDialogState();
}

class _ForceRepinDialogState extends State<ForceRepinDialog> {
  final _pinController = TextEditingController();
  final _posFs = PosFirestoreService();
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final staff = session.staff;
    if (staff == null) {
      setState(() => _error = 'Session lost — unlock station again');
      return;
    }

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
      // Prefer live hash from Firestore in case session staff is stale.
      final fresh = await _posFs.getStaff(widget.franchiseId, staff.id);
      final hash = fresh?.pinHash ?? staff.pinHash;
      final ok = PinHash.verify(pin, hash);

      if (!ok) {
        if (!mounted) return;
        setState(() {
          _busy = false;
          _error = 'Invalid PIN';
          _pinController.clear();
        });
        return;
      }

      if (!mounted) return;
      // Refresh session staff if Firestore returned a newer doc.
      if (fresh != null) {
        session.unlock(fresh);
      } else {
        session.touch();
      }
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'PIN check failed';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final staff = context.watch<PinSessionProvider>().staff;

    return AlertDialog(
      title: const Text('Manager PIN required'),
      content: SizedBox(
        width: 320,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.reasonLabel,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
            if (staff != null) ...[
              const SizedBox(height: 4),
              Text(
                staff.name,
                style: TextStyle(
                  color: scheme.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextField(
              controller: _pinController,
              autofocus: true,
              obscureText: true,
              enabled: !_busy,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(8),
              ],
              decoration: const InputDecoration(
                labelText: 'PIN',
                border: OutlineInputBorder(),
              ),
              onSubmitted: (_) => _submit(),
            ),
            if (_error != null) ...[
              const SizedBox(height: 8),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _busy ? null : () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: _busy ? null : _submit,
          child: _busy
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('Confirm'),
        ),
      ],
    );
  }
}
