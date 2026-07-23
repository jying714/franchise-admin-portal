import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:franchise_mobile_app/generated/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/widgets/header/franchise_app_bar.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';

class ScheduledOrdersScreen extends StatefulWidget {
  const ScheduledOrdersScreen({super.key});

  @override
  State<ScheduledOrdersScreen> createState() => _ScheduledOrdersScreenState();
}

class _ScheduledOrdersScreenState extends State<ScheduledOrdersScreen> {
  String? _userId;

  @override
  void initState() {
    super.initState();
    _userId = fb_auth.FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _showOrderEditorDialog({
    shared.ScheduledOrder? scheduledOrder,
    required shared.FirestoreService firestoreService,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final isEditing = scheduledOrder != null;

    final TextEditingController freqController = TextEditingController(
      text: scheduledOrder?.frequency ?? 'weekly',
    );

    DateTime nextRun =
        scheduledOrder?.nextDate ?? DateTime.now().add(const Duration(days: 7));
    bool isPaused = scheduledOrder?.isPaused ?? false;

    final franchiseProvider =
        Provider.of<shared.FranchiseProvider>(context, listen: false);
    final menuItems = await firestoreService
        .getMenuItems(franchiseProvider.currentFranchiseId)
        .first;

    // Convert MenuItem list to OrderItem list
    List<shared.OrderItem> selectedOrderItems = scheduledOrder?.items ?? [];
    List<shared.MenuItem> selectedMenuItems = menuItems
        .where((m) => selectedOrderItems.any((oi) => oi.menuItemId == m.id))
        .toList();

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(builder: (context, setModalState) {
          return AlertDialog(
            title: Text(
              isEditing
                  ? localizations.editScheduledOrder
                  : localizations.newScheduledOrder,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<String>(
                    value: freqController.text,
                    items: [
                      DropdownMenuItem(
                          value: 'daily',
                          child: Text(localizations.frequencyDaily)),
                      DropdownMenuItem(
                          value: 'weekly',
                          child: Text(localizations.frequencyWeekly)),
                      DropdownMenuItem(
                          value: 'monthly',
                          child: Text(localizations.frequencyMonthly)),
                    ],
                    onChanged: (value) {
                      setModalState(
                          () => freqController.text = value ?? 'weekly');
                    },
                    decoration:
                        InputDecoration(labelText: localizations.frequency),
                  ),
                  ListTile(
                    title: Text(localizations.nextRunDate),
                    subtitle: Text(nextRun.toString().substring(0, 16)),
                    trailing: IconButton(
                      icon: const Icon(Icons.calendar_today),
                      onPressed: () async {
                        final picked = await showDatePicker(
                          context: context,
                          initialDate: nextRun,
                          firstDate: DateTime.now(),
                          lastDate:
                              DateTime.now().add(const Duration(days: 365)),
                        );
                        if (picked != null && mounted) {
                          setModalState(() => nextRun = picked);
                        }
                      },
                    ),
                  ),
                  SwitchListTile(
                    value: isPaused,
                    onChanged: (v) => setModalState(() => isPaused = v),
                    title: Text(localizations.pauseSchedule),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(localizations.selectItems),
                  ),
                  Wrap(
                    spacing: 6,
                    children: menuItems
                        .map((item) => FilterChip(
                              label: Text(item.name),
                              selected:
                                  selectedMenuItems.any((i) => i.id == item.id),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedMenuItems.add(item);
                                  } else {
                                    selectedMenuItems
                                        .removeWhere((i) => i.id == item.id);
                                  }
                                });
                              },
                            ))
                        .toList(),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                child: Text(localizations.cancel),
                onPressed: () => Navigator.of(context).pop(),
              ),
              ElevatedButton(
                child: Text(
                    isEditing ? localizations.update : localizations.create),
                onPressed: () async {
                  if (_userId == null || selectedMenuItems.isEmpty || !mounted)
                    return;

                  final franchiseProvider =
                      Provider.of<shared.FranchiseProvider>(context,
                          listen: false);
                  final now = DateTime.now();

                  // Convert MenuItems to OrderItems
                  final List<shared.OrderItem> orderItems = selectedMenuItems
                      .map((m) => shared.OrderItem(
                            menuItemId: m.id,
                            name: m.name,
                            price: m.price ?? 0.0,
                            quantity: 1,
                            customizations: {},
                            image: m.image,
                          ))
                      .toList();

                  final shared.ScheduledOrder updated = shared.ScheduledOrder(
                    id: scheduledOrder?.id ??
                        now.microsecondsSinceEpoch.toString(),
                    userId: _userId!,
                    storeId: franchiseProvider.currentFranchiseId,
                    items: orderItems,
                    frequency: freqController.text,
                    nextDate: nextRun,
                    isPaused: isPaused,
                  );

                  if (isEditing) {
                    await firestoreService.updateScheduledOrder(updated);
                  } else {
                    await firestoreService.addScheduledOrder(updated);
                  }
                  if (mounted) Navigator.of(context).pop();
                },
              )
            ],
          );
        });
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context)!;
    final franchiseProvider = Provider.of<shared.FranchiseProvider>(context);

    if (_userId == null) {
      return Scaffold(
        appBar: FranchiseAppBar(
          title: localizations.scheduledOrders,
          showLogo: true,
          logoUrl: shared.UiConfig.currentLogoUrl,
          logoAsset: shared.BrandingConfig.appBarLogoAsset,
          centerTitle: true,
        ),
        backgroundColor: shared.UiConfig.backgroundColorDark,
        body: Center(
          child: Text(
            localizations.mustSignInForScheduledOrders,
            style: shared.UiConfig.bodyStyle,
          ),
        ),
      );
    }

    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: FranchiseAppBar(
        title: localizations.scheduledOrders,
        showLogo: true,
        logoUrl: shared.UiConfig.currentLogoUrl,
        logoAsset: shared.BrandingConfig.appBarLogoAsset,
        centerTitle: true,
      ),
      backgroundColor: shared.UiConfig.backgroundColorDark,
      floatingActionButton: FloatingActionButton(
        backgroundColor: shared.UiConfig.primaryColor,
        onPressed: () =>
            _showOrderEditorDialog(firestoreService: firestoreService),
        child: Icon(Icons.add, color: shared.UiConfig.onPrimaryColor),
        tooltip: localizations.addScheduledOrder,
      ),
      body: StreamBuilder<List<shared.Order>>(
        stream: firestoreService.getScheduledOrdersForUser(
          _userId!,
          franchiseId: franchiseProvider.currentFranchiseId,
        ),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final scheduledOrders =
              (snapshot.data ?? []).whereType<shared.ScheduledOrder>().toList();

          if (scheduledOrders.isEmpty) {
            return Center(
              child: Text(
                localizations.noScheduledOrders,
                style: shared.UiConfig.bodyStyle,
              ),
            );
          }
          return Padding(
            padding: shared.UiConfig.defaultScreenPadding,
            child: ListView.builder(
              itemCount: scheduledOrders.length,
              itemBuilder: (context, index) {
                final order = scheduledOrders[index];
                final firstItem =
                    order.items.isNotEmpty ? order.items.first : null;

                return Card(
                  elevation: shared.DesignTokens.cardElevation,
                  margin: const EdgeInsets.symmetric(
                      vertical: shared.DesignTokens.gridSpacing / 2),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(shared.DesignTokens.cardRadius),
                  ),
                  color: shared.UiConfig.surfaceColor,
                  child: ListTile(
                    leading: firstItem != null
                        ? NetworkImageWidget(
                            imageUrl: firstItem.image ?? '',
                            fallbackAsset:
                                shared.BrandingConfig.defaultPizzaIcon,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(24),
                          )
                        : const SizedBox(width: 48, height: 48),
                    title: Text(
                      localizations.orderNumberWithId(order.id),
                      style: shared.UiConfig.bodyBoldStyle,
                    ),
                    subtitle: Text(
                      "${order.frequency ?? 'weekly'} • ${order.nextDate.toString().substring(0, 16)}",
                      style: shared.UiConfig.captionStyle,
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                              order.isPaused ? Icons.play_arrow : Icons.pause),
                          color: shared.UiConfig.primaryColor,
                          tooltip: order.isPaused ? 'Resume' : 'Pause',
                          onPressed: () async {
                            final updated =
                                order.copyWith(isPaused: !order.isPaused);
                            await firestoreService
                                .updateScheduledOrder(updated);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: shared.UiConfig.errorColor,
                          tooltip: localizations.delete,
                          onPressed: () async {
                            await firestoreService
                                .deleteScheduledOrder(order.id);
                          },
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
