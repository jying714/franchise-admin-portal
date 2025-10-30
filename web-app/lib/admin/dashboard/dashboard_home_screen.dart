// File: lib/admin/dashboard/dashboard_home_screen.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/providers/franchise_feature_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/utils/user_permissions.dart';
import 'package:franchise_admin_portal/widgets/financials/dashboard_stat_card.dart';
import 'package:franchise_admin_portal/widgets/financials/revenue_stat_card.dart';
import 'package:franchise_admin_portal/widgets/financials/kpi_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/analytics_placeholder_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/activity_feed_widget.dart';
import 'package:franchise_admin_portal/widgets/dashboard/urgent_status_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/notifications_panel.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/providers/role_guard.dart';
import 'package:franchise_admin_portal/widgets/dashboard/live_operational_snapshot_widget.dart';

/// ---------------------------------------------------------------------------
/// 🖥️ DashboardHomeScreen
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
    debugPrint('[DashboardHomeScreen] Building dashboard UI');

    final franchiseId = context.watch<FranchiseProvider>().franchiseId;
    final featureProvider = context.watch<FranchiseFeatureProvider>();
    final isMobile = MediaQuery.of(context).size.width < 800;
    final gridColumns = isMobile ? 1 : 4;
    final gap = isMobile ? 16.0 : 24.0;

    if (!featureProvider.isInitialized) {
      debugPrint('[DashboardHomeScreen] Waiting for featureProvider init...');
      return const Center(child: CircularProgressIndicator());
    }

    final liveSnapshotEnabled = featureProvider.liveSnapshotEnabled;
    final userCanToggle = UserPermissions.isPlatformPrivileged(
          context.read<AdminUserProvider>().user,
        ) ||
        UserPermissions.canManageSubscriptions(
          context.read<AdminUserProvider>().user,
        );

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
                  child: DashboardStatCard(
                    label: 'Orders Today',
                    icon: Icons.shopping_cart,
                    getValue: () => context
                        .read<FirestoreService>()
                        .getTotalOrdersTodayCount(franchiseId: franchiseId),
                    tooltip: 'Total orders placed today',
                    semanticLabel: 'Total orders placed today',
                  ),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 290,
                  child: RevenueStatCard(franchiseId: franchiseId),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 290,
                  child: const KpiCard(
                      title: "Active Promotions", value: "--", loading: true),
                ),
                SizedBox(
                  width: isMobile ? double.infinity : 290,
                  child: const NotificationsPanel(),
                ),

                // 📡 Real-Time Ops Snapshot
                // 📡 Real-Time Ops Snapshot
                if (liveSnapshotEnabled || userCanToggle)
                  Container(
                    width: isMobile
                        ? double.infinity
                        : (_expandedSnapshot ? (290 * 2 + gap) : 290),
                    height: _expandedSnapshot
                        ? (3 * 120 + 2 * 12) // 3 rows + 2 gaps in expanded mode
                        : null, // auto height when collapsed
                    child: RoleGuard(
                      requireAnyRole: ['platform_owner', 'hq_owner'],
                      featureName: 'real_time_ops_snapshot',
                      screen: 'dashboard_home_screen.dart',
                      child: Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Real-Time Ops Snapshot',
                                    style:
                                        Theme.of(context).textTheme.titleMedium,
                                  ),
                                  Row(
                                    children: [
                                      IconButton(
                                        icon: Icon(_expandedSnapshot
                                            ? Icons.expand_less
                                            : Icons.expand_more),
                                        tooltip: _expandedSnapshot
                                            ? 'Collapse view'
                                            : 'Expand view',
                                        onPressed: () {
                                          setState(() {
                                            _expandedSnapshot =
                                                !_expandedSnapshot;
                                          });
                                        },
                                      ),
                                      if (userCanToggle)
                                        Switch(
                                          value: liveSnapshotEnabled,
                                          onChanged: (value) async {
                                            try {
                                              featureProvider
                                                  .setLiveSnapshotEnabled(
                                                      value);
                                              final saved =
                                                  await featureProvider
                                                      .persistToFirestore();
                                              debugPrint(
                                                  '[DashboardHomeScreen] liveSnapshotEnabled persisted: $saved');
                                              if (!saved) {
                                                ScaffoldMessenger.of(context)
                                                    .showSnackBar(
                                                  const SnackBar(
                                                    content: Text(
                                                        'Failed to save snapshot setting.'),
                                                  ),
                                                );
                                              }
                                            } catch (e, st) {
                                              await ErrorLogger.log(
                                                message:
                                                    'Error updating liveSnapshotEnabled',
                                                stack: st.toString(),
                                                source:
                                                    'DashboardHomeScreen.onChanged',
                                                severity: 'error',
                                                screen:
                                                    'dashboard_home_screen.dart',
                                                contextData: {
                                                  'franchiseId': franchiseId,
                                                  'newValue': value,
                                                },
                                              );
                                            }
                                          },
                                        ),
                                    ],
                                  ),
                                ],
                              ),
                              const SizedBox(height: 12),
                              if (liveSnapshotEnabled)
                                Expanded(
                                  // ✅ Fill vertical space when expanded
                                  child: LiveOperationalSnapshotWidget(
                                    franchiseId: franchiseId,
                                    expanded: _expandedSnapshot,
                                  ),
                                )
                              else
                                Text(
                                  'Disabled — enable to view live operational metrics.',
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: gap),

            // Second row: Analytics, Urgent, Activity Feed
            SizedBox(
              height: isMobile ? 780 : 270,
              child: GridView.count(
                crossAxisCount: gridColumns,
                crossAxisSpacing: gap,
                mainAxisSpacing: gap,
                childAspectRatio: isMobile ? 1.8 : 2.5,
                physics: const NeverScrollableScrollPhysics(),
                children: const [
                  AnalyticsPlaceholderCard(title: "Orders Over Time"),
                  AnalyticsPlaceholderCard(title: "Top Menu Items"),
                  UrgentStatusCard(),
                  ActivityFeedWidget(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
