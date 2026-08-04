import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import '../dine_in/table_status.dart';
import '../../core/constants/pos_permissions.dart';
import '../../providers/pin_session_provider.dart';
import '../payments/payment_screen.dart';
import '../../services/print_service.dart';
import 'pos_modifier_dialog.dart';
import 'package:flutter/foundation.dart';

class _DeliveryCustomer {
  final String name;
  final String phone;
  final String street;
  final String city;
  final String state;
  final String zip;

  const _DeliveryCustomer({
    required this.name,
    required this.phone,
    required this.street,
    required this.city,
    required this.state,
    required this.zip,
  });

  String get addressLine => '$street, $city, $state $zip';
}

class OrderEntryScreen extends StatefulWidget {
  final String franchiseId;
  final String orderType; // carryout | dine_in | delivery
  final String? tableId;
  final String? tableLabel;

  /// When set, Send **appends** lines to this order instead of creating one.
  final String? existingOrderId;

  const OrderEntryScreen({
    super.key,
    required this.franchiseId,
    this.orderType = 'carryout',
    this.tableId,
    this.tableLabel,
    this.existingOrderId,
  });
  @override
  State<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen> {
  final List<_TicketLine> _lines = [];
  bool _sending = false;
  _DeliveryCustomer? _deliveryCustomer;

  bool get _isDelivery => widget.orderType == 'delivery';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _loadStoreOpsTax();
    });
    if (_isDelivery) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptDeliveryCustomer();
      });
    }
  }

  Future<void> _promptDeliveryCustomer() async {
    final result = await showDialog<_DeliveryCustomer>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _DeliveryCustomerDialog(),
    );
    if (!mounted) return;
    if (result == null) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _deliveryCustomer = result);
  }

  Stream<List<MenuItem>> _menuStream() {
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('menu_items')
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((d) => MenuItem.fromFirestore(d.data(), d.id))
              .where((m) => m.isSellable)
              .toList();
          items.sort((a, b) => a.name.compareTo(b.name));
          return items;
        });
  }

  Future<void> _addSimpleLine(MenuItem item) async {
    if (_isDelivery && _deliveryCustomer == null) {
      await _promptDeliveryCustomer();
      if (_deliveryCustomer == null) return;
    }

    Map<String, dynamic> customizations = {};
    if (item.effectiveModifierGroups.isNotEmpty) {
      final result = await PosModifierDialog.show(context, item);
      if (result == null) return;
      customizations = result;
    }

    setState(() {
      final existing = _lines.indexWhere(
        (l) =>
            l.menuItemId == item.id &&
            _mapEquals(l.customizations, customizations),
      );
      if (existing >= 0) {
        _lines[existing] = _lines[existing].copyWith(
          quantity: _lines[existing].quantity + 1,
        );
      } else {
        _lines.add(
          _TicketLine(
            menuItemId: item.id,
            name: item.name,
            unitPrice: item.price,
            quantity: 1,
            customizations: customizations,
          ),
        );
      }
    });
  }

  bool _mapEquals(Map<String, dynamic> a, Map<String, dynamic> b) {
    if (a.length != b.length) return false;
    for (final key in a.keys) {
      if (a[key].toString() != b[key].toString()) return false;
    }
    return true;
  }

  double get _subtotal =>
      _lines.fold(0.0, (sum, l) => sum + l.unitPrice * l.quantity);

  /// Provisional rate — matches mobile checkout (`0.0925`) until franchise tax config exists.
  /// Do not invent a new config field here.
  double _taxRate = 0.0925;
  bool _storeOpsLoadStarted = false;

  double _moneyRound(double v) => (v * 100).roundToDouble() / 100.0;

  /// Taxable amount = subtotal − discount (never below 0).
  double _taxableAmount({required double subtotal, required double discount}) {
    final v = subtotal - discount;
    return v <= 0 ? 0.0 : _moneyRound(v);
  }

  /// Tax = taxable amount × rate.
  double _taxFor(double taxableAmount) {
    if (taxableAmount <= 0) return 0.0;
    return _moneyRound(taxableAmount * _taxRate);
  }

  /// Total = taxable + tax + fees.
  double _totalFor({
    required double subtotal,
    required double discount,
    double deliveryFee = 0.0,
  }) {
    final taxable = _taxableAmount(subtotal: subtotal, discount: discount);
    final tax = _taxFor(taxable);
    final total = taxable + tax + deliveryFee;
    return total <= 0 ? 0.0 : _moneyRound(total);
  }

  String? _validateDelivery() {
    if (!_isDelivery) return null;
    if (_deliveryCustomer == null) {
      return 'Customer information required for delivery';
    }
    return null;
  }

  Future<void> _loadStoreOpsTax() async {
    if (_storeOpsLoadStarted) return;
    _storeOpsLoadStarted = true;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(widget.franchiseId)
          .collection('config')
          .doc('store_ops')
          .get();
      final rate = (snap.data()?['taxRate'] as num?)?.toDouble();
      if (rate != null && rate >= 0 && mounted) {
        setState(() => _taxRate = rate);
      }
    } catch (e) {
      debugPrint('[POS] store_ops tax load failed: $e');
    }
  }

  Future<void> _markTableSeated(String tableId) async {
    await setTableStatus(
      franchiseId: widget.franchiseId,
      tableId: tableId,
      status: 'seated',
    );
  }

  Future<String?> _createOrderDoc({required String status}) async {
    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final staff = session.staff;
    if (staff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session locked — unlock again')),
      );
      return null;
    }
    if (!session.hasPermission(PosPermissions.takeOrder)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No take_order permission')));
      return null;
    }

    final deliveryError = _validateDelivery();
    if (deliveryError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(deliveryError)));
      return null;
    }

    final now = DateTime.now();
    final items = _lines
        .map(
          (l) => OrderItem(
            menuItemId: l.menuItemId,
            name: l.name,
            price: l.unitPrice,
            quantity: l.quantity,
            customizations: l.customizations,
          ),
        )
        .toList();

    final subtotal = _subtotal;
    // Order-level discount at create is 0 today (payment-time discount is on PaymentScreen).
    const discount = 0.0;
    final taxable = _taxableAmount(subtotal: subtotal, discount: discount);
    final tax = _taxFor(taxable);
    final total = _totalFor(
      subtotal: subtotal,
      discount: discount,
      deliveryFee: 0.0,
    );
    final customer = _deliveryCustomer;
    final customerName = _isDelivery ? customer!.name : staff.name;

    Address? deliveryAddress;
    if (_isDelivery && customer != null) {
      deliveryAddress = Address(
        id: 'pos_delivery',
        street: customer.street,
        city: customer.city,
        state: customer.state,
        zip: customer.zip,
        label: 'Delivery',
        name: customer.name,
      );
    }

    final order = Order(
      id: '',
      userId: staff.id,
      storeId: widget.franchiseId,
      items: items,
      subtotal: subtotal,
      tax: tax,
      deliveryFee: 0,
      discount: 0,
      total: total,
      deliveryType: widget.orderType,
      time: '',
      status: status,
      timestamp: now,
      estimatedTime: 20,
      timestamps: {
        'created': now.toIso8601String(),
        status: now.toIso8601String(),
      },
      userName: customerName,
      deliveryAddress: deliveryAddress,
      specialInstructions: null,
      source: 'pos',
    );

    final col = FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('orders');

    // Append to open dine-in ticket
    final existingId = widget.existingOrderId;
    if (existingId != null && existingId.isNotEmpty) {
      final ref = col.doc(existingId);
      final snap = await ref.get();
      if (!snap.exists || snap.data() == null) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(const SnackBar(content: Text('Open order not found')));
        }
        return null;
      }
      final existing = Order.fromFirestore(snap.data()!, snap.id);
      final nowMs = DateTime.now().millisecondsSinceEpoch;
      final newItems = <OrderItem>[];
      for (var i = 0; i < items.length; i++) {
        final it = items[i];
        newItems.add(
          OrderItem(
            menuItemId: it.menuItemId,
            name: it.name,
            price: it.price,
            quantity: it.quantity,
            customizations: it.customizations,
            image: it.image,
            size: it.size,
            cartItemKey: it.cartItemKey ?? '${it.menuItemId}_${nowMs}_$i',
            lineStatus: 'active',
          ),
        );
      }
      final mergedItems = [...existing.items, ...newItems];
      // Active lines only (voided/comped contribute 0).
      final subtotal = mergedItems.fold<double>(
        0,
        (s, i) => s + i.effectiveLineTotal,
      );
      final discount = existing.discount;
      final taxable = _taxableAmount(subtotal: subtotal, discount: discount);
      final tax = _taxFor(taxable);
      final total = _totalFor(
        subtotal: subtotal,
        discount: discount,
        deliveryFee: existing.deliveryFee,
      );
      await ref.set({
        'items': mergedItems.map((i) => i.toMap()).toList(),
        'subtotal': subtotal,
        'tax': tax,
        'total': total,
        'timestamps.updated': DateTime.now().toIso8601String(),
        'timestamps.line_adjusted': DateTime.now().toIso8601String(),
      }, SetOptions(merge: true));
      // Do not change table status on append
      return existingId;
    }

    final ref = col.doc();
    final data = order.copyWith(id: ref.id).toFirestore();
    data['staffId'] = staff.id;
    data['staffName'] = staff.name;
    if (_isDelivery && customer != null) {
      data['customerPhone'] = customer.phone;
    }
    if (widget.tableId != null && widget.tableId!.isNotEmpty) {
      data['tableId'] = widget.tableId;
      data['tableLabel'] = widget.tableLabel ?? widget.tableId;
    }
    await ref.set(data);
    final tableId = widget.tableId;
    if (tableId != null &&
        tableId.isNotEmpty &&
        widget.orderType == 'dine_in') {
      try {
        await _markTableSeated(tableId);
      } catch (_) {
        // Order is already written; map color can be fixed on refresh.
      }
    }
    return ref.id;
  }

  Future<void> _mockKitchenTicketForOrder(
    String orderId, {
    required bool isAppend,
  }) async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(widget.franchiseId)
          .collection('orders')
          .doc(orderId)
          .get();
      if (!doc.exists || doc.data() == null) return;
      final data = doc.data()!;
      final order = Order.fromFirestore(data, doc.id);
      // tableLabel is POS-only on the order doc; not a shared Order model field.
      final tableLabelFromDoc = data['tableLabel'] as String?;
      await const PrintService().printKitchenTicket(
        order: order,
        tableLabel: widget.tableLabel ?? tableLabelFromDoc,
        isAppend: isAppend,
      );
    } catch (e) {
      // Order already committed — print must not fail the send path.
      debugPrint('[POS] mock kitchen ticket skipped: $e');
    }
  }

  Future<void> _sendUnpaid() async {
    if (_lines.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final id = await _createOrderDoc(status: OrderStatus.sentToKitchen);
      if (id == null) {
        if (mounted) setState(() => _sending = false);
        return;
      }
      final isAppend =
          widget.existingOrderId != null && widget.existingOrderId!.isNotEmpty;
      await _mockKitchenTicketForOrder(id, isAppend: isAppend);
      if (!mounted) return;
      setState(() {
        _lines.clear();
        _sending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            isAppend
                ? 'Order $id updated · kitchen ticket (mock)'
                : 'Order $id sent to kitchen · ticket (mock)',
          ),
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Send failed: $e')));
    }
  }

  Future<void> _payAndSend() async {
    if (_lines.isEmpty || _sending) return;
    setState(() => _sending = true);
    try {
      final id = await _createOrderDoc(status: OrderStatus.open);
      if (id == null) {
        if (mounted) setState(() => _sending = false);
        return;
      }
      if (!mounted) return;

      final amountDue = _totalFor(subtotal: _subtotal, discount: 0.0);
      final paid = await Navigator.of(context).push<bool>(
        MaterialPageRoute<bool>(
          builder: (_) => PaymentScreen(
            franchiseId: widget.franchiseId,
            orderId: id,
            amountDue: amountDue,
            closeOutOrder: false,
            statusWhenPaid: OrderStatus.sentToKitchen,
          ),
        ),
      );

      if (!mounted) return;
      setState(() => _sending = false);

      if (paid == true) {
        await _mockKitchenTicketForOrder(id, isAppend: false);
        if (!mounted) return;
        setState(() => _lines.clear());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order $id paid and sent to kitchen · ticket (mock)'),
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Order $id saved as open — pay from board when ready',
            ),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      setState(() => _sending = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Pay & send failed: $e')));
    }
  }

  Widget _buildDeliverySummary(ColorScheme scheme) {
    final c = _deliveryCustomer;
    if (c == null) {
      return Padding(
        padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
        child: Row(
          children: [
            Expanded(
              child: Text(
                'No customer info',
                style: TextStyle(color: scheme.error, fontSize: 13),
              ),
            ),
            TextButton(
              onPressed: _promptDeliveryCustomer,
              child: const Text('Add'),
            ),
          ],
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 4),
      child: Row(
        children: [
          Icon(Icons.delivery_dining, size: 18, color: scheme.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              '${c.name} · ${c.addressLine}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
            ),
          ),
          IconButton(
            tooltip: 'Edit customer',
            icon: const Icon(Icons.edit_outlined, size: 18),
            onPressed: _promptDeliveryCustomer,
            visualDensity: VisualDensity.compact,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = switch (widget.orderType) {
      'dine_in' => 'Dine-in',
      'delivery' => 'Delivery',
      _ => 'Carry-out',
    };

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(title: Text(title)),
      body: SafeArea(
        child: Row(
          children: [
            Expanded(
              flex: 3,
              child: StreamBuilder<List<MenuItem>>(
                stream: _menuStream(),
                builder: (context, snapshot) {
                  if (snapshot.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Menu error:\n${snapshot.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    );
                  }
                  if (!snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final items = snapshot.data!;
                  if (items.isEmpty) {
                    return Center(
                      child: Text(
                        'No menu items',
                        style: TextStyle(color: scheme.onSurfaceVariant),
                      ),
                    );
                  }
                  return GridView.builder(
                    padding: const EdgeInsets.all(12),
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 8,
                          crossAxisSpacing: 8,
                          childAspectRatio: 1.4,
                        ),
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return Card(
                        child: InkWell(
                          onTap: () => _addSimpleLine(item),
                          child: Padding(
                            padding: const EdgeInsets.all(12),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  item.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.titleSmall,
                                ),
                                const Spacer(),
                                Text(
                                  '\$${item.price.toStringAsFixed(2)}',
                                  style: TextStyle(
                                    color: scheme.primary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
            VerticalDivider(width: 1, color: scheme.outlineVariant),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.existingOrderId != null
                              ? 'Add to order'
                              : 'Ticket',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        if (widget.tableLabel != null &&
                            widget.tableLabel!.isNotEmpty)
                          Text(
                            'Table ${widget.tableLabel}',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: scheme.onSurfaceVariant),
                          ),
                      ],
                    ),
                  ),
                  if (_isDelivery) ...[
                    _buildDeliverySummary(scheme),
                    const Divider(height: 1),
                  ],
                  Expanded(
                    child: _lines.isEmpty
                        ? Center(
                            child: Text(
                              'Tap items to add',
                              style: TextStyle(color: scheme.onSurfaceVariant),
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            itemCount: _lines.length,
                            itemBuilder: (context, index) {
                              final line = _lines[index];
                              return ListTile(
                                title: Text(line.name),
                                subtitle: Text(
                                  '\$${line.unitPrice.toStringAsFixed(2)} × ${line.quantity}',
                                ),
                                trailing: IconButton(
                                  icon: const Icon(Icons.remove_circle_outline),
                                  onPressed: () {
                                    setState(() {
                                      if (line.quantity <= 1) {
                                        _lines.removeAt(index);
                                      } else {
                                        _lines[index] = line.copyWith(
                                          quantity: line.quantity - 1,
                                        );
                                      }
                                    });
                                  },
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  Padding(
                    padding: EdgeInsets.fromLTRB(
                      12,
                      12,
                      12,
                      12 + MediaQuery.of(context).padding.bottom,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Subtotal  \$${_subtotal.toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (_isDelivery) ...[
                          FilledButton(
                            onPressed: _lines.isEmpty || _sending
                                ? null
                                : _payAndSend,
                            child: _sending
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text('Pay & send'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _lines.isEmpty || _sending
                                ? null
                                : _sendUnpaid,
                            child: const Text('Send unpaid (COD)'),
                          ),
                        ] else
                          FilledButton(
                            onPressed: _lines.isEmpty || _sending
                                ? null
                                : _sendUnpaid,
                            child: _sending
                                ? const SizedBox(
                                    height: 22,
                                    width: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    widget.existingOrderId != null
                                        ? 'Add to order'
                                        : 'Send to kitchen',
                                  ),
                          ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DeliveryCustomerDialog extends StatefulWidget {
  const _DeliveryCustomerDialog();

  @override
  State<_DeliveryCustomerDialog> createState() =>
      _DeliveryCustomerDialogState();
}

class _DeliveryCustomerDialogState extends State<_DeliveryCustomerDialog> {
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _streetController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _zipController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _streetController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _zipController.dispose();
    super.dispose();
  }

  void _submit() {
    final name = _nameController.text.trim();
    final phone = _phoneController.text.trim();
    final street = _streetController.text.trim();
    final city = _cityController.text.trim();
    final state = _stateController.text.trim();
    final zip = _zipController.text.trim();

    if (name.isEmpty ||
        phone.isEmpty ||
        street.isEmpty ||
        city.isEmpty ||
        state.isEmpty ||
        zip.isEmpty) {
      setState(() => _error = 'All fields are required');
      return;
    }

    Navigator.of(context).pop(
      _DeliveryCustomer(
        name: name,
        phone: phone,
        street: street,
        city: city,
        state: state,
        zip: zip,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Delivery customer'),
      content: SizedBox(
        width: 420,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextField(
                controller: _nameController,
                autofocus: true,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Customer name',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Phone',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _streetController,
                textInputAction: TextInputAction.next,
                decoration: const InputDecoration(
                  labelText: 'Street',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    flex: 3,
                    child: TextField(
                      controller: _cityController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'City',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextField(
                      controller: _stateController,
                      textInputAction: TextInputAction.next,
                      decoration: const InputDecoration(
                        labelText: 'St',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _zipController,
                      keyboardType: TextInputType.number,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _submit(),
                      decoration: const InputDecoration(
                        labelText: 'ZIP',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              ),
              if (_error != null) ...[
                const SizedBox(height: 10),
                Text(_error!, style: TextStyle(color: scheme.error)),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(onPressed: _submit, child: const Text('Continue')),
      ],
    );
  }
}

class _TicketLine {
  final String menuItemId;
  final String name;
  final double unitPrice;
  final int quantity;
  final Map<String, dynamic> customizations;

  const _TicketLine({
    required this.menuItemId,
    required this.name,
    required this.unitPrice,
    required this.quantity,
    this.customizations = const {},
  });

  _TicketLine copyWith({int? quantity}) {
    return _TicketLine(
      menuItemId: menuItemId,
      name: name,
      unitPrice: unitPrice,
      quantity: quantity ?? this.quantity,
      customizations: customizations,
    );
  }
}
