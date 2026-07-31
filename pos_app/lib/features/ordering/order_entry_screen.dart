import 'package:cloud_firestore/cloud_firestore.dart' hide Order;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart';
import '../../core/constants/pos_permissions.dart';
import '../../providers/pin_session_provider.dart';
import '../payments/payment_screen.dart';
import '../../features/ordering/pos_modifier_dialog.dart';

/// Carry-out order entry — Phase 4.1 shell (menu + empty ticket).
class OrderEntryScreen extends StatefulWidget {
  final String franchiseId;
  final String orderType; // carryout | dine_in | delivery

  const OrderEntryScreen({
    super.key,
    required this.franchiseId,
    this.orderType = 'carryout',
  });

  @override
  State<OrderEntryScreen> createState() => _OrderEntryScreenState();
}

class _OrderEntryScreenState extends State<OrderEntryScreen> {
  final List<_TicketLine> _lines = [];
  bool _sending = false;

  Stream<List<MenuItem>> _menuStream() {
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(widget.franchiseId)
        .collection('menu_items')
        .snapshots()
        .map((snap) {
          final items = snap.docs
              .map((d) => MenuItem.fromFirestore(d.data(), d.id))
              .where(
                (m) =>
                    m.availability &&
                    m.available &&
                    !m.archived &&
                    m.hideInMenu != true,
              )
              .toList();
          items.sort((a, b) => a.name.compareTo(b.name));
          return items;
        });
  }

  Future<void> _addSimpleLine(MenuItem item) async {
    Map<String, dynamic> customizations = {};
    if (item.effectiveModifierGroups.isNotEmpty) {
      final result = await PosModifierDialog.show(context, item);
      if (result == null) return; // cancelled
      customizations = result;
    }

    setState(() {
      // Lines with different modifiers stay separate
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

  Future<void> _sendTicket() async {
    if (_lines.isEmpty || _sending) return;

    final session = Provider.of<PinSessionProvider>(context, listen: false);
    final staff = session.staff;
    if (staff == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session locked — unlock again')),
      );
      return;
    }
    if (!session.hasPermission(PosPermissions.takeOrder)) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('No take_order permission')));
      return;
    }

    setState(() => _sending = true);
    try {
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
      final tax = 0.0; // tax calc later
      final total = subtotal + tax;

      final order = Order(
        id: '', // assigned after doc create
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
        status: OrderStatus.sentToKitchen,
        timestamp: now,
        estimatedTime: 20,
        timestamps: {
          'created': now.toIso8601String(),
          'sent_to_kitchen': now.toIso8601String(),
        },
        userName: staff.name,
        specialInstructions: null,
        source: 'pos',
      );

      final col = FirebaseFirestore.instance
          .collection('franchises')
          .doc(widget.franchiseId)
          .collection('orders');
      final ref = col.doc();
      final data = order.copyWith(id: ref.id).toFirestore();
      data['staffId'] = staff.id;
      data['staffName'] = staff.name;
      await ref.set(data);

      if (!mounted) return;
      setState(() {
        _lines.clear();
        _sending = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Order ${ref.id} sent to kitchen')),
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

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final title = switch (widget.orderType) {
      'dine_in' => 'Dine-in',
      'delivery' => 'Delivery',
      _ => 'Carry-out',
    };

    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Row(
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
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
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
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    'Ticket',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                ),
                Expanded(
                  child: _lines.isEmpty
                      ? Center(
                          child: Text(
                            'Tap items to add',
                            style: TextStyle(color: scheme.onSurfaceVariant),
                          ),
                        )
                      : ListView.builder(
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
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Subtotal  \$${_subtotal.toStringAsFixed(2)}',
                        textAlign: TextAlign.right,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 8),
                      FilledButton(
                        onPressed: _lines.isEmpty || _sending
                            ? null
                            : _sendTicket,
                        child: _sending
                            ? const SizedBox(
                                height: 22,
                                width: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              )
                            : const Text('Send to kitchen'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
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
