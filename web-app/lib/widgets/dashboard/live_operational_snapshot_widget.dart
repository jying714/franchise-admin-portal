import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;

class LiveOperationalSnapshotWidget extends StatelessWidget {
  final String franchiseId;
  final bool expanded;

  const LiveOperationalSnapshotWidget({
    Key? key,
    required this.franchiseId,
    required this.expanded,
  }) : super(key: key);

  /// Live orders for ops board. Prefer status filter aligned with real writes;
  /// fall back handled in metrics if docs arrive with other statuses.
  Stream<QuerySnapshot<Map<String, dynamic>>> _liveOpsStream() {
    if (franchiseId.isEmpty ||
        franchiseId == 'unknown' ||
        franchiseId == 'test' ||
        franchiseId == 'default') {
      return const Stream.empty();
    }
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .orderBy('timestamp', descending: true)
        .limit(150)
        .snapshots();
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
      for (final key in [
        'paid',
        'created',
        'sent_to_kitchen',
        'open',
        'completed',
      ]) {
        final t = _asDateTime(tsMap[key]);
        if (t != null) return t;
      }
    }
    return _asDateTime(data['createdAt']);
  }

  String _statusOf(Map<String, dynamic> data) {
    return (data['status'] as String?)?.toLowerCase().trim() ?? '';
  }

  bool _isKitchen(String status) =>
      status == 'sent_to_kitchen' || status == 'in_kitchen';

  bool _isOpenBoard(String status) =>
      status == 'open' ||
      status == 'sent_to_kitchen' ||
      status == 'in_kitchen' ||
      status == 'placed';

  bool _isCompleted(String status) =>
      status == 'completed' || status == 'closed';

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _liveOpsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          shared.ErrorLogger.log(
            message: 'Live ops snapshot stream error',
            stack: snapshot.error.toString(),
            source: 'LiveOperationalSnapshotWidget',
            severity: 'error',
            contextData: {'franchiseId': franchiseId},
          );
          return Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Live metrics unavailable',
                style: TextStyle(color: Theme.of(context).colorScheme.error),
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final now = DateTime.now();
        final oneHourAgo = now.subtract(const Duration(hours: 1));
        final todayStart = DateTime(now.year, now.month, now.day);

        var activeOrders = 0;
        var recentOrders = 0;
        var kitchenTickets = 0;
        var kitchenLoad = 0;
        var todayRevenue = 0.0;
        final fulfillmentMinutes = <int>[];

        for (final doc in docs) {
          final data = doc.data();
          final status = _statusOf(data);
          final ts = _orderTime(data);

          if (_isOpenBoard(status)) {
            activeOrders++;
          }
          if (_isKitchen(status)) {
            kitchenTickets++;
            final items = data['items'];
            if (items is List) {
              kitchenLoad += items.length;
            }
          }
          if (ts != null && ts.isAfter(oneHourAgo)) {
            recentOrders++;
          }
          if (ts != null &&
              !ts.isBefore(todayStart) &&
              (_isCompleted(status) ||
                  data['paidAt'] != null ||
                  (data['timestamps'] is Map &&
                      (data['timestamps'] as Map)['paid'] != null))) {
            final total = data['total'];
            if (total is num) {
              todayRevenue += total.toDouble();
            }
          }

          if (_isCompleted(status)) {
            final created = ts;
            DateTime? completed = _asDateTime(data['completedAt']);
            final tsMap = data['timestamps'];
            if (completed == null && tsMap is Map) {
              completed =
                  _asDateTime(tsMap['completed']) ?? _asDateTime(tsMap['paid']);
            }
            if (created != null && completed != null) {
              final mins = completed.difference(created).inMinutes;
              if (mins >= 0 && mins < 24 * 60) {
                fulfillmentMinutes.add(mins);
              }
            }
          }
        }

        final avgFulfillmentTime = fulfillmentMinutes.isEmpty
            ? 0.0
            : fulfillmentMinutes.reduce((a, b) => a + b) /
                fulfillmentMinutes.length;

        if (expanded) {
          return GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.4,
            children: [
              _metricCard('Active Orders', activeOrders.toString(),
                  Icons.shopping_cart),
              _metricCard('Orders (Last Hour)', recentOrders.toString(),
                  Icons.access_time),
              _metricCard(
                  'Kitchen Tickets', kitchenTickets.toString(), Icons.kitchen),
              _metricCard(
                  'Kitchen Load', kitchenLoad.toString(), Icons.restaurant),
              _metricCard('Revenue Today',
                  '\$${todayRevenue.toStringAsFixed(2)}', Icons.attach_money),
              _metricCard('Avg Fulfillment (min)',
                  avgFulfillmentTime.toStringAsFixed(1), Icons.timer),
            ],
          );
        }

        return Card(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _metricCard(
                    'Active', activeOrders.toString(), Icons.shopping_cart,
                    compact: true),
                _metricCard('1h', recentOrders.toString(), Icons.access_time,
                    compact: true),
                _metricCard('Kitchen', kitchenTickets.toString(), Icons.kitchen,
                    compact: true),
                _metricCard('Rev', '\$${todayRevenue.toStringAsFixed(0)}',
                    Icons.attach_money,
                    compact: true),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _metricCard(String title, String value, IconData icon,
      {bool compact = false}) {
    return Card(
      elevation: compact ? 0 : 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 20 : 28, color: Colors.blueGrey),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: compact ? 14 : 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              title,
              style: TextStyle(
                fontSize: compact ? 10 : 12,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
