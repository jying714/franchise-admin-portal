import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'package:franchise_admin_portal/widgets/empty_state_widget.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/subscription_access_guard.dart';
import 'package:franchise_admin_portal/widgets/subscription/grace_period_banner.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';
import 'package:franchise_admin_portal/core/services/admin_firestore_service.dart';

class InventoryScreen extends StatefulWidget {
  const InventoryScreen({super.key});

  @override
  State<InventoryScreen> createState() => _InventoryScreenState();
}

class _InventoryScreenState extends State<InventoryScreen> {
  String _search = '';
  shared.Inventory? _lastDeleted;

  void _onSearchChanged(String val) => setState(() => _search = val);

  bool _canEdit(BuildContext context) {
    final user = Provider.of<shared.User?>(context, listen: false);
    if (user == null) return false;
    return user.roles.contains('owner') ||
        user.roles.contains('manager') ||
        user.roles.contains('developer') ||
        user.roles.contains('hq_owner') ||
        user.roles.contains('admin') ||
        user.roles.contains('platform_owner');
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
            'Inventory management is available in full Admin mode only.\n\n(Admin-only feature)',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    // Prefer AdminFirestoreService if available
    final adminService =
        Provider.of<shared.FirestoreService?>(context, listen: false)
            as dynamic;
    final firestore = (adminService is AdminFirestoreService)
        ? adminService as AdminFirestoreService
        : Provider.of<shared.FirestoreService>(context, listen: false);

    final loc = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    if (loc == null) {
      return const Scaffold(body: Center(child: Text('Localization missing!')));
    }

    final canEdit = _canEdit(context);

    return RoleGuard(
      allowedRoles: const [
        'platform_owner',
        'hq_owner',
        'manager',
        'developer',
        'admin'
      ],
      featureName: 'inventory_screen',
      child: SubscriptionAccessGuard(
        child: Scaffold(
          backgroundColor: colorScheme.background,
          body: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 11,
                child: Padding(
                  padding:
                      const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const GracePeriodBanner(),
                      Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Row(
                          children: [
                            Text(
                              loc.inventory,
                              style: TextStyle(
                                color: colorScheme.onBackground,
                                fontWeight: FontWeight.bold,
                                fontSize: 22,
                              ),
                            ),
                            const Spacer(),
                            if (canEdit)
                              IconButton(
                                icon: Icon(Icons.add,
                                    color: colorScheme.onBackground),
                                tooltip: loc.addInventory,
                                onPressed: () =>
                                    _addOrEditInventory(franchiseId, context),
                              ),
                          ],
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: loc.inventorySearchHint,
                            prefixIcon: const Icon(Icons.search),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12)),
                            isDense: true,
                          ),
                          onChanged: _onSearchChanged,
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder<List<shared.Inventory>>(
                          stream: firestore.getInventory(franchiseId),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return const LoadingShimmerWidget();
                            }

                            if (snapshot.hasError) {
                              final error = snapshot.error.toString();
                              if (error.contains('UnimplementedError') ||
                                  error.contains('Admin-only method')) {
                                return const Center(
                                  child: Padding(
                                    padding: EdgeInsets.all(32.0),
                                    child: Text(
                                      'Inventory management is available in full Admin mode only.\n\n(Feature in progress for P3)',
                                      textAlign: TextAlign.center,
                                      style: TextStyle(fontSize: 18),
                                    ),
                                  ),
                                );
                              }
                              return EmptyStateWidget(
                                title: loc.errorLoadingInventory,
                                message: error,
                                onRetry: () => setState(() {}),
                              );
                            }

                            var items = snapshot.data ?? [];
                            if (_search.isNotEmpty) {
                              items = items
                                  .where((inv) =>
                                      inv.name
                                          .toLowerCase()
                                          .contains(_search.toLowerCase()) ||
                                      (inv.sku?.toLowerCase().contains(
                                              _search.toLowerCase()) ??
                                          false))
                                  .toList();
                            }

                            if (items.isEmpty) {
                              return EmptyStateWidget(
                                title: loc.noInventory,
                                message: loc.noInventoryMsg,
                              );
                            }

                            return ListView.separated(
                              padding: const EdgeInsets.all(8),
                              separatorBuilder: (_, __) =>
                                  const Divider(height: 1),
                              itemCount: items.length,
                              itemBuilder: (context, idx) {
                                final item = items[idx];
                                return Card(
                                  elevation: 2,
                                  margin:
                                      const EdgeInsets.symmetric(vertical: 4),
                                  child: ListTile(
                                    leading: Icon(
                                      item.available
                                          ? Icons.check_circle
                                          : Icons.cancel,
                                      color: item.available
                                          ? colorScheme.primary
                                          : colorScheme.error,
                                    ),
                                    title: Text(item.name,
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Text(
                                      '${loc.sku}: ${item.sku ?? "—"}\n'
                                      '${loc.stock}: ${item.stock}\n'
                                      '${loc.threshold}: ${item.threshold}\n'
                                      '${loc.unitType}: ${item.unitType ?? "—"}',
                                    ),
                                    trailing: canEdit
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              IconButton(
                                                icon: Icon(Icons.edit,
                                                    color:
                                                        colorScheme.secondary),
                                                onPressed: () =>
                                                    _addOrEditInventory(
                                                        franchiseId, context,
                                                        item: item),
                                              ),
                                              IconButton(
                                                icon: Icon(Icons.delete,
                                                    color: colorScheme.error),
                                                onPressed: () =>
                                                    _deleteInventory(
                                                        franchiseId,
                                                        context,
                                                        item),
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
              Expanded(flex: 9, child: Container()),
            ],
          ),
          floatingActionButton: canEdit
              ? FloatingActionButton.extended(
                  heroTag: 'inventory_fab',
                  icon: const Icon(Icons.add),
                  label: Text(loc.addInventory),
                  backgroundColor: BrandingConfig.brandRed,
                  onPressed: () => _addOrEditInventory(franchiseId, context),
                )
              : null,
        ),
      ),
    );
  }

  Future<void> _addOrEditInventory(String franchiseId, BuildContext context,
      {shared.Inventory? item}) async {
    final firestore =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      // Optionally, show a SnackBar or dialog here
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Localization missing! [debug]'))
      // );
      return;
    }
    final nameController = TextEditingController(text: item?.name ?? '');
    final skuController = TextEditingController(text: item?.sku ?? '');
    final stockController =
        TextEditingController(text: item?.stock.toString() ?? '0');
    final thresholdController =
        TextEditingController(text: item?.threshold.toString() ?? '0');
    final unitTypeController =
        TextEditingController(text: item?.unitType ?? '');
    bool available = item?.available ?? true;

    final result = await showDialog<bool>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: Text(item == null ? (loc.addInventory) : (loc.editInventory)),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameController,
                  decoration: InputDecoration(labelText: loc.name),
                  autofocus: true,
                ),
                TextField(
                  controller: skuController,
                  decoration: InputDecoration(labelText: loc.sku),
                ),
                TextField(
                  controller: stockController,
                  decoration: InputDecoration(labelText: loc.stock),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: thresholdController,
                  decoration: InputDecoration(labelText: loc.threshold),
                  keyboardType: TextInputType.number,
                ),
                TextField(
                  controller: unitTypeController,
                  decoration: InputDecoration(labelText: loc.unitType),
                ),
                SwitchListTile(
                  value: available,
                  onChanged: (val) => setDialogState(() => available = val),
                  title: Text(loc.available),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: Text(loc.cancel),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: Text(item == null ? loc.add : loc.save),
            ),
          ],
        ),
      ),
    );

    if (result == true) {
      final inventory = shared.Inventory(
        id: item?.id ?? '',
        name: nameController.text.trim(),
        sku: skuController.text.trim(),
        stock: double.tryParse(stockController.text.trim()) ?? 0.0,
        threshold: double.tryParse(thresholdController.text.trim()) ?? 0.0,
        unitType: unitTypeController.text.trim(),
        available: available,
        lastUpdated: DateTime.now(),
      );
      if (item == null) {
        await firestore.addInventory(franchiseId, inventory.copyWith(id: ''));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.inventoryAdded)),
        );
      } else {
        await firestore.updateInventory(
            franchiseId, inventory.copyWith(id: item.id));
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(loc.inventoryUpdated)),
        );
      }
    }
  }

  Future<void> _deleteInventory(
      String franchiseId, BuildContext context, shared.Inventory item) async {
    final firestore =
        Provider.of<shared.FirestoreService>(context, listen: false);
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[YourWidget] loc is null! Localization not available for this context.');
      // ScaffoldMessenger.of(context).showSnackBar(
      //   SnackBar(content: Text('Localization missing! [debug]'))
      // );
      return;
    }
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: Theme.of(context).colorScheme.surface,
        title: Text(
          loc.deleteInventoryTitle,
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        content: Text(
          loc.deleteInventoryPrompt(item.name),
          style: TextStyle(color: Theme.of(context).colorScheme.onSurface),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(
              loc.cancel,
              style: TextStyle(color: Theme.of(context).colorScheme.primary),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.error,
              foregroundColor: Theme.of(context).colorScheme.onError,
            ),
            child: Text(loc.delete),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await firestore.deleteInventory(franchiseId, item.id);
      if (!mounted) return;
      setState(() => _lastDeleted = item);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(loc.inventoryDeleted),
          action: SnackBarAction(
            label: loc.undo,
            onPressed: () async {
              if (_lastDeleted != null) {
                await firestore.addInventory(
                    franchiseId, _lastDeleted!.copyWith(id: ''));
                if (!mounted) return;
                setState(() => _lastDeleted = null);
              }
            },
          ),
        ),
      );
    }
  }
}
