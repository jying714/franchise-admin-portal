import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/src/core/models/order.dart'
    as order_model;
import 'package:shared_core/src/core/services/firestore_service.dart';
import 'package:shared_core/src/core/models/user.dart'
    as admin_user;
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:shared_core/src/core/services/audit_log_service.dart';
import 'package:shared_core/src/core/providers/franchise_provider.dart';
import 'package:shared_core/src/core/providers/user_profile_notifier.dart';
import 'package:shared_core/src/core/providers/role_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import 'package:shared_core/src/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/widgets/orders/order_detail_dialog.dart';

class OrderManagementScreen extends StatelessWidget {
  const OrderManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const RoleGuard(
      allowedRoles: [
        'platform_owner',
        'hq_owner',
        'manager',
        'developer',
        'admin',
      ],
      featureName: 'OrderManagementScreen',
      child: _OrderManagementScreenContent(),
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
    await context
        .read<FirestoreService>()
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
    await context
        .read<FirestoreService>()
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
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    final controller =
        TextEditingController(text: order.total.toStringAsFixed(2));
    final colorScheme = Theme.of(context).colorScheme;
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
            child: Text("Cancel", style: TextStyle(color: colorScheme.outline)),
          ),
          ElevatedButton(
            onPressed: () {
              final amount = double.tryParse(controller.text) ?? 0.0;
              if (amount > 0 && amount <= order.total) {
                Navigator.of(context).pop();
                _processRefund(franchiseId, order, amount, user);
              }
            },
            style:
                ElevatedButton.styleFrom(backgroundColor: colorScheme.primary),
            child: const Text("Refund"),
          ),
        ],
      ),
    );
  }

  void _showStatusDialog(order_model.Order order, admin_user.User user) {
    final franchiseId = context.read<FranchiseProvider>().franchiseId;
    const allowedStatuses = [
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

  List<order_model.Order> _filterOrders(List<order_model.Order> orders) {
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
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
          content: Text('Exported orders (CSV download logic goes here).')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final user = context.watch<AdminUserProvider>().user;
    final loading = context.watch<AdminUserProvider>().loading;
    final firestoreService = context.read<FirestoreService>();
    final colorScheme = Theme.of(context).colorScheme;

    if (user == null) {
      return Scaffold(
        body: Center(
          child: loading
              ? const CircularProgressIndicator()
              : const Text('Unauthorized â€” No admin user'),
        ),
      );
    }

    return RoleGuard(
      allowedRoles: ['hq_owner', 'manager', 'developer'],
      child: SubscriptionAccessGuard(
        child: Scaffold(
          backgroundColor: colorScheme.background,
          body: Column(
            children: [
              const GracePeriodBanner(),
              Expanded(
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text("Order Management",
                              style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                  color: colorScheme.onBackground)),
                          const Spacer(),
                          IconButton(
                            icon: Icon(Icons.download,
                                color: colorScheme.primary),
                            tooltip: "Export Orders",
                            onPressed: () => _showExportDialog(
                                franchiseId, _lastOrders, user),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              decoration: InputDecoration(
                                labelText: "Search by Order ID or Name",
                                prefixIcon: const Icon(Icons.search),
                                border: const OutlineInputBorder(),
                              ),
                              onChanged: (val) =>
                                  setState(() => _searchText = val.trim()),
                            ),
                          ),
                          const SizedBox(width: 12),
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
                                .map((s) => DropdownMenuItem(
                                    value: s, child: Text(s ?? "All")))
                                .toList(),
                            onChanged: (val) =>
                                setState(() => _filterStatus = val),
                          ),
                          const SizedBox(width: 12),
                          IconButton(
                            icon: const Icon(Icons.calendar_today),
                            onPressed: () async {
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 1)),
                              );
                              if (range != null)
                                setState(() => _dateRange = range);
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
                      const SizedBox(height: 16),
                      Expanded(
                        child: StreamBuilder<List<order_model.Order>>(
                          stream:
                              firestoreService.getAllOrdersStream(franchiseId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LoadingShimmerWidget();
                            }
                            final orders = snapshot.data ?? [];
                            final filtered = _filterOrders(orders);
                            _lastOrders = filtered;

                            if (filtered.isEmpty) {
                              return const EmptyStateWidget(
                                title: "No Orders",
                                message: "No orders found.",
                                iconData: Icons.receipt_long,
                              );
                            }

                            return ListView.builder(
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) {
                                final order = filtered[i];
                                return Card(
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 6),
                                  child: ListTile(
                                    leading: CircleAvatar(
                                      backgroundColor:
                                          order.status == 'Refunded'
                                              ? Colors.redAccent
                                              : DesignTokens.adminPrimaryColor,
                                      child: Text(
                                          order.userNameDisplay.isNotEmpty
                                              ? order.userNameDisplay[0]
                                                  .toUpperCase()
                                              : '#'),
                                    ),
                                    title: Text(
                                        "${order.id} â€” ${order.userNameDisplay}",
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
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
                                        final items =
                                            <PopupMenuEntry<String>>[];
                                        if (user.isOwner || user.isManager) {
                                          items.add(const PopupMenuItem(
                                              value: 'status',
                                              child: Text("Update Status")));
                                          if (order.status != 'Refunded') {
                                            items.add(const PopupMenuItem(
                                                value: 'refund',
                                                child: Text("Process Refund")));
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
            ],
          ),
        ),
      ),
    );
  }
}


