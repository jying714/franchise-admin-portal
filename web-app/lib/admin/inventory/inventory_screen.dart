import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _search = '';

  void _onSearchChanged(String val) => setState(() => _search = val);

  bool _canEdit(BuildContext context) {
    final user =
        Provider.of<shared.AdminUserProvider>(context, listen: false).user;
    if (user == null) return false;
    final roles = user.roles;
    return roles.contains('owner') ||
        roles.contains('manager') ||
        roles.contains('developer') ||
        roles.contains('hq_owner') ||
        roles.contains('admin') ||
        roles.contains('platform_owner');
  }

  Stream<List<shared.MenuItem>> _trackedMenuStream(String franchiseId) {
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('menu_items')
        .snapshots()
        .map((snap) {
      final items = snap.docs
          .map((d) => shared.MenuItem.fromFirestore(d.data(), d.id))
          .where((m) => m.inventoryTracked)
          .toList();
      items
          .sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      return items;
    });
  }

  Future<void> _adjustStock(
    String franchiseId,
    shared.MenuItem item,
  ) async {
    final controller = TextEditingController(
      text: '${item.stockCount ?? 0}',
    );
    final loc = AppLocalizations.of(context);
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          title: Text('Adjust stock · ${item.name}'),
          content: TextField(
            controller: controller,
            autofocus: true,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: 'Stock count',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: Text(loc?.cancel ?? 'Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                final parsed = int.tryParse(controller.text.trim());
                if (parsed == null || parsed < 0) return;
                Navigator.pop(ctx, parsed);
              },
              child: Text(loc?.save ?? 'Save'),
            ),
          ],
        );
      },
    );
    if (result == null || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('menu_items')
          .doc(item.id)
          .set(
        {
          'stockCount': result,
          'inventoryTracked': true,
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name}: stock set to $result')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to update stock: $e')),
      );
    }
  }

  Future<void> _stopTracking(
    String franchiseId,
    shared.MenuItem item,
  ) async {
    final loc = AppLocalizations.of(context);
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Stop tracking inventory?'),
        content: Text(
          '${item.name} will leave this list. The menu item is not deleted.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(loc?.cancel ?? 'Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Stop tracking'),
          ),
        ],
      ),
    );
    if (confirm != true || !mounted) return;

    try {
      await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('menu_items')
          .doc(item.id)
          .set(
        {
          'inventoryTracked': false,
        },
        SetOptions(merge: true),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${item.name}: inventory tracking off')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to stop tracking: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final franchiseId = franchiseProvider.franchiseId;

    if (franchiseId == null ||
        franchiseId.isEmpty ||
        franchiseId == 'unknown') {
      return const Scaffold(
        body: Center(
          child: Text(
            'Select a franchise to manage inventory.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final canEdit = _canEdit(context);

    if (loc == null) {
      return const Scaffold(
        body: Center(child: Text('Localization missing!')),
      );
    }

    return RoleGuard(
      allowedRoles: const [
        'platform_owner',
        'hq_owner',
        'manager',
        'developer',
        'admin',
      ],
      featureName: 'inventory_screen',
      child: SubscriptionAccessGuard(
        child: Scaffold(
          backgroundColor: colorScheme.background,
          body: Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const GracePeriodBanner(),
                Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Text(
                    loc.inventory,
                    style: TextStyle(
                      color: colorScheme.onBackground,
                      fontWeight: FontWeight.bold,
                      fontSize: 22,
                    ),
                  ),
                ),
                Text(
                  'Tracked menu items · live stockCount (POS / web / mobile 86)',
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 8),
                TextField(
                  decoration: InputDecoration(
                    hintText: loc.inventorySearchHint,
                    prefixIcon: const Icon(Icons.search),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    isDense: true,
                  ),
                  onChanged: _onSearchChanged,
                ),
                const SizedBox(height: 8),
                Expanded(
                  child: StreamBuilder<List<shared.MenuItem>>(
                    stream: _trackedMenuStream(franchiseId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const LoadingShimmerWidget();
                      }
                      if (snapshot.hasError) {
                        return EmptyStateWidget(
                          title: loc.errorLoadingInventory,
                          message: snapshot.error.toString(),
                          onRetry: () => setState(() {}),
                        );
                      }

                      var items = snapshot.data ?? const <shared.MenuItem>[];
                      if (_search.isNotEmpty) {
                        final q = _search.toLowerCase();
                        items = items
                            .where((m) => m.name.toLowerCase().contains(q))
                            .toList();
                      }

                      if (items.isEmpty) {
                        return EmptyStateWidget(
                          title: loc.noInventory,
                          message:
                              'No menu items have inventory tracking enabled. Turn it on in Menu Item Editor, then set a stock count.',
                        );
                      }

                      return ListView.separated(
                        padding: const EdgeInsets.all(8),
                        separatorBuilder: (_, __) => const Divider(height: 1),
                        itemCount: items.length,
                        itemBuilder: (context, idx) {
                          final item = items[idx];
                          final stock = item.stockCount ?? 0;
                          final is86 = stock <= 0;
                          return Card(
                            elevation: 2,
                            margin: const EdgeInsets.symmetric(vertical: 4),
                            child: ListTile(
                              leading: Icon(
                                is86 ? Icons.cancel : Icons.check_circle,
                                color: is86
                                    ? colorScheme.error
                                    : colorScheme.primary,
                              ),
                              title: Text(
                                item.name,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              subtitle: Text(
                                is86
                                    ? 'Stock: $stock · 86 (not sellable)'
                                    : 'Stock: $stock',
                              ),
                              trailing: canEdit
                                  ? Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(
                                          icon: Icon(
                                            Icons.edit,
                                            color: colorScheme.secondary,
                                          ),
                                          tooltip: 'Adjust stock',
                                          onPressed: () => _adjustStock(
                                            franchiseId,
                                            item,
                                          ),
                                        ),
                                        IconButton(
                                          icon: Icon(
                                            Icons.link_off,
                                            color: colorScheme.error,
                                          ),
                                          tooltip: 'Stop tracking',
                                          onPressed: () => _stopTracking(
                                            franchiseId,
                                            item,
                                          ),
                                        ),
                                      ],
                                    )
                                  : null,
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
      ),
    );
  }
}
