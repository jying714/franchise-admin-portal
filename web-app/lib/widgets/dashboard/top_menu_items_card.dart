import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TopMenuItemsCard extends StatefulWidget {
  final String franchiseId;

  const TopMenuItemsCard({Key? key, required this.franchiseId})
      : super(key: key);

  @override
  State<TopMenuItemsCard> createState() => _TopMenuItemsCardState();
}

class _TopMenuItemsCardState extends State<TopMenuItemsCard> {
  late Future<List<_MenuRank>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant TopMenuItemsCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.franchiseId != widget.franchiseId) {
      _future = _load();
    }
  }

  DateTime? _asDateTime(dynamic raw) {
    if (raw == null) return null;
    if (raw is Timestamp) return raw.toDate();
    if (raw is DateTime) return raw;
    if (raw is String && raw.trim().isNotEmpty) {
      return DateTime.tryParse(raw.trim());
    }
    return null;
  }

  DateTime? _orderTime(Map<String, dynamic> data) {
    final primary = _asDateTime(data['timestamp']);
    if (primary != null) return primary;
    final tsMap = data['timestamps'];
    if (tsMap is Map) {
      for (final key in ['paid', 'created', 'sent_to_kitchen', 'open']) {
        final t = _asDateTime(tsMap[key]);
        if (t != null) return t;
      }
    }
    return _asDateTime(data['createdAt']);
  }

  bool _countsTowardKpi(Map<String, dynamic> data) {
    final status = (data['status'] as String?)?.toLowerCase().trim() ?? '';
    if (status == 'pending_payment' ||
        status == 'cancelled' ||
        status == 'canceled') {
      return false;
    }
    return true;
  }

  bool _lineIsActive(Map<String, dynamic> line) {
    final ls = (line['lineStatus'] as String?)?.toLowerCase().trim();
    if (ls == null || ls.isEmpty) return true;
    return ls == 'active';
  }

  Future<List<_MenuRank>> _load() async {
    final franchiseId = widget.franchiseId;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final rangeStart = todayStart.subtract(const Duration(days: 6));

    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'test' ||
        franchiseId == 'default') {
      return const [];
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('orders')
          .get();

      final qtyByKey = <String, int>{};
      final nameByKey = <String, String>{};

      for (final doc in snap.docs) {
        final data = doc.data();
        if (!_countsTowardKpi(data)) continue;
        final ts = _orderTime(data);
        if (ts == null) continue;
        final day = DateTime(ts.year, ts.month, ts.day);
        if (day.isBefore(rangeStart) || day.isAfter(todayStart)) continue;

        final items = data['items'];
        if (items is! List) continue;
        for (final raw in items) {
          if (raw is! Map) continue;
          final line = Map<String, dynamic>.from(raw);
          if (!_lineIsActive(line)) continue;

          final name = (line['name'] as String?)?.trim() ?? '';
          final menuItemId = (line['menuItemId'] as String?)?.trim() ?? '';
          final key = menuItemId.isNotEmpty
              ? menuItemId
              : (name.isNotEmpty ? 'name:$name' : '');
          if (key.isEmpty) continue;

          final qtyRaw = line['quantity'];
          final qty = qtyRaw is num ? qtyRaw.toInt() : 1;
          if (qty <= 0) continue;

          qtyByKey[key] = (qtyByKey[key] ?? 0) + qty;
          if (name.isNotEmpty) {
            nameByKey[key] = name;
          } else {
            nameByKey.putIfAbsent(key, () => key);
          }
        }
      }

      final ranks = qtyByKey.entries
          .map(
            (e) => _MenuRank(
              key: e.key,
              name: nameByKey[e.key] ?? e.key,
              quantity: e.value,
            ),
          )
          .toList()
        ..sort((a, b) {
          final byQty = b.quantity.compareTo(a.quantity);
          if (byQty != 0) return byQty;
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });

      if (ranks.length <= 5) return ranks;
      return ranks.sublist(0, 5);
    } catch (e) {
      debugPrint('[TopMenuItemsCard] load failed: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      color: scheme.surface,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Top Menu Items',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                Text(
                  'Last 7 days',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: scheme.onSurface.withOpacity(0.55),
                      ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Expanded(
              child: FutureBuilder<List<_MenuRank>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load top items',
                        style: TextStyle(color: scheme.error, fontSize: 13),
                      ),
                    );
                  }
                  final ranks = snapshot.data ?? const <_MenuRank>[];
                  if (ranks.isEmpty) {
                    return Center(
                      child: Text(
                        'No item sales in range',
                        style: TextStyle(
                          color: scheme.onSurface.withOpacity(0.55),
                          fontSize: 13,
                        ),
                      ),
                    );
                  }

                  final maxQty = ranks.first.quantity.toDouble();

                  return ListView.separated(
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: ranks.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      final row = ranks[index];
                      final fraction =
                          maxQty <= 0 ? 0.0 : row.quantity / maxQty;
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Row(
                            children: [
                              SizedBox(
                                width: 18,
                                child: Text(
                                  '${index + 1}.',
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodySmall
                                      ?.copyWith(
                                        color:
                                            scheme.onSurface.withOpacity(0.55),
                                      ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  row.name,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodyMedium,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                '${row.quantity}',
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyMedium
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: fraction.clamp(0.0, 1.0),
                              minHeight: 6,
                              backgroundColor: scheme.primary.withOpacity(0.12),
                              color: scheme.primary,
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MenuRank {
  final String key;
  final String name;
  final int quantity;

  const _MenuRank({
    required this.key,
    required this.name,
    required this.quantity,
  });
}
