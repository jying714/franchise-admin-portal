import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import '../dine_in/table_status.dart';
import '../../core/constants/pos_permissions.dart';
import '../../providers/pin_session_provider.dart';
import '../ordering/widgets/discount_sheet.dart';
import 'split_tender_sheet.dart';

class PaymentScreen extends StatefulWidget {
  final String franchiseId;
  final String orderId;
  final double amountDue;
  final bool closeOutOrder;
  final String statusWhenPaid;
  final Set<String> allowedMethods;

  const PaymentScreen({
    super.key,
    required this.franchiseId,
    required this.orderId,
    required this.amountDue,
    this.closeOutOrder = true,
    this.statusWhenPaid = OrderStatus.sentToKitchen,
    this.allowedMethods = const {'cash', 'split', 'card'},
  });

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  final _tenderController = TextEditingController();
  final _posFs = PosFirestoreService();

  bool _busy = false;
  String? _error;

  double _discountAmount = 0;
  String? _discountLabel;
  int _maxSplitTenders = 3;

  Order? _order;
  bool _orderLoading = true;
  String? _orderError;

  double get _baseDue => widget.amountDue;

  double get _dueAfterDiscount {
    final v = _baseDue - _discountAmount;
    return v < 0 ? 0 : (v * 100).roundToDouble() / 100.0;
  }

  @override
  void initState() {
    super.initState();
    _tenderController.text = _dueAfterDiscount.toStringAsFixed(2);
    _loadSettings();
    _loadOrder();
  }

  Future<void> _loadSettings() async {
    try {
      final settings = await _posFs.getPosSettings(widget.franchiseId);
      if (!mounted) return;
      setState(() {
        _maxSplitTenders = settings.maxSplitTenders;
      });
    } catch (_) {
      // Keep default 3
    }
  }

  Future<void> _loadOrder() async {
    setState(() {
      _orderLoading = true;
      _orderError = null;
    });
    try {
      final doc = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(widget.franchiseId)
          .collection('orders')
          .doc(widget.orderId)
          .get();
      if (!doc.exists || doc.data() == null) {
        if (!mounted) return;
        setState(() {
          _orderLoading = false;
          _orderError = 'Order not found';
        });
        return;
      }
      final order = Order.fromFirestore(doc.data()!, doc.id);
      if (!mounted) return;
      setState(() {
        _order = order;
        _orderLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _orderLoading = false;
        _orderError = 'Could not load order';
      });
    }
  }

  @override
  void dispose() {
    _tenderController.dispose();
    super.dispose();
  }

  double? get _tendered {
    return double.tryParse(_tenderController.text.trim());
  }

  double? get _change {
    final t = _tendered;
    if (t == null) return null;
    return t - _dueAfterDiscount;
  }

  bool _canTakeCash(PinSessionProvider session) {
    return session.hasPermission(PosPermissions.takePayment) &&
        session.hasPermission(PosPermissions.openDrawer);
  }

  String _typeLabel(String raw) {
    final t = raw.trim().toLowerCase();
    if (t == 'dine_in' || t == 'dine-in' || t == 'dinein') return 'Dine-in';
    if (t == 'delivery') return 'Delivery';
    if (t == 'carryout' ||
        t == 'carry-out' ||
        t == 'carry_out' ||
        t == 'takeout') {
      return 'Carry-out';
    }
    return raw.isEmpty ? 'Carry-out' : raw;
  }

  String _sourceLabel(Order order) {
    final s = order.source.trim().toLowerCase();
    if (s.isEmpty) return 'mobile';
    return s;
  }

  Future<void> _openDiscount() async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!session.hasPermission(PosPermissions.discount)) {
      setState(() => _error = 'No discount permission');
      return;
    }

    final result = await DiscountSheet.show(context, baseAmount: _baseDue);
    if (result == null || !mounted) return;

    setState(() {
      _discountAmount = result.amount;
      _discountLabel = result.label;
      _error = null;
      _tenderController.text = _dueAfterDiscount.toStringAsFixed(2);
    });
  }

  void _clearDiscount() {
    setState(() {
      _discountAmount = 0;
      _discountLabel = null;
      _tenderController.text = _dueAfterDiscount.toStringAsFixed(2);
    });
  }

  Future<void> _openSplit() async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!_canTakeCash(session)) {
      setState(
        () => _error =
            'Cash / split requires take_payment and open_drawer permissions',
      );
      return;
    }

    final lines = await SplitTenderSheet.show(
      context,
      amountDue: _dueAfterDiscount,
      maxSplitTenders: _maxSplitTenders,
    );
    if (lines == null || lines.isEmpty || !mounted) return;

    await _completeWithTenders(lines);
  }

  Future<void> _completeCash() async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!session.hasPermission(PosPermissions.takePayment)) {
      setState(() => _error = 'No take_payment permission');
      return;
    }
    if (!session.hasPermission(PosPermissions.openDrawer)) {
      setState(() => _error = 'No open_drawer permission — cannot take cash');
      return;
    }
    final tendered = _tendered;
    if (tendered == null || tendered < _dueAfterDiscount) {
      setState(() => _error = 'Tender must cover amount due');
      return;
    }

    await _completeWithTenders([TenderLine(method: 'cash', amount: tendered)]);
  }

  Future<void> _completeWithTenders(List<TenderLine> lines) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    if (!_canTakeCash(session)) {
      setState(
        () => _error =
            'Cash / split requires take_payment and open_drawer permissions',
      );
      return;
    }

    final cashTotal = lines
        .where((l) => l.method == 'cash')
        .fold(0.0, (sum, l) => sum + l.amount);
    final due = _dueAfterDiscount;
    if (cashTotal + 0.001 < due) {
      setState(() => _error = 'Cash must cover amount due');
      return;
    }
    if (lines.any((l) => l.method == 'card')) {
      setState(() => _error = 'Card capture is Phase 5.3 — use cash only');
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

      final isSplit = lines.length > 1;
      final nextStatus = widget.closeOutOrder
          ? OrderStatus.completed
          : widget.statusWhenPaid;

      await ref.set({
        'status': nextStatus,
        'paymentMethod': isSplit ? 'split' : 'cash',
        'tenders': lines.map((l) => l.toMap()).toList(),
        'amountTendered': cashTotal,
        'changeDue': cashTotal - due,
        'discount': _discountAmount,
        if (_discountLabel != null) 'discountLabel': _discountLabel,
        'amountDueAtPay': due,
        'paidAt': now.toIso8601String(),
        if (widget.closeOutOrder) 'timestamps.completed': now.toIso8601String(),
        'timestamps.paid': now.toIso8601String(),
        if (!widget.closeOutOrder)
          'timestamps.${widget.statusWhenPaid}': now.toIso8601String(),
      }, SetOptions(merge: true));

      // ignore: avoid_print
      print('[POS] cash drawer kick (mock)');

      if (widget.closeOutOrder) {
        try {
          final snap = await ref.get();
          final data = snap.data();
          final tableId = data?['tableId'] as String?;
          final deliveryType =
              (data?['deliveryType'] as String?)?.trim().toLowerCase() ?? '';
          if (tableId != null &&
              tableId.isNotEmpty &&
              (deliveryType == 'dine_in' ||
                  deliveryType == 'dine-in' ||
                  deliveryType == 'dinein')) {
            await setTableStatus(
              franchiseId: widget.franchiseId,
              tableId: tableId,
              status: 'free',
            );
          }
        } catch (_) {
          // Payment already committed; map can be corrected on refresh.
        }
      }

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

  Widget _buildOrderDetails(ColorScheme scheme) {
    if (_orderLoading) {
      return const Center(child: CircularProgressIndicator());
    }
    if (_orderError != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            _orderError!,
            textAlign: TextAlign.center,
            style: TextStyle(color: scheme.error),
          ),
        ),
      );
    }

    final order = _order;
    if (order == null) {
      return Center(
        child: Text(
          'Order ${widget.orderId}',
          style: TextStyle(color: scheme.onSurfaceVariant),
        ),
      );
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 120),
      children: [
        Text(
          'Order details',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          order.userNameDisplay,
          style: Theme.of(
            context,
          ).textTheme.headlineSmall?.copyWith(color: scheme.onSurface),
        ),
        const SizedBox(height: 8),
        Text(
          'ID  ${order.id}',
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
        ),
        const SizedBox(height: 12),
        _MetaChipRow(
          children: [
            _MetaChip(label: _typeLabel(order.deliveryType)),
            _MetaChip(label: order.status),
            _MetaChip(label: _sourceLabel(order).toUpperCase()),
          ],
        ),
        const SizedBox(height: 16),
        const Divider(),
        const SizedBox(height: 8),
        Text(
          'Items',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        if (order.items.isEmpty)
          Text(
            'No line items',
            style: TextStyle(color: scheme.onSurfaceVariant),
          )
        else
          ...order.items.map((item) {
            final lineTotal = item.price * item.quantity;
            final mods = item.customizations.entries
                .map((e) => '${e.key}: ${e.value}')
                .join(' · ');
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${item.quantity}×',
                    style: TextStyle(
                      color: scheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.name,
                          style: TextStyle(color: scheme.onSurface),
                        ),
                        if (mods.isNotEmpty)
                          Text(
                            mods,
                            style: TextStyle(
                              color: scheme.onSurfaceVariant,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                  Text(
                    '\$${lineTotal.toStringAsFixed(2)}',
                    style: TextStyle(color: scheme.onSurface),
                  ),
                ],
              ),
            );
          }),
        const Divider(),
        _TotalsRow(label: 'Subtotal', value: order.subtotal),
        _TotalsRow(label: 'Tax', value: order.tax),
        if (order.discount > 0)
          _TotalsRow(label: 'Discount (order)', value: -order.discount),
        _TotalsRow(label: 'Total', value: order.total, emphasize: true),
      ],
    );
  }

  Widget _buildPaymentPanel(ColorScheme scheme, PinSessionProvider session) {
    final change = _change;
    final canDiscount = session.hasPermission(PosPermissions.discount);
    final canCash = _canTakeCash(session);

    return ListView(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 120),
      children: [
        Text(
          'Payment',
          style: Theme.of(
            context,
          ).textTheme.titleMedium?.copyWith(color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 8),
        Text(
          'Amount due',
          style: Theme.of(
            context,
          ).textTheme.titleSmall?.copyWith(color: scheme.onSurfaceVariant),
        ),
        Text(
          '\$${_dueAfterDiscount.toStringAsFixed(2)}',
          style: Theme.of(
            context,
          ).textTheme.displaySmall?.copyWith(color: scheme.onSurface),
        ),
        if (_discountAmount > 0) ...[
          const SizedBox(height: 4),
          Text(
            'Was \$${_baseDue.toStringAsFixed(2)}'
            '${_discountLabel != null ? ' · $_discountLabel' : ''}',
            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
          ),
        ],
        const SizedBox(height: 12),
        Row(
          children: [
            if (canDiscount)
              OutlinedButton.icon(
                onPressed: _busy ? null : _openDiscount,
                icon: const Icon(Icons.percent, size: 18),
                label: const Text('Discount'),
              ),
            if (_discountAmount > 0) ...[
              const SizedBox(width: 8),
              TextButton(
                onPressed: _busy ? null : _clearDiscount,
                child: const Text('Clear discount'),
              ),
            ],
          ],
        ),
        const SizedBox(height: 24),
        TextField(
          controller: _tenderController,
          enabled: !_busy && canCash,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'[0-9.]')),
          ],
          decoration: InputDecoration(
            labelText: 'Cash tendered',
            border: const OutlineInputBorder(),
            prefixText: '\$ ',
            helperText: canCash ? null : 'Requires take_payment + open_drawer',
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
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final session = context.watch<PinSessionProvider>();
    final canCash = _canTakeCash(session);
    final allowCash = canCash && widget.allowedMethods.contains('cash');
    final allowSplit = canCash && widget.allowedMethods.contains('split');
    final allowCard = widget.allowedMethods.contains('card');

    return Scaffold(
      appBar: AppBar(title: const Text('Payment')),
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 5,
            child: ColoredBox(
              color: scheme.surfaceContainerLowest,
              child: _buildOrderDetails(scheme),
            ),
          ),
          VerticalDivider(width: 1, color: scheme.outlineVariant),
          Expanded(flex: 4, child: _buildPaymentPanel(scheme, session)),
        ],
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: [
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'pos_pay_cash',
                onPressed: (_busy || !allowCash) ? null : _completeCash,
                icon: const Icon(Icons.payments_outlined),
                label: const Text('Cash'),
                backgroundColor: allowCash
                    ? scheme.primary
                    : scheme.surfaceContainerHighest,
                foregroundColor: allowCash
                    ? scheme.onPrimary
                    : scheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'pos_pay_split',
                onPressed: (_busy || !allowSplit) ? null : _openSplit,
                icon: const Icon(Icons.call_split),
                label: const Text('Split'),
                backgroundColor: allowSplit
                    ? scheme.secondaryContainer
                    : scheme.surfaceContainerHighest,
                foregroundColor: allowSplit
                    ? scheme.onSecondaryContainer
                    : scheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: FloatingActionButton.extended(
                heroTag: 'pos_pay_card',
                onPressed: (_busy || !allowCard)
                    ? null
                    : () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Card-present — later in Phase 5'),
                          ),
                        );
                      },
                icon: const Icon(Icons.credit_card),
                label: const Text('Card'),
                backgroundColor: allowCard
                    ? scheme.tertiaryContainer
                    : scheme.surfaceContainerHighest,
                foregroundColor: allowCard
                    ? scheme.onTertiaryContainer
                    : scheme.onSurface.withValues(alpha: 0.38),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChipRow extends StatelessWidget {
  final List<Widget> children;

  const _MetaChipRow({required this.children});

  @override
  Widget build(BuildContext context) {
    return Wrap(spacing: 8, runSpacing: 8, children: children);
  }
}

class _MetaChip extends StatelessWidget {
  final String label;

  const _MetaChip({required this.label});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Chip(
      label: Text(
        label,
        style: TextStyle(fontSize: 12, color: scheme.onSurface),
      ),
      visualDensity: VisualDensity.compact,
      padding: EdgeInsets.zero,
      backgroundColor: scheme.surfaceContainerHighest,
    );
  }
}

class _TotalsRow extends StatelessWidget {
  final String label;
  final double value;
  final bool emphasize;

  const _TotalsRow({
    required this.label,
    required this.value,
    this.emphasize = false,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final style = emphasize
        ? Theme.of(context).textTheme.titleMedium?.copyWith(
            color: scheme.onSurface,
            fontWeight: FontWeight.w700,
          )
        : TextStyle(color: scheme.onSurfaceVariant);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(child: Text(label, style: style)),
          Text('\$${value.toStringAsFixed(2)}', style: style),
        ],
      ),
    );
  }
}
