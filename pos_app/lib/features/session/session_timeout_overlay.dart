import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

import '../../providers/pin_session_provider.dart';

class SessionTimeoutOverlay extends StatefulWidget {
  final String franchiseId;
  final Duration grace;

  const SessionTimeoutOverlay({
    super.key,
    required this.franchiseId,
    this.grace = const Duration(seconds: 30),
  });

  @override
  State<SessionTimeoutOverlay> createState() => _SessionTimeoutOverlayState();
}

class _SessionTimeoutOverlayState extends State<SessionTimeoutOverlay> {
  final _pin = TextEditingController();
  final _posFs = PosFirestoreService();
  Timer? _tick;
  late int _left;
  String? _error;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _left = widget.grace.inSeconds;
    _tick = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      if (_left <= 1) {
        _tick?.cancel();
        Provider.of<PinSessionProvider>(context, listen: false).lock();
        return;
      }
      setState(() => _left -= 1);
    });
  }

  @override
  void dispose() {
    _tick?.cancel();
    _pin.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final staff = session.staff;
    if (staff == null) {
      session.lock();
      return;
    }
    final pin = _pin.text.trim();
    if (pin.isEmpty) {
      setState(() => _error = 'Enter PIN');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final fresh = await _posFs.getStaff(widget.franchiseId, staff.id);
      final ok = PinHash.verify(pin, fresh?.pinHash ?? staff.pinHash);
      if (!ok) {
        setState(() => _error = 'Invalid PIN');
        return;
      }
      session.unlock(staff);
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Station locked',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 8),
                  Text('Unlock in $_left s or enter PIN'),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _pin,
                    obscureText: true,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                      LengthLimitingTextInputFormatter(8),
                    ],
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
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.error,
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: const Text('Unlock'),
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
