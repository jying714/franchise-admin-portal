import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/orders/order_detail_dialog.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';

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
  List<shared.Order> _lastOrders = [];

  Future<void> _updateOrderStatus(String franchiseId, shared.Order order,
      String newStatus, shared.User user) async {
    await Provider.of<shared.FirestoreService>(context, listen: false)
        .updateOrderStatus(franchiseId, order.id, newStatus);
    await Provider.of<shared.AuditLogService>(context, listen: false).addLog(
      franchiseId: franchiseId,
      userId: user.id,
      action: 'update_order_status',
      targetType: 'order',
      targetId: order.id,
      details: {'newStatus': newStatus},
    );
  }

  Future<void> _processRefund(String franchiseId, shared.Order order,
      double amount, shared.User user) async {
    try {
      await Provider.of<shared.FirestoreService>(context, listen: false)
          .refundOrder(franchiseId, order.id, amount: amount);
      await Provider.of<shared.AuditLogService>(context, listen: false).addLog(
        franchiseId: franchiseId,
        userId: user.id,
        action: 'refund_order',
        targetType: 'order',
        targetId: order.id,
        details: {'refundAmount': amount},
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Refund processed')),
      );
    } catch (e, stack) {
      shared.ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'OrderManagementScreen._processRefund',
        contextData: {
          'franchiseId': franchiseId,
          'orderId': order.id,
          'amount': amount,
        },
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Refund failed: $e')),
      );
      rethrow;
    }
  }

  void _showRefundDialog(shared.Order order, shared.User user) {
    final parentContext = context;
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(parentContext, listen: false)
            .franchiseId;
    final controller =
        TextEditingController(text: order.total.toStringAsFixed(2));
    final colorScheme = Theme.of(parentContext).colorScheme;

    showDialog<void>(
      context: parentContext,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Process Refund'),
          content: TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(labelText: 'Refund Amount'),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child:
                  Text('Cancel', style: TextStyle(color: colorScheme.outline)),
            ),
            ElevatedButton(
              onPressed: () async {
                final raw = controller.text
                    .trim()
                    .replaceAll(r'$', '')
                    .replaceAll(',', '');
                final amount = double.tryParse(raw) ?? 0.0;
                final max = order.total;

                if (amount <= 0) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    const SnackBar(
                        content: Text('Enter a refund amount greater than 0')),
                  );
                  return;
                }
                // Allow full refund even with tiny float noise; still block nonsense totals.
                if (max > 0 && amount > max + 0.01) {
                  ScaffoldMessenger.of(parentContext).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Amount cannot exceed ${max.toStringAsFixed(2)}',
                      ),
                    ),
                  );
                  return;
                }

                // Close dialog first so messenger/parent context stay valid.
                Navigator.of(dialogContext).pop();

                try {
                  await _processRefund(franchiseId, order, amount, user);
                } catch (_) {
                  // Snackbar handled inside _processRefund
                }
              },
              style: ElevatedButton.styleFrom(
                  backgroundColor: colorScheme.primary),
              child: const Text('Refund'),
            ),
          ],
        );
      },
    );
  }

  void _showStatusDialog(shared.Order order, shared.User user) {
    final franchiseId =
        Provider.of<shared.FranchiseProvider>(context, listen: false)
            .franchiseId;
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

  bool _isRefundedOrder(shared.Order o) {
    final status = o.status.trim().toLowerCase();
    final refund = (o.refundStatus ?? '').trim().toLowerCase();
    return status == 'refunded' ||
        refund == 'refunded' ||
        refund == 'completed' ||
        refund == 'full';
  }

  List<shared.Order> _filterOrders(List<shared.Order> orders) {
    return orders.where((o) {
      if (!_showRefunded && _isRefundedOrder(o)) return false;
      if (_filterStatus != null) {
        if (_filterStatus == 'Refunded') {
          if (!_isRefundedOrder(o)) return false;
        } else if (o.status != _filterStatus) {
          return false;
        }
      }
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

  void _showExportDialog(
      String franchiseId, List<shared.Order> orders, shared.User user) async {
    await Provider.of<shared.AuditLogService>(context, listen: false).addLog(
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
    final franchiseId = context.watch<shared.FranchiseProvider>().franchiseId;
    final user =
        Provider.of<shared.AdminUserProvider>(context, listen: false).user;
    final loading =
        Provider.of<shared.AdminUserProvider>(context, listen: false).loading;
    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);
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
                            icon: Icon(
                              _dateRange == null
                                  ? Icons.calendar_today
                                  : Icons.event_busy,
                            ),
                            tooltip: _dateRange == null
                                ? 'Filter by date'
                                : 'Clear date filter',
                            onPressed: () async {
                              if (_dateRange != null) {
                                setState(() => _dateRange = null);
                                return;
                              }
                              final range = await showDateRangePicker(
                                context: context,
                                firstDate: DateTime.now()
                                    .subtract(const Duration(days: 365)),
                                lastDate:
                                    DateTime.now().add(const Duration(days: 1)),
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
                      const SizedBox(height: 16),
                      Expanded(
                        child: StreamBuilder<List<shared.Order>>(
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
                                        final canManageOrders = user.isOwner ||
                                            user.isManager ||
                                            user.isAdmin ||
                                            user.isHqOwner ||
                                            user.isPlatformOwner ||
                                            user.isDeveloper;
                                        if (canManageOrders) {
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
