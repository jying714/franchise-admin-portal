import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:shared_core/shared_core.dart' show DesignTokens;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:franchise_mobile_app/core/models/scheduled_order.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/widgets/network_image_widget.dart';
import 'package:franchise_mobile_app/core/providers/franchise_provider.dart';
import 'package:shared_core/shared_core.dart' show BrandingConfig;

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
    ScheduledOrder? scheduledOrder,
    required shared.FirestoreService firestoreService,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final isEditing = scheduledOrder != null;
    final TextEditingController freqController =
        TextEditingController(text: scheduledOrder?.frequency ?? 'weekly');

    DateTime nextRun =
        scheduledOrder?.nextDate ?? DateTime.now().add(const Duration(days: 7));
    bool isPaused = scheduledOrder?.isPaused ??
        false; // Will be handled via status fallback if missing

    final franchiseProvider =
        Provider.of<FranchiseProvider>(context, listen: false);
    final menuItems = await firestoreService
        .getMenuItems(franchiseProvider.currentFranchiseId)
        .first;
    List<MenuItem> selectedItems =
        List<MenuItem>.from(scheduledOrder?.items ?? []);

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
                        if (picked != null) {
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
                                  selectedItems.any((i) => i.id == item.id),
                              onSelected: (selected) {
                                setModalState(() {
                                  if (selected) {
                                    selectedItems.add(item);
                                  } else {
                                    selectedItems
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
                  if (_userId == null || selectedItems.isEmpty) return;

                  final franchiseProvider =
                      Provider.of<FranchiseProvider>(context, listen: false);
                  final now = DateTime.now();

                  final ScheduledOrder updated = ScheduledOrder(
                    id: scheduledOrder?.id ??
                        now.microsecondsSinceEpoch.toString(),
                    userId: _userId!,
                    franchiseId: franchiseProvider.currentFranchiseId,
                    items: selectedItems,
                    frequency: freqController.text,
                    nextDate: nextRun,
                    isPaused: isPaused,
                  );

                  if (isEditing) {
                    await firestoreService
                        .updateScheduledOrder(updated as shared.Order);
                  } else {
                    await firestoreService
                        .addScheduledOrder(updated as shared.Order);
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
    final franchiseProvider = Provider.of<FranchiseProvider>(context);

    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.scheduledOrders,
            style: TextStyle(
              fontSize: DesignTokens.titleFontSize,
              color: UiConfig.foregroundColorDark,
              fontWeight: UiConfig.fontWeightBold,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          backgroundColor: UiConfig.primaryColor,
          centerTitle: true,
          elevation: 0,
          iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
        ),
        backgroundColor: UiConfig.backgroundColorDark,
        body: Center(
          child: Text(
            localizations.mustSignInForScheduledOrders,
            style: TextStyle(
              fontSize: DesignTokens.bodyFontSize,
              color: UiConfig.textColorDark,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: UiConfig.fontWeightNormal,
            ),
          ),
        ),
      );
    }

    final firestoreService =
        Provider.of<shared.FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.scheduledOrders,
          style: TextStyle(
            fontSize: DesignTokens.titleFontSize,
            color: UiConfig.foregroundColorDark,
            fontWeight: UiConfig.fontWeightBold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: UiConfig.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: IconThemeData(color: UiConfig.foregroundColorDark),
      ),
      backgroundColor: UiConfig.backgroundColorDark,
      floatingActionButton: FloatingActionButton(
        backgroundColor: UiConfig.primaryColor,
        onPressed: () =>
            _showOrderEditorDialog(firestoreService: firestoreService),
        child: const Icon(Icons.add, color: Colors.white),
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
          final scheduledOrders = snapshot.data ?? [];
          if (scheduledOrders.isEmpty) {
            return Center(
              child: Text(
                localizations.noScheduledOrders,
                style: TextStyle(
                  fontSize: DesignTokens.bodyFontSize,
                  color: UiConfig.textColorDark,
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: UiConfig.fontWeightNormal,
                ),
              ),
            );
          }
          return Padding(
            padding: UiConfig.defaultScreenPadding,
            child: ListView.builder(
              itemCount: scheduledOrders.length,
              itemBuilder: (context, index) {
                final order = scheduledOrders[index];
                final firstItem =
                    order.items.isNotEmpty ? order.items.first : null;

                return Card(
                  elevation: DesignTokens.cardElevation,
                  margin: const EdgeInsets.symmetric(
                      vertical: DesignTokens.gridSpacing / 2),
                  shape: RoundedRectangleBorder(
                    borderRadius:
                        BorderRadius.circular(DesignTokens.cardRadius),
                  ),
                  color: UiConfig.surfaceColor,
                  child: ListTile(
                    leading: firstItem != null
                        ? NetworkImageWidget(
                            imageUrl: firstItem.image ?? '',
                            fallbackAsset: BrandingConfig.defaultPizzaIcon,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(24),
                          )
                        : const SizedBox(width: 48, height: 48),
                    title: Text(
                      localizations.orderNumberWithId(order.id),
                      style: TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        color: UiConfig.textColorDark,
                        fontWeight: UiConfig.fontWeightBold,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                    subtitle: Text(
                      "${order.frequency ?? 'weekly'} • ${order.timestamp.toString().substring(0, 16)}",
                      style: TextStyle(
                        fontSize: DesignTokens.captionFontSize,
                        color: UiConfig.secondaryTextColor,
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: UiConfig.fontWeightNormal,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.pause),
                          color: UiConfig.primaryColor,
                          tooltip: 'Pause',
                          onPressed: () async {
                            final updated = order.copyWith(status: 'paused');
                            await firestoreService
                                .updateScheduledOrder(updated);
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: UiConfig.errorColor,
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
