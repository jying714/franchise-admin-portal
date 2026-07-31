import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';

import '../../core/constants/pos_permissions.dart';
import '../../providers/pin_session_provider.dart';

class PaymentScreen extends StatefulWidget {
  final String franchiseId;
  final String orderId;
  final double amountDue;

  const PaymentScreen({
    super.key,
    required this.franchiseId,
    required this.orderId,
    required this.amountDue,
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _tenderController = TextEditingController();
  bool _busy = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tenderController.text = widget.amountDue.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _tenderController.dispose();
    super.dispose();
  }

  double? get _tendered {
    final v = double.tryParse(_tenderController.text.trim());
    return v;
  }

  double? get _change {
    final t = _tendered;
    if (t == null) return null;
    return t - widget.amountDue;
  }

  Future<void> _completeCash() async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!session.hasPermission(PosPermissions.takePayment)) {
      setState(() => _error = 'No take_payment permission');
      return;
    }
    final tendered = _tendered;
    if (tendered == null || tendered < widget.amountDue) {
      setState(() => _error = 'Tender must cover amount due');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
    });

    try {
      final now = DateTime.now();
      final ref = FirebaseFirestore.instance
          .collection('franchises')
          .doc(widget.franchiseId)
          .collection('orders')
          .doc(widget.orderId);

      await ref.set({
        'status': OrderStatus.completed,
        'paymentMethod': 'cash',
        'amountTendered': tendered,
        'changeDue': tendered - widget.amountDue,
        'paidAt': now.toIso8601String(),
        'timestamps.completed': now.toIso8601String(),
        'timestamps.paid': now.toIso8601String(),
      }, SetOptions(merge: true));

      // Drawer kick — mock until hardware (Phase 10 / 5.2)
      // ignore: avoid_print
      print('[POS] cash drawer kick (mock)');

      if (!mounted) return;
      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = 'Payment failed: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final change = _change;

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Amount due',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
            ),
            Text(
              '\$${widget.amountDue.toStringAsFixed(2)}',
              style: Theme.of(
                context,
              ).textTheme.displaySmall?.copyWith(color: scheme.onSurface),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: _tenderController,
              enabled: !_busy,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
              ],
              decoration: const InputDecoration(
                labelText: 'Cash tendered',
                border: OutlineInputBorder(),
                prefixText: '\$ ',
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 16),
            Text(
              change == null
                  ? 'Change: —'
                  : 'Change: \$${change.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                color: (change != null && change < 0)
                    ? scheme.error
                    : scheme.onSurface,
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 12),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
            const Spacer(),
            FilledButton(
              onPressed: _busy ? null : _completeCash,
              child: _busy
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Complete cash payment'),
            ),
            const SizedBox(height: 8),
            OutlinedButton(
              onPressed: _busy
                  ? null
                  : () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Card-present — later in Phase 5'),
                        ),
                      );
                    },
              child: const Text('Card (coming soon)'),
            ),
          ],
        ),
      ),
    );
  }
}
