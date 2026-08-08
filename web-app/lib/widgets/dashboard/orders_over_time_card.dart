import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class OrdersOverTimeCard extends StatefulWidget {
  final String franchiseId;

  const OrdersOverTimeCard({Key? key, required this.franchiseId})
      : super(key: key);

  @override
  State<OrdersOverTimeCard> createState() => _OrdersOverTimeCardState();
}

class _OrdersOverTimeCardState extends State<OrdersOverTimeCard> {
  late Future<List<_DayBucket>> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  @override
  void didUpdateWidget(covariant OrdersOverTimeCard oldWidget) {
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

  Future<List<_DayBucket>> _load() async {
    final franchiseId = widget.franchiseId;
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final rangeStart = todayStart.subtract(const Duration(days: 6));

    final buckets = List<_DayBucket>.generate(7, (i) {
      final day = rangeStart.add(Duration(days: i));
      return _DayBucket(day: day, count: 0);
    });

    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'test' ||
        franchiseId == 'default') {
      return buckets;
    }

    try {
      final snap = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(franchiseId)
          .collection('orders')
          .get();

      for (final doc in snap.docs) {
        final data = doc.data();
        if (!_countsTowardKpi(data)) continue;
        final ts = _orderTime(data);
        if (ts == null) continue;
        final day = DateTime(ts.year, ts.month, ts.day);
        if (day.isBefore(rangeStart) || day.isAfter(todayStart)) continue;
        final index = day.difference(rangeStart).inDays;
        if (index >= 0 && index < buckets.length) {
          buckets[index] = buckets[index].copyWith(
            count: buckets[index].count + 1,
          );
        }
      }
      return buckets;
    } catch (e) {
      debugPrint('[OrdersOverTimeCard] load failed: $e');
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelFormat = DateFormat('E'); // Mon, Tue, …

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
                    'Orders Over Time',
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
              child: FutureBuilder<List<_DayBucket>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Unable to load series',
                        style: TextStyle(color: scheme.error, fontSize: 13),
                      ),
                    );
                  }
                  final buckets = snapshot.data ?? const <_DayBucket>[];
                  final maxY = buckets.fold<int>(
                    0,
                    (m, b) => b.count > m ? b.count : m,
                  );
                  final chartMax = (maxY < 4 ? 4 : maxY).toDouble();

                  return BarChart(
                    BarChartData(
                      maxY: chartMax,
                      minY: 0,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        horizontalInterval: chartMax <= 4 ? 1 : null,
                        getDrawingHorizontalLine: (v) => FlLine(
                          color: scheme.outlineVariant.withOpacity(0.5),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 28,
                            interval: chartMax <= 4 ? 1 : null,
                            getTitlesWidget: (value, meta) {
                              if (value != value.roundToDouble()) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                value.toInt().toString(),
                                style: TextStyle(
                                  fontSize: 10,
                                  color: scheme.onSurface.withOpacity(0.55),
                                ),
                              );
                            },
                          ),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 22,
                            getTitlesWidget: (value, meta) {
                              final i = value.toInt();
                              if (i < 0 || i >= buckets.length) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  labelFormat.format(buckets[i].day),
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: scheme.onSurface.withOpacity(0.65),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: [
                        for (var i = 0; i < buckets.length; i++)
                          BarChartGroupData(
                            x: i,
                            barRods: [
                              BarChartRodData(
                                toY: buckets[i].count.toDouble(),
                                width: 14,
                                borderRadius: const BorderRadius.vertical(
                                  top: Radius.circular(4),
                                ),
                                color: scheme.primary,
                              ),
                            ],
                          ),
                      ],
                      barTouchData: BarTouchData(
                        touchTooltipData: BarTouchTooltipData(
                          getTooltipItem: (group, groupIndex, rod, rodIndex) {
                            final i = group.x;
                            if (i < 0 || i >= buckets.length) return null;
                            final b = buckets[i];
                            final dayLabel =
                                DateFormat('MMM d').format(b.day);
                            return BarTooltipItem(
                              '$dayLabel\n${b.count} order${b.count == 1 ? '' : 's'}',
                              TextStyle(
                                color: scheme.onPrimary,
                                fontWeight: FontWeight.w600,
                                fontSize: 12,
                              ),
                            );
                          },
                        ),
                      ),
                    ),
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

class _DayBucket {
  final DateTime day;
  final int count;

  const _DayBucket({required this.day, required this.count});

  _DayBucket copyWith({int? count}) =>
      _DayBucket(day: day, count: count ?? this.count);
}