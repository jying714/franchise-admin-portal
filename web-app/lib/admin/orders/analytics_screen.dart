import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

enum _AnalyticsPeriod { today, days7, days30, month }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  _AnalyticsPeriod _period = _AnalyticsPeriod.days7;
  Future<_AnalyticsSnapshot>? _future;
  String? _loadedForFranchise;

  String _periodLabel(_AnalyticsPeriod p) {
    switch (p) {
      case _AnalyticsPeriod.today:
        return 'Today';
      case _AnalyticsPeriod.days7:
        return 'Last 7 days';
      case _AnalyticsPeriod.days30:
        return 'Last 30 days';
      case _AnalyticsPeriod.month:
        return 'This month';
    }
  }

  DateTime _periodStart(_AnalyticsPeriod p) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    switch (p) {
      case _AnalyticsPeriod.today:
        return today;
      case _AnalyticsPeriod.days7:
        return today.subtract(const Duration(days: 6));
      case _AnalyticsPeriod.days30:
        return today.subtract(const Duration(days: 29));
      case _AnalyticsPeriod.month:
        return DateTime(now.year, now.month, 1);
    }
  }

  void _ensureLoad(String franchiseId) {
    if (_future != null && _loadedForFranchise == franchiseId) return;
    _loadedForFranchise = franchiseId;
    _future = _load(franchiseId, _period);
  }

  void _reload(String franchiseId) {
    setState(() {
      _loadedForFranchise = franchiseId;
      _future = _load(franchiseId, _period);
    });
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

  bool _countsTowardSales(Map<String, dynamic> data) {
    final status = (data['status'] as String?)?.toLowerCase().trim() ?? '';
    if (status == 'pending_payment' ||
        status == 'cancelled' ||
        status == 'canceled') {
      return false;
    }
    return true;
  }

  bool _isCancelled(Map<String, dynamic> data) {
    final status = (data['status'] as String?)?.toLowerCase().trim() ?? '';
    return status == 'cancelled' || status == 'canceled';
  }

  bool _lineActive(Map line) {
    final ls = (line['lineStatus'] as String?)?.toLowerCase().trim();
    if (ls == null || ls.isEmpty) return true;
    return ls == 'active';
  }

  Future<_AnalyticsSnapshot> _load(
    String franchiseId,
    _AnalyticsPeriod period,
  ) async {
    final start = _periodStart(period);
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final dayCount = today.difference(start).inDays + 1;
    final dayBuckets = List<_DayPoint>.generate(dayCount, (i) {
      final d = start.add(Duration(days: i));
      return _DayPoint(day: d, orders: 0, revenue: 0);
    });

    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'test') {
      return _AnalyticsSnapshot.empty(periodLabel: _periodLabel(period));
    }

    final snap = await FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .get();

    var totalOrders = 0;
    var cancelled = 0;
    var revenue = 0.0;
    final customers = <String>{};
    final bySource = <String, int>{};
    final byType = <String, int>{};
    final itemQty = <String, int>{};
    final itemName = <String, String>{};

    for (final doc in snap.docs) {
      final data = doc.data();
      final ts = _orderTime(data);
      if (ts == null) continue;
      final day = DateTime(ts.year, ts.month, ts.day);
      if (day.isBefore(start) || day.isAfter(today)) continue;

      if (_isCancelled(data)) {
        cancelled++;
        continue;
      }
      if (!_countsTowardSales(data)) continue;

      totalOrders++;
      final total = data['total'];
      final orderRevenue = total is num ? total.toDouble() : 0.0;
      revenue += orderRevenue;

      final uid = (data['userId'] as String?)?.trim();
      if (uid != null && uid.isNotEmpty) customers.add(uid);

      final source = ((data['source'] as String?)?.trim().isNotEmpty == true)
          ? (data['source'] as String).trim().toLowerCase()
          : 'unknown';
      bySource[source] = (bySource[source] ?? 0) + 1;

      final dtype =
          ((data['deliveryType'] as String?)?.trim().isNotEmpty == true)
              ? (data['deliveryType'] as String).trim().toLowerCase()
              : 'unknown';
      byType[dtype] = (byType[dtype] ?? 0) + 1;

      final idx = day.difference(start).inDays;
      if (idx >= 0 && idx < dayBuckets.length) {
        dayBuckets[idx] = dayBuckets[idx].copyWith(
          orders: dayBuckets[idx].orders + 1,
          revenue: dayBuckets[idx].revenue + orderRevenue,
        );
      }

      final items = data['items'];
      if (items is List) {
        for (final raw in items) {
          if (raw is! Map) continue;
          if (!_lineActive(raw)) continue;
          final name = (raw['name'] as String?)?.trim() ?? '';
          final mid = (raw['menuItemId'] as String?)?.trim() ?? '';
          final key = mid.isNotEmpty ? mid : (name.isNotEmpty ? 'n:$name' : '');
          if (key.isEmpty) continue;
          final q = raw['quantity'];
          final qty = q is num ? q.toInt() : 1;
          if (qty <= 0) continue;
          itemQty[key] = (itemQty[key] ?? 0) + qty;
          if (name.isNotEmpty) itemName[key] = name;
          itemName.putIfAbsent(key, () => key);
        }
      }
    }

    final topItems = itemQty.entries
        .map((e) => _RankedItem(
              name: itemName[e.key] ?? e.key,
              quantity: e.value,
            ))
        .toList()
      ..sort((a, b) => b.quantity.compareTo(a.quantity));
    final top5 = topItems.length > 5 ? topItems.sublist(0, 5) : topItems;

    final aov = totalOrders == 0 ? 0.0 : revenue / totalOrders;

    return _AnalyticsSnapshot(
      periodLabel: _periodLabel(period),
      totalOrders: totalOrders,
      cancelledOrders: cancelled,
      totalRevenue: (revenue * 100).roundToDouble() / 100.0,
      averageOrderValue: (aov * 100).roundToDouble() / 100.0,
      uniqueCustomers: customers.length,
      bySource: bySource,
      byFulfillment: byType,
      series: dayBuckets,
      topItems: top5,
      generatedAt: DateTime.now(),
    );
  }

  Future<void> _exportCsv(_AnalyticsSnapshot s) async {
    final buf = StringBuffer();
    buf.writeln('metric,value');
    buf.writeln('period,${s.periodLabel}');
    buf.writeln('total_orders,${s.totalOrders}');
    buf.writeln('total_revenue,${s.totalRevenue}');
    buf.writeln('average_order_value,${s.averageOrderValue}');
    buf.writeln('unique_customers,${s.uniqueCustomers}');
    buf.writeln('cancelled_orders,${s.cancelledOrders}');
    buf.writeln('');
    buf.writeln('day,orders,revenue');
    for (final p in s.series) {
      buf.writeln(
          '${DateFormat('yyyy-MM-dd').format(p.day)},${p.orders},${p.revenue.toStringAsFixed(2)}');
    }
    buf.writeln('');
    buf.writeln('item,quantity');
    for (final t in s.topItems) {
      buf.writeln('"${t.name.replaceAll('"', '""')}",${t.quantity}');
    }
    await Clipboard.setData(ClipboardData(text: buf.toString()));
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Analytics CSV copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final franchiseId =
        context.watch<shared.FranchiseProvider>().franchiseId ?? '';

    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      return Scaffold(
        backgroundColor: scheme.surface,
        body:
            const Center(child: Text('Select a franchise to view analytics.')),
      );
    }

    _ensureLoad(franchiseId);
    final money = NumberFormat.simpleCurrency();

    return Scaffold(
      backgroundColor: scheme.surface,
      body: Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text(
                  'Order Analytics',
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                const Spacer(),
                SegmentedButton<_AnalyticsPeriod>(
                  segments: const [
                    ButtonSegment(
                      value: _AnalyticsPeriod.today,
                      label: Text('Today'),
                    ),
                    ButtonSegment(
                      value: _AnalyticsPeriod.days7,
                      label: Text('7D'),
                    ),
                    ButtonSegment(
                      value: _AnalyticsPeriod.days30,
                      label: Text('30D'),
                    ),
                    ButtonSegment(
                      value: _AnalyticsPeriod.month,
                      label: Text('Month'),
                    ),
                  ],
                  selected: {_period},
                  onSelectionChanged: (set) {
                    final next = set.first;
                    setState(() {
                      _period = next;
                      _future = _load(franchiseId, next);
                      _loadedForFranchise = franchiseId;
                    });
                  },
                ),
                const SizedBox(width: 8),
                IconButton(
                  tooltip: 'Refresh',
                  onPressed: () => _reload(franchiseId),
                  icon: const Icon(Icons.refresh),
                ),
                IconButton(
                  tooltip: 'Copy CSV',
                  onPressed: () async {
                    final snap = await _future;
                    if (snap != null) await _exportCsv(snap);
                  },
                  icon: const Icon(Icons.download_rounded),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Live from franchise orders · excludes pending payment & cancelled',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurface.withOpacity(0.55),
                  ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: FutureBuilder<_AnalyticsSnapshot>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting &&
                      !snapshot.hasData) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (snapshot.hasError) {
                    return Center(
                      child: Text(
                        'Failed to load analytics\n${snapshot.error}',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: scheme.error),
                      ),
                    );
                  }
                  final s = snapshot.data ??
                      _AnalyticsSnapshot.empty(
                          periodLabel: _periodLabel(_period));

                  return LayoutBuilder(
                    builder: (context, constraints) {
                      final wide = constraints.maxWidth >= 960;
                      return SingleChildScrollView(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              children: [
                                _KpiTile(
                                  width: wide ? 200 : double.infinity,
                                  label: 'Orders',
                                  value: '${s.totalOrders}',
                                  icon: Icons.receipt_long,
                                  color: scheme.primary,
                                ),
                                _KpiTile(
                                  width: wide ? 200 : double.infinity,
                                  label: 'Revenue',
                                  value: money.format(s.totalRevenue),
                                  icon: Icons.attach_money,
                                  color: scheme.primary,
                                ),
                                _KpiTile(
                                  width: wide ? 200 : double.infinity,
                                  label: 'AOV',
                                  value: money.format(s.averageOrderValue),
                                  icon: Icons.shopping_bag_outlined,
                                  color: scheme.primary,
                                ),
                                _KpiTile(
                                  width: wide ? 200 : double.infinity,
                                  label: 'Customers',
                                  value: '${s.uniqueCustomers}',
                                  icon: Icons.people_outline,
                                  color: scheme.primary,
                                ),
                                _KpiTile(
                                  width: wide ? 200 : double.infinity,
                                  label: 'Cancelled',
                                  value: '${s.cancelledOrders}',
                                  icon: Icons.cancel_outlined,
                                  color: scheme.error,
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: wide ? 280 : 520,
                              child: Flex(
                                direction:
                                    wide ? Axis.horizontal : Axis.vertical,
                                children: [
                                  Expanded(
                                    flex: 3,
                                    child: _ChartCard(
                                      title: 'Orders over time',
                                      child: _OrdersBarChart(series: s.series),
                                    ),
                                  ),
                                  SizedBox(
                                      width: wide ? 12 : 0,
                                      height: wide ? 0 : 12),
                                  Expanded(
                                    flex: 2,
                                    child: _ChartCard(
                                      title: 'Revenue over time',
                                      child:
                                          _RevenueLineChart(series: s.series),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 16),
                            SizedBox(
                              height: wide ? 260 : 520,
                              child: Flex(
                                direction:
                                    wide ? Axis.horizontal : Axis.vertical,
                                children: [
                                  Expanded(
                                    child: _ChartCard(
                                      title: 'Channel (source)',
                                      child: _BreakdownList(
                                        data: s.bySource,
                                        total: s.totalOrders,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      width: wide ? 12 : 0,
                                      height: wide ? 0 : 12),
                                  Expanded(
                                    child: _ChartCard(
                                      title: 'Fulfillment type',
                                      child: _BreakdownList(
                                        data: s.byFulfillment,
                                        total: s.totalOrders,
                                      ),
                                    ),
                                  ),
                                  SizedBox(
                                      width: wide ? 12 : 0,
                                      height: wide ? 0 : 12),
                                  Expanded(
                                    child: _ChartCard(
                                      title: 'Top items',
                                      child: _TopItemsList(items: s.topItems),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Generated ${DateFormat.yMMMd().add_jm().format(s.generatedAt)} · ${s.periodLabel}',
                              style: Theme.of(context)
                                  .textTheme
                                  .bodySmall
                                  ?.copyWith(
                                    color: scheme.onSurface.withOpacity(0.45),
                                  ),
                            ),
                          ],
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
    );
  }
}

class _AnalyticsSnapshot {
  final String periodLabel;
  final int totalOrders;
  final int cancelledOrders;
  final double totalRevenue;
  final double averageOrderValue;
  final int uniqueCustomers;
  final Map<String, int> bySource;
  final Map<String, int> byFulfillment;
  final List<_DayPoint> series;
  final List<_RankedItem> topItems;
  final DateTime generatedAt;

  const _AnalyticsSnapshot({
    required this.periodLabel,
    required this.totalOrders,
    required this.cancelledOrders,
    required this.totalRevenue,
    required this.averageOrderValue,
    required this.uniqueCustomers,
    required this.bySource,
    required this.byFulfillment,
    required this.series,
    required this.topItems,
    required this.generatedAt,
  });

  factory _AnalyticsSnapshot.empty({required String periodLabel}) {
    return _AnalyticsSnapshot(
      periodLabel: periodLabel,
      totalOrders: 0,
      cancelledOrders: 0,
      totalRevenue: 0,
      averageOrderValue: 0,
      uniqueCustomers: 0,
      bySource: const {},
      byFulfillment: const {},
      series: const [],
      topItems: const [],
      generatedAt: DateTime.now(),
    );
  }
}

class _DayPoint {
  final DateTime day;
  final int orders;
  final double revenue;

  const _DayPoint({
    required this.day,
    required this.orders,
    required this.revenue,
  });

  _DayPoint copyWith({int? orders, double? revenue}) => _DayPoint(
        day: day,
        orders: orders ?? this.orders,
        revenue: revenue ?? this.revenue,
      );
}

class _RankedItem {
  final String name;
  final int quantity;

  const _RankedItem({required this.name, required this.quantity});
}

class _KpiTile extends StatelessWidget {
  final double width;
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _KpiTile({
    required this.width,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: width == double.infinity ? null : width,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label, style: Theme.of(context).textTheme.bodySmall),
                    const SizedBox(height: 2),
                    Text(
                      value,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChartCard extends StatelessWidget {
  final String title;
  final Widget child;

  const _ChartCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleSmall),
            const SizedBox(height: 8),
            Expanded(child: child),
          ],
        ),
      ),
    );
  }
}

class _OrdersBarChart extends StatelessWidget {
  final List<_DayPoint> series;

  const _OrdersBarChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (series.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final maxY = series.fold<int>(0, (m, p) => p.orders > m ? p.orders : m);
    final chartMax = (maxY < 4 ? 4 : maxY).toDouble();
    final label = DateFormat('E');

    return BarChart(
      BarChartData(
        maxY: chartMax,
        minY: 0,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outlineVariant.withOpacity(0.45),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 28,
              getTitlesWidget: (v, m) {
                if (v != v.roundToDouble()) return const SizedBox.shrink();
                return Text('${v.toInt()}',
                    style: TextStyle(
                        fontSize: 10,
                        color: scheme.onSurface.withOpacity(0.55)));
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: series.length > 14 ? 2 : 1,
              getTitlesWidget: (v, m) {
                final i = v.toInt();
                if (i < 0 || i >= series.length) return const SizedBox.shrink();
                if (series.length > 14 && i % 2 != 0) {
                  return const SizedBox.shrink();
                }
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    label.format(series[i].day),
                    style: TextStyle(
                        fontSize: 9, color: scheme.onSurface.withOpacity(0.6)),
                  ),
                );
              },
            ),
          ),
        ),
        barGroups: [
          for (var i = 0; i < series.length; i++)
            BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: series[i].orders.toDouble(),
                  width: series.length > 20 ? 6 : 12,
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(3)),
                  color: scheme.primary,
                ),
              ],
            ),
        ],
      ),
    );
  }
}

class _RevenueLineChart extends StatelessWidget {
  final List<_DayPoint> series;

  const _RevenueLineChart({required this.series});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (series.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final maxY =
        series.fold<double>(0, (m, p) => p.revenue > m ? p.revenue : m);
    final chartMax = maxY < 10 ? 10.0 : maxY * 1.1;

    return LineChart(
      LineChartData(
        minX: 0,
        maxX: (series.length - 1).toDouble(),
        minY: 0,
        maxY: chartMax,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (v) => FlLine(
            color: scheme.outlineVariant.withOpacity(0.45),
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        titlesData: FlTitlesData(
          topTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles:
              const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 36,
              getTitlesWidget: (v, m) => Text(
                v >= 1000
                    ? '${(v / 1000).toStringAsFixed(1)}k'
                    : v.toInt().toString(),
                style: TextStyle(
                    fontSize: 9, color: scheme.onSurface.withOpacity(0.55)),
              ),
            ),
          ),
          bottomTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: [
              for (var i = 0; i < series.length; i++)
                FlSpot(i.toDouble(), series[i].revenue),
            ],
            isCurved: true,
            color: scheme.primary,
            barWidth: 3,
            dotData: FlDotData(show: series.length <= 14),
            belowBarData: BarAreaData(
              show: true,
              color: scheme.primary.withOpacity(0.12),
            ),
          ),
        ],
      ),
    );
  }
}

class _BreakdownList extends StatelessWidget {
  final Map<String, int> data;
  final int total;

  const _BreakdownList({required this.data, required this.total});

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) {
      return const Center(child: Text('No data'));
    }
    final entries = data.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      itemCount: entries.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final e = entries[i];
        final frac = total <= 0 ? 0.0 : e.value / total;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    e.key,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
                Text(
                  '${e.value} (${(frac * 100).toStringAsFixed(0)}%)',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w600),
                ),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: frac.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: scheme.primary.withOpacity(0.12),
                color: scheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _TopItemsList extends StatelessWidget {
  final List<_RankedItem> items;

  const _TopItemsList({required this.items});

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return const Center(child: Text('No item sales'));
    }
    final maxQty = items.first.quantity.toDouble();
    final scheme = Theme.of(context).colorScheme;

    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (context, i) {
        final row = items[i];
        final frac = maxQty <= 0 ? 0.0 : row.quantity / maxQty;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Text('${i + 1}. ',
                    style: TextStyle(color: scheme.onSurface.withOpacity(0.5))),
                Expanded(
                  child: Text(
                    row.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Text('${row.quantity}',
                    style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 4),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: frac.clamp(0.0, 1.0),
                minHeight: 6,
                backgroundColor: scheme.primary.withOpacity(0.12),
                color: scheme.primary,
              ),
            ),
          ],
        );
      },
    );
  }
}
