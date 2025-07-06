import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/order.dart' as order_model;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service.dart';

class OrderManagementScreen extends StatefulWidget {
  const OrderManagementScreen({super.key});

  @override
  State<OrderManagementScreen> createState() => _OrderManagementScreenState();
}

class _OrderManagementScreenState extends State<OrderManagementScreen> {
  String _searchText = '';
  String? _filterStatus;
  DateTimeRange? _dateRange;
  bool _showRefunded = true;
  List<order_model.Order> _lastOrders = [];

  Future<void> _updateOrderStatus(
      order_model.Order order, String newStatus, admin_user.User user) async {
    if (!(user.isOwner || user.isManager)) {
      await AuditLogService().addLog(
        userId: user.id,
        action: 'unauthorized_order_status_change',
        targetType: 'order',
        targetId: order.id,
        details: {'attemptedStatus': newStatus},
      );
      _showUnauthorizedDialog();
      return;
    }
    await Provider.of<FirestoreService>(context, listen: false)
        .updateOrderStatus(order.id, newStatus);
    await AuditLogService().addLog(
      userId: user.id,
      action: 'update_order_status',
      targetType: 'order',
      targetId: order.id,
      details: {'newStatus': newStatus},
    );
  }

  Future<void> _processRefund(
      order_model.Order order, double amount, admin_user.User user) async {
    if (!user.isOwner && !user.isManager) {
      await AuditLogService().addLog(
        userId: user.id,
        action: 'unauthorized_refund_attempt',
        targetType: 'order',
        targetId: order.id,
        details: {'attemptedAmount': amount},
      );
      _showUnauthorizedDialog();
      return;
    }
    await Provider.of<FirestoreService>(context, listen: false)
        .refundOrder(order.id, amount: amount);

    await AuditLogService().addLog(
      userId: user.id,
      action: 'refund_order',
      targetType: 'order',
      targetId: order.id,
      details: {'refundAmount': amount},
    );
  }

  void _showUnauthorizedDialog() {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Unauthorized"),
        content: const Text(
            "You do not have permission to perform this action. This attempt has been logged."),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("OK"),
          ),
        ],
      ),
    );
  }

  void _showRefundDialog(order_model.Order order, admin_user.User user) {
    final controller =
        TextEditingController(text: order.total.toStringAsFixed(2));
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Process Refund"),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: "Refund Amount"),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount > 0 && amount <= order.total) {
                Navigator.of(context).pop();
                _processRefund(order, amount, user);
              }
            },
            child: const Text("Refund"),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(order_model.Order order, admin_user.User user) {
    final List<String> allowedStatuses = [
      'Placed',
      'Preparing',
      'Ready',
      'Out for Delivery',
      'Delivered',
      'Picked Up',
      'Refunded'
    ];
    String selected = order.status;
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setStateDialog) => AlertDialog(
          title: const Text("Update Order Status"),
          content: DropdownButton<String>(
            value: selected,
            items: allowedStatuses
                .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                .toList(),
            onChanged: (val) =>
                setStateDialog(() => selected = val ?? order.status),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.of(context).pop();
                if (selected != order.status) {
                  _updateOrderStatus(order, selected, user);
                }
              },
              child: const Text("Update"),
            ),
          ],
        ),
      ),
    );
  }

  List<order_model.Order> _filterOrders(
      List<order_model.Order> orders, admin_user.User user) {
    return orders.where((o) {
      if (!_showRefunded && o.status == 'Refunded') return false;
      if (_filterStatus != null && o.status != _filterStatus) return false;
      if (_searchText.isNotEmpty &&
          !(o.userNameDisplay
                  .toLowerCase()
                  .contains(_searchText.toLowerCase()) ||
              o.id.toLowerCase().contains(_searchText.toLowerCase()))) {
        return false;
      }
      if (_dateRange != null) {
        if (o.timestamp.isBefore(_dateRange!.start) ||
            o.timestamp.isAfter(_dateRange!.end)) return false;
      }
      return true;
    }).toList();
  }

  void _showExportDialog(
      List<order_model.Order> orders, admin_user.User user) async {
    await AuditLogService().addLog(
      userId: user.id,
      action: 'export_orders',
      targetType: 'order',
      targetId: '',
      details: {'count': orders.length},
    );
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Exported orders (CSV download logic goes here).')));
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<admin_user.User?>(context);

    if (user == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text("Order Management"),
          backgroundColor: DesignTokens.adminPrimaryColor,
        ),
        body: const Center(child: Text("Unauthorized — Please log in.")),
      );
    }

    if (!(user.isOwner || user.isManager)) {
      Future.microtask(() {
        AuditLogService().addLog(
          userId: user.id,
          action: 'unauthorized_order_management_access',
          targetType: 'order_management',
          targetId: '',
          details: {'message': 'User with insufficient role tried to access.'},
        );
      });
      return Scaffold(
        appBar: AppBar(
          title: const Text("Order Management"),
          backgroundColor: DesignTokens.adminPrimaryColor,
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.lock_outline, size: 54, color: Colors.redAccent),
              const SizedBox(height: 16),
              const Text(
                "Unauthorized — You do not have permission to access this page.",
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 18),
              ElevatedButton.icon(
                icon: const Icon(Icons.home),
                label: const Text("Return to Home"),
                onPressed: () {
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
              ),
            ],
          ),
        ),
      );
    }

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Order Management"),
        backgroundColor: DesignTokens.adminPrimaryColor,
        actions: [
          IconButton(
            icon: const Icon(Icons.download),
            tooltip: "Export Orders",
            onPressed: () {
              // Export currently filtered orders
              _showExportDialog(_lastOrders, user);
            },
          )
        ],
      ),
      body: StreamBuilder<List<order_model.Order>>(
        stream: firestoreService.getAllOrdersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const LoadingShimmerWidget();
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const EmptyStateWidget(
              title: "No Orders",
              message: "No orders found.",
              iconData: Icons.receipt_long,
            );
          }
          var orders = _filterOrders(snapshot.data!, user);
          _lastOrders = orders; // cache for export

          return Column(
            children: [
              Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                child: Row(
                  children: [
                    Expanded(
                      child: TextField(
                        decoration: const InputDecoration(
                          labelText: "Search by Order ID or Name",
                          prefixIcon: Icon(Icons.search),
                        ),
                        onChanged: (val) =>
                            setState(() => _searchText = val.trim()),
                      ),
                    ),
                    const SizedBox(width: 8),
                    DropdownButton<String>(
                      value: _filterStatus,
                      hint: const Text("Status"),
                      items: [
                        null,
                        'Placed',
                        'Preparing',
                        'Ready',
                        'Out for Delivery',
                        'Delivered',
                        'Picked Up',
                        'Refunded'
                      ]
                          .map(
                            (s) => DropdownMenuItem<String>(
                              value: s,
                              child: Text(s ?? "All"),
                            ),
                          )
                          .toList(),
                      onChanged: (val) => setState(() => _filterStatus = val),
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.calendar_today),
                      tooltip: "Filter by Date",
                      onPressed: () async {
                        final range = await showDateRangePicker(
                          context: context,
                          firstDate: DateTime.now()
                              .subtract(const Duration(days: 365)),
                          lastDate: DateTime.now().add(const Duration(days: 1)),
                        );
                        if (range != null) {
                          setState(() => _dateRange = range);
                        }
                      },
                    ),
                    Checkbox(
                      value: _showRefunded,
                      onChanged: (val) =>
                          setState(() => _showRefunded = val ?? true),
                    ),
                    const Text("Show Refunded"),
                  ],
                ),
              ),
              Expanded(
                child: ListView.builder(
                  itemCount: orders.length,
                  itemBuilder: (ctx, i) {
                    final order = orders[i];
                    return Card(
                      elevation: 2,
                      margin: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: order.status == 'Refunded'
                              ? Colors.redAccent
                              : DesignTokens.adminPrimaryColor,
                          child: Text(order.userNameDisplay.isNotEmpty
                              ? order.userNameDisplay[0].toUpperCase()
                              : '#'),
                        ),
                        title: Text(
                          "${order.id} — ${order.userNameDisplay}",
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                                "Status: ${order.status} | \$${order.total.toStringAsFixed(2)}"),
                            Text("Placed: ${order.timestamp}"),
                            if (order.refundStatus != null)
                              Text("Refund: ${order.refundStatus}"),
                          ],
                        ),
                        trailing: PopupMenuButton<String>(
                          onSelected: (value) {
                            if (value == 'status') {
                              _showStatusDialog(order, user);
                            } else if (value == 'refund') {
                              _showRefundDialog(order, user);
                            }
                          },
                          itemBuilder: (context) {
                            final items = <PopupMenuEntry<String>>[];
                            if (user.isOwner || user.isManager) {
                              items.add(const PopupMenuItem<String>(
                                value: 'status',
                                child: Text("Update Status"),
                              ));
                              if (order.status != 'Refunded') {
                                items.add(const PopupMenuItem<String>(
                                  value: 'refund',
                                  child: Text("Process Refund"),
                                ));
                              }
                            }
                            return items;
                          },
                        ),
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (_) => OrderDetailDialog(order: order),
                          );
                        },
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class OrderDetailDialog extends StatelessWidget {
  final order_model.Order order;
  const OrderDetailDialog({required this.order, super.key});

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text("Order #${order.id}"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Customer: ${order.userNameDisplay}"),
            const SizedBox(height: 8),
            Text("Items:"),
            ...order.items.map((item) => Text(
                  "- ${item.name} x${item.quantity} (\$${(item.price * item.quantity).toStringAsFixed(2)})",
                  style: const TextStyle(fontSize: 15),
                )),
            const SizedBox(height: 8),
            Text("Total: \$${order.total.toStringAsFixed(2)}"),
            Text("Status: ${order.status}"),
            Text("Placed: ${order.timestamp}"),
            if (order.refundStatus != null)
              Text("Refund: ${order.refundStatus}"),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text("Close"),
        )
      ],
    );
  }
}
