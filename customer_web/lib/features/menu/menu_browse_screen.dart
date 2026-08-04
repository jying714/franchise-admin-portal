// customer_web/lib/features/menu/menu_browse_screen.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'menu_item_detail_screen.dart';
import '../../widgets/branding_shell.dart';
import '../../widgets/menu_item_card.dart';

/// Signed-out menu browse for a bound franchise.
/// Uses existing FirestoreService menu APIs only.
class MenuBrowseScreen extends StatefulWidget {
  const MenuBrowseScreen({super.key});

  @override
  State<MenuBrowseScreen> createState() => _MenuBrowseScreenState();
}

class _MenuBrowseScreenState extends State<MenuBrowseScreen> {
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
    final fp = context.watch<shared.FranchiseProvider>();
    final fs = Provider.of<shared.FirestoreService>(context, listen: false);
    final franchiseId = fp.currentFranchiseId;

    if (!fp.hasValidFranchise) {
      return const BrandingShell(
        child: Center(child: Text('No restaurant selected')),
      );
    }

    if (_opsForFranchiseId != franchiseId) {
      _opsForFranchiseId = franchiseId;
      _opsLoaded = false;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _loadStoreOps(franchiseId);
      });
    }

    return BrandingShell(
      child: StreamBuilder<List<shared.MenuItem>>(
        stream: fs.getMenuItems(franchiseId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Could not load menu.\n${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items =
              snapshot.data!
                  .where((m) => m.hideInMenu != true && !m.archived)
                  .where((m) => m.isSellable)
                  .toList()
                ..sort((a, b) {
                  final ao = a.sortOrder ?? 9999;
                  final bo = b.sortOrder ?? 9999;
                  if (ao != bo) return ao.compareTo(bo);
                  return a.name.compareTo(b.name);
                });

          if (items.isEmpty) {
            return const Center(child: Text('Menu is empty'));
          }

          // Group by category label (display only — no second schema).
          final byCategory = <String, List<shared.MenuItem>>{};
          for (final item in items) {
            final key = item.category.trim().isEmpty
                ? 'Menu'
                : item.category.trim();
            byCategory.putIfAbsent(key, () => []).add(item);
          }
          final categoryNames = byCategory.keys.toList()..sort();

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
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onErrorContainer,
                        ),
                      ),
                    ),
                  ),
                ),
              for (final cat in categoryNames) ...[
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                    child: Text(
                      cat,
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                  ),
                ),
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  sliver: SliverGrid(
                    gridDelegate: SliverGridDelegateWithMaxCrossAxisExtent(
                      maxCrossAxisExtent: () {
                        final w = MediaQuery.sizeOf(context).width;
                        if (w < 600) return 200.0; // phone: denser
                        if (w < 900) return 240.0; // tablet
                        return 280.0; // desktop
                      }(),
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: MediaQuery.sizeOf(context).width < 600
                          ? 0.72
                          : 0.78,
                    ),
                    delegate: SliverChildBuilderDelegate((context, index) {
                      final item = byCategory[cat]![index];
                      return MenuItemCard(
                        item: item,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) => MenuItemDetailScreen(item: item),
                            ),
                          );
                        },
                      );
                    }, childCount: byCategory[cat]!.length),
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 32)),
            ],
          );
        },
      ),
    );
  }
}
