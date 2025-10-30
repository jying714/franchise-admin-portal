// File: lib/admin/dashboard/widgets/live_operational_snapshot_widget.dart
//
// PURPOSE:
// Displays real-time operational metrics for the currently selected franchise.
// Controlled by the `liveSnapshotEnabled` flag in `FranchiseFeatureProvider`.
// Data is streamed from Firestore in near real time.
//
// AUTHOR:
// Auto-generated with production-readiness, logging, and maintainability in mind.
//
// DEPENDENCIES:
// - franchise_provider.dart (for franchiseId context)
// - error_logger.dart (for robust logging)
// - cloud_firestore.dart
// - provider.dart (for context.watch)

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class LiveOperationalSnapshotWidget extends StatelessWidget {
  final String franchiseId;
  final bool expanded; // Controls layout size

  const LiveOperationalSnapshotWidget({
    Key? key,
    required this.franchiseId,
    required this.expanded,
  }) : super(key: key);

  /// Firestore stream to watch active, completed, and in_kitchen orders
  Stream<QuerySnapshot<Map<String, dynamic>>> _liveOpsStream() {
    debugPrint(
        '[LiveOperationalSnapshotWidget] Starting stream for franchiseId: $franchiseId');
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('orders')
        .where('status',
            whereIn: ['active', 'completed', 'in_kitchen']).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: _liveOpsStream(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          // Check for index creation link in Firestore error
          final errorStr = snapshot.error.toString();
          if (errorStr.contains('FAILED_PRECONDITION') &&
              errorStr.contains('index')) {
            final linkMatch =
                RegExp(r'https:\/\/console\.firebase\.google\.com\/[^\s]+')
                    .firstMatch(errorStr);
            if (linkMatch != null) {
              debugPrint(
                  '[LiveOperationalSnapshotWidget] Firestore index required: ${linkMatch.group(0)}');
            }
          }

          // Log the error
          ErrorLogger.log(
            message: 'Live ops snapshot stream error',
            stack: snapshot.error.toString(),
            source: 'LiveOperationalSnapshotWidget',
            severity: 'error',
            screen: 'dashboard_home_screen.dart',
            contextData: {'franchiseId': franchiseId},
          );
          return const Text('Error loading live metrics.');
        }

        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        debugPrint(
            '[LiveOperationalSnapshotWidget] Received ${docs.length} order documents.');

        final now = DateTime.now();
        final oneHourAgo = now.subtract(const Duration(hours: 1));
        final todayStart = DateTime(now.year, now.month, now.day);

        try {
          // --- Metric calculations ---
          final activeOrders =
              docs.where((d) => d['status'] == 'active').length;

          final recentOrders = docs.where((d) {
            final ts = (d['createdAt'] as Timestamp?)?.toDate();
            return ts != null && ts.isAfter(oneHourAgo);
          }).length;

          final kitchenTickets =
              docs.where((d) => d['status'] == 'in_kitchen').length;

          final kitchenLoad = docs
              .where((d) => d['status'] == 'in_kitchen')
              .fold<int>(0, (sum, d) {
            final count =
                (d['items'] is List) ? (d['items'] as List).length : 0;
            return sum + count;
          });

          final todayRevenue = docs.where((d) {
            final ts = (d['createdAt'] as Timestamp?)?.toDate();
            return ts != null &&
                ts.isAfter(todayStart) &&
                d['status'] == 'completed';
          }).fold<double>(0.0, (sum, d) {
            final val = d['total'];
            return sum + ((val is num) ? val.toDouble() : 0.0);
          });

          final completedOrders = docs
              .where(
                  (d) => d['status'] == 'completed' && d['completedAt'] != null)
              .take(20)
              .map((d) {
            final created = (d['createdAt'] as Timestamp?)?.toDate() ?? now;
            final completed = (d['completedAt'] as Timestamp?)?.toDate() ?? now;
            return completed.difference(created).inMinutes;
          }).toList();

          final avgFulfillmentTime = completedOrders.isEmpty
              ? 0
              : completedOrders.reduce((a, b) => a + b) /
                  completedOrders.length;

          debugPrint('[LiveOperationalSnapshotWidget] Metrics → '
              'Active: $activeOrders, LastHour: $recentOrders, '
              'KitchenTickets: $kitchenTickets, KitchenLoad: $kitchenLoad, '
              'RevenueToday: $todayRevenue, AvgFulfillment: $avgFulfillmentTime');

          // Expanded → 2×3 grid
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
                _metricCard('Kitchen Tickets', kitchenTickets.toString(),
                    Icons.kitchen),
                _metricCard(
                    'Kitchen Load', kitchenLoad.toString(), Icons.restaurant),
                _metricCard('Revenue Today',
                    '\$${todayRevenue.toStringAsFixed(2)}', Icons.attach_money),
                _metricCard('Avg Fulfillment (min)',
                    avgFulfillmentTime.toStringAsFixed(1), Icons.timer),
              ],
            );
          }

          // Collapsed → single compact row
          return Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              _metricCard(
                  'Active', activeOrders.toString(), Icons.shopping_cart,
                  compact: true),
              _metricCard('1h', recentOrders.toString(), Icons.access_time,
                  compact: true),
              _metricCard('Rev', '\$${todayRevenue.toStringAsFixed(0)}',
                  Icons.attach_money,
                  compact: true),
            ],
          );
        } catch (e, st) {
          ErrorLogger.log(
            message: 'Error calculating live ops metrics',
            stack: st.toString(),
            source: 'LiveOperationalSnapshotWidget',
            severity: 'error',
            screen: 'dashboard_home_screen.dart',
            contextData: {'franchiseId': franchiseId, 'docCount': docs.length},
          );
          return const Text('Error calculating metrics.');
        }
      },
    );
  }

  /// Reusable metric card
  Widget _metricCard(String title, String value, IconData icon,
      {bool compact = false}) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: compact ? 20 : 28, color: Colors.blueGrey),
            const SizedBox(height: 4),
            Text(value,
                style: TextStyle(
                    fontSize: compact ? 14 : 20, fontWeight: FontWeight.bold)),
            const SizedBox(height: 2),
            Text(title,
                style:
                    TextStyle(fontSize: compact ? 10 : 12, color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
