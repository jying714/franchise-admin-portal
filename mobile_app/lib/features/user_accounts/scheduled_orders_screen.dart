import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_mobile_app/core/models/scheduled_order.dart';
import 'package:franchise_mobile_app/core/services/firestore_service.dart';
import 'package:franchise_mobile_app/core/models/menu_item.dart';
import 'package:franchise_mobile_app/config/design_tokens.dart';
import 'package:franchise_mobile_app/config/branding_config.dart';
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
    _userId = FirebaseAuth.instance.currentUser?.uid;
  }

  Future<void> _showOrderEditorDialog({
    ScheduledOrder? scheduledOrder,
    required FirestoreService firestoreService,
  }) async {
    final localizations = AppLocalizations.of(context)!;
    final isEditing = scheduledOrder != null;
    final TextEditingController freqController =
        TextEditingController(text: scheduledOrder?.frequency ?? 'weekly');
    DateTime nextRun =
        scheduledOrder?.nextRun ?? DateTime.now().add(const Duration(days: 7));
    bool isPaused = scheduledOrder?.isPaused ?? false;
    final menuItems = await firestoreService.getMenuItems().first;
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
                        child: Text(localizations.frequencyDaily),
                      ),
                      DropdownMenuItem(
                        value: 'weekly',
                        child: Text(localizations.frequencyWeekly),
                      ),
                      DropdownMenuItem(
                        value: 'monthly',
                        child: Text(localizations.frequencyMonthly),
                      ),
                    ],
                    onChanged: (value) {
                      setModalState(
                          () => freqController.text = value ?? 'weekly');
                    },
                    decoration: InputDecoration(
                      labelText: localizations.frequency,
                    ),
                  ),
                  ListTile(
                    title: Text(localizations.nextRunDate),
                    subtitle: Text("${nextRun.toString().substring(0, 16)}"),
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
                              selected: selectedItems.contains(item),
                              onSelected: (selected) {
                                setModalState(() {
                                  selected
                                      ? selectedItems.add(item)
                                      : selectedItems.remove(item);
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
                  final now = DateTime.now();
                  final ScheduledOrder updated = ScheduledOrder(
                    id: scheduledOrder?.id ??
                        now.microsecondsSinceEpoch.toString(),
                    userId: _userId!,
                    items: selectedItems,
                    frequency: freqController.text,
                    nextRun: nextRun,
                    isPaused: isPaused,
                    createdAt: scheduledOrder?.createdAt ?? now,
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
    if (_userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            localizations.scheduledOrders,
            style: const TextStyle(
              fontSize: DesignTokens.titleFontSize,
              color: DesignTokens.foregroundColor,
              fontWeight: DesignTokens.titleFontWeight,
              fontFamily: DesignTokens.fontFamily,
            ),
          ),
          backgroundColor: DesignTokens.primaryColor,
          centerTitle: true,
          elevation: 0,
          iconTheme: const IconThemeData(color: DesignTokens.foregroundColor),
        ),
        backgroundColor: DesignTokens.backgroundColor,
        body: Center(
          child: Text(
            localizations.mustSignInForScheduledOrders,
            style: const TextStyle(
              fontSize: DesignTokens.bodyFontSize,
              color: DesignTokens.textColor,
              fontFamily: DesignTokens.fontFamily,
              fontWeight: DesignTokens.bodyFontWeight,
            ),
          ),
        ),
      );
    }

    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          localizations.scheduledOrders,
          style: const TextStyle(
            fontSize: DesignTokens.titleFontSize,
            color: DesignTokens.foregroundColor,
            fontWeight: DesignTokens.titleFontWeight,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
        backgroundColor: DesignTokens.primaryColor,
        centerTitle: true,
        elevation: 0,
        iconTheme: const IconThemeData(color: DesignTokens.foregroundColor),
      ),
      backgroundColor: DesignTokens.backgroundColor,
      floatingActionButton: FloatingActionButton(
        backgroundColor: DesignTokens.primaryColor,
        onPressed: () =>
            _showOrderEditorDialog(firestoreService: firestoreService),
        child: const Icon(Icons.add, color: Colors.white),
        tooltip: localizations.addScheduledOrder,
      ),
      body: StreamBuilder<List<ScheduledOrder>>(
        stream: firestoreService.getScheduledOrdersForUser(_userId!),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final scheduledOrders = snapshot.data ?? [];
          if (scheduledOrders.isEmpty) {
            return Center(
              child: Text(
                localizations.noScheduledOrders,
                style: const TextStyle(
                  fontSize: DesignTokens.bodyFontSize,
                  color: DesignTokens.textColor,
                  fontFamily: DesignTokens.fontFamily,
                  fontWeight: DesignTokens.bodyFontWeight,
                ),
              ),
            );
          }
          return Padding(
            padding: DesignTokens.cardPadding,
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
                  color: DesignTokens.surfaceColor,
                  child: ListTile(
                    leading: firstItem != null
                        ? NetworkImageWidget(
                            imageUrl: firstItem.image ?? '',
                            fallbackAsset: 'assets/images/pizza_icon.png',
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            borderRadius: BorderRadius.circular(24),
                          )
                        : const SizedBox(width: 48, height: 48),
                    title: Text(
                      localizations.orderNumberWithId(order.id),
                      style: const TextStyle(
                        fontSize: DesignTokens.bodyFontSize,
                        color: DesignTokens.textColor,
                        fontWeight: DesignTokens.titleFontWeight,
                        fontFamily: DesignTokens.fontFamily,
                      ),
                    ),
                    subtitle: Text(
                      localizations.scheduledOrderSubtitle(
                        order.frequency,
                        order.nextRun.toString().substring(0, 16),
                        order.items.map((e) => e.name).join(', '),
                      ),
                      style: const TextStyle(
                        fontSize: DesignTokens.captionFontSize,
                        color: DesignTokens.secondaryTextColor,
                        fontFamily: DesignTokens.fontFamily,
                        fontWeight: DesignTokens.bodyFontWeight,
                      ),
                    ),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: Icon(
                            order.isPaused ? Icons.play_arrow : Icons.pause,
                          ),
                          color: DesignTokens.primaryColor,
                          tooltip: order.isPaused
                              ? localizations.resume
                              : localizations.pause,
                          onPressed: () async {
                            await firestoreService.updateScheduledOrder(
                              order.copyWith(isPaused: !order.isPaused),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.edit),
                          color: DesignTokens.secondaryColor,
                          tooltip: localizations.edit,
                          onPressed: () => _showOrderEditorDialog(
                            scheduledOrder: order,
                            firestoreService: firestoreService,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete),
                          color: DesignTokens.errorColor,
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
