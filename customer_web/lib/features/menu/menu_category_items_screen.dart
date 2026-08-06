// customer_web/lib/features/menu/menu_category_items_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../../widgets/branding_shell.dart';
import '../../widgets/menu_item_card.dart';
import 'menu_item_detail_screen.dart';

/// Items for one category (P0a).
class MenuCategoryItemsScreen extends StatefulWidget {
  const MenuCategoryItemsScreen({
    super.key,
    required this.categoryId,
    required this.categoryName,
    this.embed = false,
  });

  final String categoryId;
  final String categoryName;
  final bool embed;

  @override
  State<MenuCategoryItemsScreen> createState() =>
      _MenuCategoryItemsScreenState();
}

class _MenuCategoryItemsScreenState extends State<MenuCategoryItemsScreen> {
  TimeOfDay _open = const TimeOfDay(hour: 11, minute: 0);
  TimeOfDay _close = const TimeOfDay(hour: 21, minute: 0);
  bool _dayClosed = false;
  bool _opsLoaded = false;
  String? _opsForFranchiseId;

  static String _weekdayKey(DateTime dt) {
    switch (dt.weekday) {
      case DateTime.monday:
        return 'mon';
      case DateTime.tuesday:
        return 'tue';
      case DateTime.wednesday:
        return 'wed';
      case DateTime.thursday:
        return 'thu';
      case DateTime.friday:
        return 'fri';
      case DateTime.saturday:
        return 'sat';
      default:
        return 'sun';
    }
  }

  bool _inHours(TimeOfDay t) {
    if (_dayClosed) return false;
    int m(TimeOfDay x) => x.hour * 60 + x.minute;
    return m(t) >= m(_open) && m(t) <= m(_close);
  }

  bool get _storeOpenNow => _inHours(TimeOfDay.fromDateTime(DateTime.now()));

  Future<void> _loadStoreOps(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') return;
    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('config')
          .doc('store_ops')
          .get();
      final data = snap.data();
      if (data == null || !mounted) return;

      final key = _weekdayKey(DateTime.now());
      var open = _open;
      var close = _close;
      var closed = false;

      final hoursRaw = data['hours'];
      if (hoursRaw is Map && hoursRaw[key] is Map) {
        final day = Map<String, dynamic>.from(hoursRaw[key] as Map);
        closed = day['closed'] == true;
        open = TimeOfDay(
          hour: day['openHour'] as int? ?? 11,
          minute: day['openMinute'] as int? ?? 0,
        );
        close = TimeOfDay(
          hour: day['closeHour'] as int? ?? 21,
          minute: day['closeMinute'] as int? ?? 0,
        );
      } else {
        open = TimeOfDay(
          hour: data['openHour'] as int? ?? 11,
          minute: data['openMinute'] as int? ?? 0,
        );
        close = TimeOfDay(
          hour: data['closeHour'] as int? ?? 21,
          minute: data['closeMinute'] as int? ?? 0,
        );
      }

      setState(() {
        _open = open;
        _close = close;
        _dayClosed = closed;
        _opsLoaded = true;
      });
    } catch (e) {
      debugPrint('[menu] store_ops: $e');
      if (mounted) setState(() => _opsLoaded = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final fp = Provider.of<shared.FranchiseProvider>(context, listen: true);
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;

    if (_opsForFranchiseId != franchiseId) {
      _opsForFranchiseId = franchiseId;
      _opsLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStoreOps(franchiseId);
      });
    }

    final content = StreamBuilder<List<shared.MenuItem>>(
      stream: fs.getMenuItems(franchiseId),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final nameLower = widget.categoryName.trim().toLowerCase();
        final items =
            snapshot.data!
                .where((m) => m.hideInMenu != true && !m.archived)
                .where((m) => m.isSellable)
                .where((m) {
                  if (m.categoryId.trim() == widget.categoryId) return true;
                  return m.category.trim().toLowerCase() == nameLower;
                })
                .toList()
              ..sort((a, b) {
                final ao = a.sortOrder ?? 9999;
                final bo = b.sortOrder ?? 9999;
                if (ao != bo) return ao.compareTo(bo);
                return a.name.compareTo(b.name);
              });

        if (items.isEmpty) {
          return Center(child: Text('No items in ${widget.categoryName}'));
        }

        return CustomScrollView(
          slivers: [
            if (_opsLoaded && !_storeOpenNow)
              SliverToBoxAdapter(
                child: Material(
                  color: Theme.of(context).colorScheme.errorContainer,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                    child: Text(
                      _dayClosed
                          ? 'Closed today. You can browse the menu; ordering resumes next open day.'
                          : 'Currently closed. Hours today: ${_open.format(context)}–${_close.format(context)}. You can browse; checkout is blocked until open.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onErrorContainer,
                      ),
                    ),
                  ),
                ),
              ),
            if (!widget.embed)
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Text(
                    widget.categoryName,
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                ),
              ),
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                  maxCrossAxisExtent: MediaQuery.sizeOf(context).width < 600
                      ? 200.0
                      : 240.0,
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 0.75,
                ),
                delegate: SliverChildBuilderDelegate((context, index) {
                  final item = items[index];
                  return MenuItemCard(
                    item: item,
                    onTap: () {
                      showDialog<void>(
                        context: context,
                        barrierDismissible: true,
                        builder: (dialogContext) {
                          return Dialog(
                            insetPadding: const EdgeInsets.symmetric(
                              horizontal: 24,
                              vertical: 24,
                            ),
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(
                                maxWidth: 640,
                                maxHeight: 720,
                              ),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Material(
                                  color: Theme.of(
                                    dialogContext,
                                  ).colorScheme.surface,
                                  child: MenuItemDetailScreen(item: item),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  );
                }, childCount: items.length),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 32)),
          ],
        );
      },
    );

    return widget.embed ? content : BrandingShell(child: content);
  }
}
