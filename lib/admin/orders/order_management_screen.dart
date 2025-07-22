import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/models/order.dart' as order_model;
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/user.dart' as admin_user;
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/core/services/audit_log_service.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/widgets/role_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return RoleGuard(
      allowedRoles: [
        'platform_owner',
        'hq_owner',
        'manager',
        'developer',
        'admin'
      ],
      featureName: 'OrderManagementScreen',
      child: const _OrderManagementScreenContent(),
    );
  }
}

class _OrderManagementScreenContent extends StatefulWidget {
  const _OrderManagementScreenContent();

  @override
  State<_OrderManagementScreenContent> createState() =>
      _OrderManagementScreenContentState();
}

class _OrderManagementScreenContentState
    extends State<_OrderManagementScreenContent> {
  String _searchText = '';
  String? _filterStatus;
  DateTimeRange? _dateRange;
  bool _showRefunded = true;
  List<order_model.Order> _lastOrders = [];

  Future<void> _updateOrderStatus(String franchiseId, order_model.Order order,
      String newStatus, admin_user.User user) async {
    await Provider.of<FirestoreService>(context, listen: false)
        .updateOrderStatus(franchiseId, order.id, newStatus);
    await AuditLogService().addLog(
      franchiseId: franchiseId,
      userId: user.id,
      action: 'update_order_status',
      targetType: 'order',
      targetId: order.id,
      details: {'newStatus': newStatus},
    );
  }

  Future<void> _processRefund(String franchiseId, order_model.Order order,
      double amount, admin_user.User user) async {
    await Provider.of<FirestoreService>(context, listen: false)
        .refundOrder(franchiseId, order.id, amount: amount);
    await AuditLogService().addLog(
      franchiseId: franchiseId,
      userId: user.id,
      action: 'refund_order',
      targetType: 'order',
      targetId: order.id,
      details: {'refundAmount': amount},
    );
  }

  void _showRefundDialog(order_model.Order order, admin_user.User user) {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
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
                _processRefund(franchiseId, order, amount, user);
              }
            },
            child: const Text("Refund"),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(order_model.Order order, admin_user.User user) {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
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
                  _updateOrderStatus(franchiseId, order, selected, user);
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
            o.timestamp.isAfter(_dateRange!.end)) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void _showExportDialog(String franchiseId, List<order_model.Order> orders,
      admin_user.User user) async {
    await AuditLogService().addLog(
      franchiseId: franchiseId,
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
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final userNotifier = Provider.of<UserProfileNotifier>(context);
    final user = userNotifier.user;
    final loading = userNotifier.loading;
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context);

    if (loading || user == null) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return RoleGuard(
      allowedRoles: ['hq_owner', 'manager', 'developer'],
      child: SubscriptionAccessGuard(
        child: Scaffold(
          backgroundColor: Colors.white,
          body: Column(
            children: [
              const GracePeriodBanner(),
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      flex: 11,
                      child: Padding(
                        padding: const EdgeInsets.only(
                            top: 24.0, left: 24.0, right: 24.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Row(
                                children: [
                                  const Text(
                                    "Order Management",
                                    style: TextStyle(
                                        fontSize: 22,
                                        fontWeight: FontWeight.bold),
                                  ),
                                  const Spacer(),
                                  IconButton(
                                    icon: const Icon(Icons.download),
                                    tooltip: "Export Orders",
                                    onPressed: () async {
                                      try {
                                        _showExportDialog(
                                            franchiseId, _lastOrders, user);
                                      } catch (e, stack) {
                                        await ErrorLogger.log(
                                          message: 'Export failed: $e',
                                          stack: stack.toString(),
                                          screen:
                                              'order_management_screen.dart',
                                          source: 'export',
                                          contextData: {
                                            'franchiseId': franchiseId
                                          },
                                        );
                                      }
                                    },
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              children: [
                                Expanded(
                                  child: TextField(
                                    decoration: const InputDecoration(
                                      labelText: "Search by Order ID or Name",
                                      prefixIcon: Icon(Icons.search),
                                    ),
                                    onChanged: (val) => setState(
                                        () => _searchText = val.trim()),
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
                                      .map((s) => DropdownMenuItem<String>(
                                            value: s,
                                            child: Text(s ?? "All"),
                                          ))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _filterStatus = val),
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
                                      lastDate: DateTime.now()
                                          .add(const Duration(days: 1)),
                                    );
                                    if (range != null) {
                                      setState(() => _dateRange = range);
                                    }
                                  },
                                ),
                                Checkbox(
                                  value: _showRefunded,
                                  onChanged: (val) => setState(
                                      () => _showRefunded = val ?? true),
                                ),
                                const Text("Show Refunded"),
                              ],
                            ),
                            Expanded(
                              child: StreamBuilder<List<order_model.Order>>(
                                stream: firestoreService
                                    .getAllOrdersStream(franchiseId),
                                builder: (context, snapshot) {
                                  if (snapshot.connectionState ==
                                      ConnectionState.waiting) {
                                    return const LoadingShimmerWidget();
                                  }
                                  if (!snapshot.hasData ||
                                      snapshot.data!.isEmpty) {
                                    return const EmptyStateWidget(
                                      title: "No Orders",
                                      message: "No orders found.",
                                      iconData: Icons.receipt_long,
                                    );
                                  }
                                  final orders =
                                      _filterOrders(snapshot.data!, user);
                                  _lastOrders = orders;
                                  return ListView.builder(
                                    itemCount: orders.length,
                                    itemBuilder: (ctx, i) {
                                      final order = orders[i];
                                      return Card(
                                        elevation: 2,
                                        margin: const EdgeInsets.symmetric(
                                            horizontal: 10, vertical: 6),
                                        child: ListTile(
                                          leading: CircleAvatar(
                                            backgroundColor:
                                                order.status == 'Refunded'
                                                    ? Colors.redAccent
                                                    : DesignTokens
                                                        .adminPrimaryColor,
                                            child: Text(
                                              order.userNameDisplay.isNotEmpty
                                                  ? order.userNameDisplay[0]
                                                      .toUpperCase()
                                                  : '#',
                                            ),
                                          ),
                                          title: Text(
                                            "${order.id} — ${order.userNameDisplay}",
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold),
                                          ),
                                          subtitle: Column(
                                            crossAxisAlignment:
                                                CrossAxisAlignment.start,
                                            children: [
                                              Text(
                                                  "Status: ${order.status} | \$${order.total.toStringAsFixed(2)}"),
                                              Text(
                                                  "Placed: ${order.timestamp}"),
                                              if (order.refundStatus != null)
                                                Text(
                                                    "Refund: ${order.refundStatus}"),
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
                                              final items =
                                                  <PopupMenuEntry<String>>[];
                                              if (user.isOwner ||
                                                  user.isManager) {
                                                items.add(
                                                    const PopupMenuItem<String>(
                                                  value: 'status',
                                                  child: Text("Update Status"),
                                                ));
                                                if (order.status !=
                                                    'Refunded') {
                                                  items.add(const PopupMenuItem<
                                                      String>(
                                                    value: 'refund',
                                                    child:
                                                        Text("Process Refund"),
                                                  ));
                                                }
                                              }
                                              return items;
                                            },
                                          ),
                                          onTap: () => showDialog(
                                            context: context,
                                            builder: (_) =>
                                                OrderDetailDialog(order: order),
                                          ),
                                        ),
                                      );
                                    },
                                  );
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    Expanded(flex: 9, child: Container()),
                  ],
                ),
              ),
            ],
          ),
        ),
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
            const Text("Items:"),
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
