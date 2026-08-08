// File: lib/admin/dashboard/dashboard_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/
import 'package:franchise_admin_portal/widgets/financials/orders_stat_card.dart';
import 'package:franchise_admin_portal/widgets/financials/revenue_stat_card.dart';
import 'package:franchise_admin_portal/widgets/financials/kpi_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/analytics_placeholder_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/orders_over_time_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/activity_feed_widget.dart';
import 'package:franchise_admin_portal/widgets/dashboard/urgent_status_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/notifications_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/widgets/admin/role_guard_widget.dart';
import 'package:franchise_admin_portal/widgets/dashboard/live_operational_snapshot_widget.dart';
import 'package:franchise_admin_portal/widgets/dashboard/top_menu_items_card.dart';

/// ---------------------------------------------------------------------------
/// ðŸ–¥ï¸ DashboardHomeScreen
/// ---------------------------------------------------------------------------
/// Main admin dashboard landing page.
/// Shows KPIs, revenue stats, notifications, live operational snapshot,
/// analytics, urgent alerts, and activity feed.
/// ---------------------------------------------------------------------------

class DashboardHomeScreen extends StatefulWidget {
  const DashboardHomeScreen({Key? key}) : super(key: key);

  @override
  State<DashboardHomeScreen> createState() => _DashboardHomeScreenState();
}

class _DashboardHomeScreenState extends State<DashboardHomeScreen> {
  bool _expandedSnapshot = false; // Tracks expanded/collapsed state

  @override
  Widget build(BuildContext context) {
    final franchiseProvider = context.watch<shared.FranchiseProvider>();
    final franchiseId = franchiseProvider.franchiseId ?? 'test';
    final featureProvider = context.watch<shared.FranchiseFeatureProvider>();

    if (!featureProvider.isInitialized) {
      debugPrint(
          '[DashboardHomeScreen] Forcing feature provider initialization...');
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        if (!mounted) return;
        try {
          await featureProvider.initialize();
          if (franchiseId.isNotEmpty && franchiseId != 'unknown') {
            await featureProvider.loadLiveSnapshotFlag(franchiseId);
          }
          if (mounted) setState(() {});
        } catch (e, st) {
          shared.ErrorLogger.log(
            message: 'DashboardHomeScreen feature init failed',
            source: 'DashboardHomeScreen',
            severity: 'error',
            stack: st.toString(),
            contextData: {'franchiseId': franchiseId},
          );
          if (mounted) setState(() {});
        }
      });

      return const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading dashboard features...',
                style: TextStyle(fontSize: 16)),
          ],
        ),
      );
    }

    final liveSnapshotEnabled = featureProvider.liveSnapshotEnabled;
    final adminUser =
        Provider.of<shared.AdminUserProvider>(context, listen: false).user;
    final userCanToggle =
        shared.UserPermissions.isPlatformPrivileged(adminUser) ||
            shared.UserPermissions.canManageSubscriptions(adminUser);

    final isMobile = MediaQuery.of(context).size.width < 800;
    final gridColumns = isMobile ? 1 : 4;
    final gap = isMobile ? 16.0 : 24.0;

    return Padding(
      padding: EdgeInsets.all(gap),
      child: SingleChildScrollView(
        child: Column(
          children: [
            Wrap(
              spacing: gap,
              runSpacing: gap,
              children: [
                SizedBox(
                  width: isMobile ? double.infinity : 290,
                  child: OrdersStatCard(franchiseId: franchiseId),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 290,
                  child: RevenueStatCard(franchiseId: franchiseId),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 290,
                  child: StreamBuilder<List<shared.Promo>>(
                    stream: Provider.of<shared.FirestoreService>(
                      context,
                      listen: false,
                    ).getPromos(franchiseId),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const KpiCard(
                          title: 'Active Promotions',
                          value: '--',
                          loading: true,
                          icon: Icons.local_offer_outlined,
                        );
                      }
                      if (snapshot.hasError) {
                        return const KpiCard(
                          title: 'Active Promotions',
                          value: '—',
                          loading: false,
                          icon: Icons.local_offer_outlined,
                        );
                      }
                      final promos = snapshot.data ?? const <shared.Promo>[];
                      final now = DateTime.now();
                      final activeCount = promos.where((p) {
                        if (!p.active) return false;
                        // Inclusive window: started and not past end.
                        if (p.endDate.isBefore(now)) return false;
                        if (p.startDate.isAfter(now)) return false;
                        return true;
                      }).length;
                      return KpiCard(
                        title: 'Active Promotions',
                        value: '$activeCount',
                        loading: false,
                        icon: Icons.local_offer_outlined,
                      );
                    },
                  ),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 290,
                  child: const NotificationsPanel(),
                ),

                // Live Ops Snapshot — now safely wrapped
                if (liveSnapshotEnabled || userCanToggle)
                  SizedBox(
                    width: isMobile
                        ? double.infinity
                        : (_expandedSnapshot ? 600 : 290),
                    child: RoleGuard(
                      requireAnyRole: ['platform_owner', 'hq_owner'],
                      featureName: 'real_time_ops_snapshot',
                      child: LiveOperationalSnapshotWidget(
                        franchiseId: franchiseId,
                        expanded: _expandedSnapshot,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: gap),

            // Second row
            SizedBox(
              height: isMobile ? 780 : 270,
              child: GridView.count(
                crossAxisCount: gridColumns,
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
                childAspectRatio: isMobile ? 1.8 : 2.5,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  OrdersOverTimeCard(franchiseId: franchiseId),
                  TopMenuItemsCard(franchiseId: franchiseId),
                  const UrgentStatusCard(),
                  const ActivityFeedWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
