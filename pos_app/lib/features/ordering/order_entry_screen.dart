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
import 'package:flutter/foundation.dart' hide Category;

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
  String? _customerPhone;

  /// null = category picker; non-null = items in that category.
  String? _selectedCategoryId;
  String? _selectedCategoryName;

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
    } else if (widget.existingOrderId == null) {
      // New carryout / dine-in ticket — collect contact phone once.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _promptCustomerPhone();
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
    setState(() {
      _deliveryCustomer = result;
      _customerPhone = result.phone.trim();
    });
  }

  Future<void> _promptCustomerPhone() async {
    final result = await showDialog<String>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CustomerPhoneDialog(),
    );
    if (!mounted) return;
    if (result == null || result.trim().isEmpty) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _customerPhone = result.trim());
  }

  Stream<List<Category>> _categoryStream() {
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('categories')
        .snapshots()
        .map((snap) {
          final cats = snap.docs
              .map((d) => Category.fromFirestore(d.data(), d.id))
              .where((c) => c.isActive)
              .toList();
          cats.sort((a, b) {
            final ao = a.sortOrder ?? 9999;
            final bo = b.sortOrder ?? 9999;
            if (ao != bo) return ao.compareTo(bo);
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
          return cats;
        });
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
          items.sort((a, b) {
            final ao = a.sortOrder ?? 9999;
            final bo = b.sortOrder ?? 9999;
            if (ao != bo) return ao.compareTo(bo);
            return a.name.toLowerCase().compareTo(b.name.toLowerCase());
          });
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

  /// Flat delivery fee in dollars. Loaded from config/store_ops.deliveryFee.
  /// Used only when orderType == delivery. Fallback 0.0 keeps prior POS behavior
  /// until the doc is read.
  double _deliveryFeeFlat = 0.0;

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
      final data = snap.data();
      final rate = (data?['taxRate'] as num?)?.toDouble();
      final fee = (data?['deliveryFee'] as num?)?.toDouble();
      if (!mounted) return;
      setState(() {
        if (rate != null && rate >= 0) _taxRate = rate;
        if (fee != null && fee >= 0) _deliveryFeeFlat = fee;
      });
    } catch (e) {
      debugPrint('[POS] store_ops tax/fee load failed: $e');
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
    final deliveryFee = _isDelivery ? _deliveryFeeFlat : 0.0;
    final taxable = _taxableAmount(subtotal: subtotal, discount: discount);
    final tax = _taxFor(taxable);
    final total = _totalFor(
      subtotal: subtotal,
      discount: discount,
      deliveryFee: deliveryFee,
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
      deliveryFee: deliveryFee,
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
    final phone = _isDelivery && customer != null
        ? customer.phone.trim()
        : (_customerPhone ?? '').trim();
    if (phone.isNotEmpty) {
      data['customerPhone'] = phone;
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

      // A3: kitchen commit holds stock so web/mobile cannot sell the last unit.
      // First send: whole-order flag. Append: key per batch of new lines only.
      try {
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
        if (isAppend) {
          final decrementKey =
              'append_${DateTime.now().millisecondsSinceEpoch}';
          await InventoryLedger.applyAppendSaleDecrement(
            db: FirebaseFirestore.instance,
            franchiseId: widget.franchiseId,
            orderId: id,
            items: items,
            decrementKey: decrementKey,
          );
        } else {
          await InventoryLedger.applySaleDecrement(
            db: FirebaseFirestore.instance,
            franchiseId: widget.franchiseId,
            orderId: id,
            items: items,
          );
        }
      } catch (e) {
        debugPrint('[POS] inventory decrement on send skipped: $e');
      }

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

      final amountDue = _totalFor(
        subtotal: _subtotal,
        discount: 0.0,
        deliveryFee: _isDelivery ? _deliveryFeeFlat : 0.0,
      );
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

  Widget _buildItemGrid(
    BuildContext context,
    ColorScheme scheme,
    List<MenuItem> items,
  ) {
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
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
        childAspectRatio: 1.1,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) {
        final item = items[index];
        return Material(
          color: scheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
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
              child: StreamBuilder<List<Category>>(
                stream: _categoryStream(),
                builder: (context, catSnap) {
                  if (catSnap.hasError) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Text(
                          'Categories error:\n${catSnap.error}',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: scheme.error),
                        ),
                      ),
                    );
                  }
                  if (!catSnap.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final categories = catSnap.data!;

                  return StreamBuilder<List<MenuItem>>(
                    stream: _menuStream(),
                    builder: (context, menuSnap) {
                      if (menuSnap.hasError) {
                        return Center(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'Menu error:\n${menuSnap.error}',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: scheme.error),
                            ),
                          ),
                        );
                      }
                      if (!menuSnap.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      final allItems = menuSnap.data!;

                      // ---- Category picker ----
                      if (_selectedCategoryId == null) {
                        if (categories.isEmpty) {
                          // Fallback: no categories configured — show all items
                          return _buildItemGrid(context, scheme, allItems);
                        }
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Padding(
                              padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                              child: Text(
                                'Categories',
                                style: Theme.of(context).textTheme.titleMedium,
                              ),
                            ),
                            Expanded(
                              child: GridView.builder(
                                padding: const EdgeInsets.all(12),
                                gridDelegate:
                                    const SliverGridDelegateWithFixedCrossAxisCount(
                                      crossAxisCount: 3,
                                      mainAxisSpacing: 10,
                                      crossAxisSpacing: 10,
                                      childAspectRatio: 1.35,
                                    ),
                                itemCount: categories.length,
                                itemBuilder: (context, index) {
                                  final cat = categories[index];
                                  final label =
                                      (cat.displayName?.isNotEmpty == true)
                                      ? cat.displayName!
                                      : cat.name;
                                  final count = allItems
                                      .where((m) => m.categoryId == cat.id)
                                      .length;
                                  return Material(
                                    color: scheme.surfaceContainerHighest,
                                    borderRadius: BorderRadius.circular(12),
                                    child: InkWell(
                                      borderRadius: BorderRadius.circular(12),
                                      onTap: () {
                                        setState(() {
                                          _selectedCategoryId = cat.id;
                                          _selectedCategoryName = label;
                                        });
                                      },
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              label,
                                              maxLines: 2,
                                              overflow: TextOverflow.ellipsis,
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .titleSmall
                                                  ?.copyWith(
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                            const Spacer(),
                                            Text(
                                              count == 1
                                                  ? '1 item'
                                                  : '$count items',
                                              style: Theme.of(context)
                                                  .textTheme
                                                  .bodySmall
                                                  ?.copyWith(
                                                    color:
                                                        scheme.onSurfaceVariant,
                                                  ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  );
                                },
                              ),
                            ),
                          ],
                        );
                      }

                      // ---- Items in selected category ----
                      final filtered = allItems
                          .where((m) => m.categoryId == _selectedCategoryId)
                          .toList();

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(4, 8, 12, 4),
                            child: Row(
                              children: [
                                IconButton(
                                  tooltip: 'All categories',
                                  onPressed: () {
                                    setState(() {
                                      _selectedCategoryId = null;
                                      _selectedCategoryName = null;
                                    });
                                  },
                                  icon: const Icon(Icons.arrow_back),
                                ),
                                Expanded(
                                  child: Text(
                                    _selectedCategoryName ?? 'Items',
                                    style: Theme.of(
                                      context,
                                    ).textTheme.titleMedium,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: filtered.isEmpty
                                ? Center(
                                    child: Text(
                                      'No items in this category',
                                      style: TextStyle(
                                        color: scheme.onSurfaceVariant,
                                      ),
                                    ),
                                  )
                                : _buildItemGrid(context, scheme, filtered),
                          ),
                        ],
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
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        if (_isDelivery && _deliveryFeeFlat > 0) ...[
                          const SizedBox(height: 2),
                          Text(
                            'Delivery  \$${_deliveryFeeFlat.toStringAsFixed(2)}',
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ],
                        const SizedBox(height: 2),
                        Text(
                          'Tax  \$${_taxFor(_taxableAmount(subtotal: _subtotal, discount: 0.0)).toStringAsFixed(2)}',
                          textAlign: TextAlign.right,
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Total  \$${_totalFor(subtotal: _subtotal, discount: 0.0, deliveryFee: _isDelivery ? _deliveryFeeFlat : 0.0).toStringAsFixed(2)}',
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

class _CustomerPhoneDialog extends StatefulWidget {
  const _CustomerPhoneDialog();

  @override
  State<_CustomerPhoneDialog> createState() => _CustomerPhoneDialogState();
}

class _CustomerPhoneDialogState extends State<_CustomerPhoneDialog> {
  final _phoneController = TextEditingController();
  String? _error;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() {
    final phone = _phoneController.text.trim();
    if (phone.isEmpty) {
      setState(() => _error = 'Phone number is required');
      return;
    }
    Navigator.of(context).pop(phone);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return AlertDialog(
      title: const Text('Customer phone'),
      content: SizedBox(
        width: 360,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            TextField(
              controller: _phoneController,
              autofocus: true,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                labelText: 'Phone',
                border: OutlineInputBorder(),
              ),
            ),
            if (_error != null) ...[
              const SizedBox(height: 10),
              Text(_error!, style: TextStyle(color: scheme.error)),
            ],
          ],
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
