// customer_web/lib/features/menu/menu_category_grid_screen.dart
import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

import '../../widgets/branding_shell.dart';
import 'menu_category_items_screen.dart';

class _Cat {
  _Cat({
    required this.id,
    required this.name,
    this.imageUrl,
    this.sortOrder = 9999,
  });

  final String id;
  final String name;
  final String? imageUrl;
  final int sortOrder;
}

/// Parity P0a: category-first menu entry.
class MenuCategoryGridScreen extends StatefulWidget {
  const MenuCategoryGridScreen({super.key});

  @override
  State<MenuCategoryGridScreen> createState() => _MenuCategoryGridScreenState();
}

class _MenuCategoryGridScreenState extends State<MenuCategoryGridScreen> {
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

    if (!fp.hasValidFranchise) {
      return const BrandingShell(
        child: Center(child: Text('No restaurant selected')),
      );
    }

    return BrandingShell(
      child: StreamBuilder<List<shared.MenuItem>>(
        stream: fs.getMenuItems(franchiseId),
        builder: (context, itemSnap) {
          if (itemSnap.hasError) {
            return Center(child: Text('Menu error: ${itemSnap.error}'));
          }
          if (!itemSnap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final items = itemSnap.data!
              .where((m) => m.hideInMenu != true && !m.archived)
              .toList();

          // Counts by categoryId and by display name (fallback).
          final byId = <String, int>{};
          final byName = <String, int>{};
          for (final m in items) {
            final cid = m.categoryId.trim();
            if (cid.isNotEmpty) {
              byId[cid] = (byId[cid] ?? 0) + 1;
            }
            final n = m.category.trim().isEmpty ? 'Menu' : m.category.trim();
            byName[n.toLowerCase()] = (byName[n.toLowerCase()] ?? 0) + 1;
          }

          return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('franchises')
                .doc(franchiseId)
                .collection('categories')
                .snapshots(),
            builder: (context, catSnap) {
              if (catSnap.hasError) {
                return Center(
                  child: Text('Categories error: ${catSnap.error}'),
                );
              }
              if (!catSnap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }

              final cats = <_Cat>[];
              for (final doc in catSnap.data!.docs) {
                final d = doc.data();
                final active = d['active'] != false && d['archived'] != true;
                if (!active) continue;
                final name = (d['name'] ?? d['title'] ?? doc.id).toString();
                final imageUrl = (d['imageUrl'] ?? d['image'] ?? d['photoUrl'])
                    ?.toString();
                final sort = (d['sortOrder'] as num?)?.toInt() ?? 9999;
                final count = (byId[doc.id] ?? 0) > 0
                    ? byId[doc.id]!
                    : (byName[name.toLowerCase()] ?? 0);
                if (count <= 0) continue;
                cats.add(
                  _Cat(
                    id: doc.id,
                    name: name,
                    imageUrl: imageUrl,
                    sortOrder: sort,
                  ),
                );
              }
              cats.sort((a, b) {
                if (a.sortOrder != b.sortOrder) {
                  return a.sortOrder.compareTo(b.sortOrder);
                }
                return a.name.compareTo(b.name);
              });

              if (cats.isEmpty) {
                return const Center(
                  child: Text('No menu categories available'),
                );
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
                            style: TextStyle(
                              color: Theme.of(
                                context,
                              ).colorScheme.onErrorContainer,
                            ),
                          ),
                        ),
                      ),
                    ),
                  SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
                      child: Text(
                        'Menu',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                    ),
                  ),
                  SliverPadding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    sliver: SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithMaxCrossAxisExtent(
                            maxCrossAxisExtent: 220,
                            mainAxisSpacing: 12,
                            crossAxisSpacing: 12,
                            childAspectRatio: 0.9,
                          ),
                      delegate: SliverChildBuilderDelegate((context, index) {
                        final cat = cats[index];
                        return _CategoryCard(
                          category: cat,
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => MenuCategoryItemsScreen(
                                  categoryId: cat.id,
                                  categoryName: cat.name,
                                ),
                              ),
                            );
                          },
                        );
                      }, childCount: cats.length),
                    ),
                  ),
                  const SliverToBoxAdapter(child: SizedBox(height: 32)),
                ],
              );
            },
          );
        },
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({required this.category, required this.onTap});

  final _Cat category;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final url = category.imageUrl?.trim() ?? '';

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Expanded(
              child: url.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: url,
                      fit: BoxFit.cover,
                      errorWidget: (_, __, ___) => ColoredBox(
                        color: scheme.surfaceContainerHighest,
                        child: Icon(Icons.restaurant, color: scheme.primary),
                      ),
                    )
                  : ColoredBox(
                      color: scheme.surfaceContainerHighest,
                      child: Icon(Icons.restaurant, color: scheme.primary),
                    ),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Text(
                category.name,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
