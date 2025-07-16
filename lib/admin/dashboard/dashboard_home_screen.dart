import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/widgets/financials/kpi_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/analytics_placeholder_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/activity_feed_widget.dart';
import 'package:franchise_admin_portal/widgets/dashboard/urgent_status_card.dart';
import 'package:franchise_admin_portal/widgets/dashboard/notifications_panel.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/widgets/financials/dashboard_stat_card.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/widgets/financials/revenue_stat_card.dart';
import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';

class DashboardHomeScreen extends StatelessWidget {
  const DashboardHomeScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final isMobile = MediaQuery.of(context).size.width < 800;
    // Responsive grid: 2 columns mobile, 4 desktop.
    final gridColumns = isMobile ? 1 : 4;
    final gap = isMobile ? 16.0 : 24.0;
    return Padding(
      padding: EdgeInsets.all(gap),
      child: SingleChildScrollView(
        child: Column(
          children: [
            // First row: KPIs and Notifications
            GridView.count(
              crossAxisCount: gridColumns,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: 2.3,
              children: [
                DashboardStatCard(
                  label: 'Orders Today',
                  icon: Icons.shopping_cart,
                  getValue: () => context
                      .read<FirestoreService>()
                      .getTotalOrdersTodayCount(franchiseId: franchiseId),
                  tooltip: 'Total orders placed today',
                  semanticLabel: 'Total orders placed today',
                ),
                RevenueStatCard(franchiseId: franchiseId),
                KpiCard(title: "Active Promotions", value: "--", loading: true),
                NotificationsPanel(),
              ],
            ),
            SizedBox(height: gap),
            // Second row: Analytics, Urgent, Activity Feed
            GridView.count(
              crossAxisCount: gridColumns,
              shrinkWrap: true,
              physics: NeverScrollableScrollPhysics(),
              crossAxisSpacing: gap,
              mainAxisSpacing: gap,
              childAspectRatio: isMobile ? 1.8 : 2.5,
              children: const [
                AnalyticsPlaceholderCard(title: "Orders Over Time"),
                AnalyticsPlaceholderCard(title: "Top Menu Items"),
                UrgentStatusCard(),
                ActivityFeedWidget(),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
