import 'package:franchise_admin_portal/widgets/user_profile_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/services/analytics_service.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/analytics_summary.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';
import 'export_analytics_dialog.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:franchise_admin_portal/core/models/export_utils.dart';
import 'package:franchise_admin_portal/core/providers/franchise_provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final userProfileNotifier = Provider.of<UserProfileNotifier>(context);
    final userRoles = userProfileNotifier.user?.roles ?? <String>[];

    final franchiseId =
        Provider.of<FranchiseProvider>(context, listen: false).franchiseId;
    final analyticsService =
        Provider.of<AnalyticsService>(context, listen: false);
    final firestoreService =
        Provider.of<FirestoreService>(context, listen: false);

    return Scaffold(
      backgroundColor: Colors.white,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Main content column
          Expanded(
            flex: 11,
            child: Padding(
              padding:
                  const EdgeInsets.only(top: 24.0, left: 24.0, right: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header row
                  Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const Text(
                          "Analytics Dashboard",
                          style: TextStyle(
                            color: Colors.black,
                            fontWeight: FontWeight.bold,
                            fontSize: 22,
                          ),
                        ),

                        // Run Rollup Button (visible only for admin/owner/developer)
                        Builder(
                          builder: (context) {
                            final firestoreService =
                                Provider.of<FirestoreService>(context,
                                    listen: false);
                            final franchiseId = Provider.of<FranchiseProvider>(
                                    context,
                                    listen: false)
                                .franchiseId;
                            final analyticsService =
                                Provider.of<AnalyticsService>(context,
                                    listen: false);
                            final userRoles = Provider.of<UserProfileNotifier>(
                                        context,
                                        listen: false)
                                    .user
                                    ?.roles ??
                                <String>[];

                            const allowedRoles = {
                              'admin',
                              'owner',
                              'developer'
                            };
                            if (!userRoles
                                .any((role) => allowedRoles.contains(role))) {
                              return const SizedBox.shrink();
                            }

                            return Padding(
                              padding:
                                  const EdgeInsets.only(left: 12.0, right: 8.0),
                              child: ElevatedButton.icon(
                                icon: const Icon(Icons.refresh, size: 20),
                                label: const Text("Run Rollup Now"),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: DesignTokens.primaryColor,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 8),
                                  textStyle: const TextStyle(
                                      fontWeight: FontWeight.w600),
                                ),
                                onPressed: () async {
                                  try {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Running analytics rollup...")),
                                    );

                                    await analyticsService
                                        .runManualRollup(franchiseId);

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                          content: Text(
                                              "Analytics rollup complete!")),
                                    );
                                  } catch (e) {
                                    ErrorLogger.log(
                                      message:
                                          'Error running manual rollup: $e',
                                      source: 'AnalyticsScreen',
                                      screen: 'ManualRollupButton',
                                      severity: 'error',
                                      stack: e.toString(),
                                      contextData: {'franchiseId': franchiseId},
                                    );

                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                          content: Text("Rollup failed: $e")),
                                    );
                                  }
                                },
                              ),
                            );
                          },
                        ),

                        const Spacer(),

                        // Export CSV IconButton
                        Builder(
                          builder: (context) {
                            final analyticsService =
                                Provider.of<AnalyticsService>(context,
                                    listen: false);
                            final franchiseId = Provider.of<FranchiseProvider>(
                                    context,
                                    listen: false)
                                .franchiseId;
                            if (franchiseId == 'unknown') {
                              return const Scaffold(
                                  body: Center(
                                      child: CircularProgressIndicator()));
                            }
                            return IconButton(
                              icon: const Icon(Icons.download_rounded,
                                  color: Colors.black87),
                              tooltip: "Export Current Summary (CSV)",
                              onPressed: () async {
                                if (_selectedPeriod == null) return;
                                final summaries = await analyticsService
                                    .getAnalyticsSummaries(franchiseId);
                                final current = summaries.firstWhere(
                                  (s) => s.period == _selectedPeriod,
                                  orElse: () => summaries.first,
                                );
                                if (current == null) return;
                                showDialog(
                                  context: context,
                                  builder: (_) =>
                                      ExportAnalyticsDialogSingleSummary(
                                          summary: current),
                                );
                              },
                            );
                          },
                        ),
                      ],
                    ),
                  ),

                  // Analytics Content
                  Expanded(
                    child: StreamBuilder<List<AnalyticsSummary>>(
                      stream: analyticsService.getSummaryMetrics(franchiseId),
                      builder: (context, snapshot) {
                        // --- 1. Loading state ---
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingShimmerWidget();
                        }

                        // --- 2. Error fetching data ---
                        if (snapshot.hasError) {
                          ErrorLogger.log(
                            message: 'Error loading analytics data',
                            source: 'analytics_dashboard',
                            screen: 'AnalyticsScreen',
                            stack: snapshot.error?.toString(),
                            severity: 'error',
                            contextData: {'franchiseId': franchiseId},
                          );
                          return Center(
                              child: Text(
                                  'Error loading analytics data. Please try again later.'));
                        }

                        final summaries = snapshot.data ?? [];

                        // --- 3. No analytics data at all ---
                        if (summaries.isEmpty) {
                          ErrorLogger.log(
                            message: 'No analytics data found for any period',
                            source: 'analytics_dashboard',
                            screen: 'AnalyticsScreen',
                            severity: 'warning',
                            contextData: {'franchiseId': franchiseId},
                          );
                          return const Center(
                              child: Text(
                                  'No analytics data available for this period.'));
                        }

                        // --- 4. Prepare selected period and summary ---
                        final sorted = List<AnalyticsSummary>.from(summaries)
                          ..sort((a, b) => b.period.compareTo(a.period));
                        final periods =
                            sorted.map((s) => s.period).toSet().toList();
                        final selected = _selectedPeriod ??
                            (periods.isNotEmpty ? periods.first : null);
                        AnalyticsSummary summary;
                        try {
                          summary = sorted.firstWhere(
                              (s) => s.period == selected,
                              orElse: () => sorted.first);
                        } catch (e, stack) {
                          ErrorLogger.log(
                            message:
                                'Failed to find analytics summary for selected period',
                            source: 'analytics_dashboard',
                            screen: 'AnalyticsScreen',
                            severity: 'error',
                            stack: stack.toString(),
                            contextData: {
                              'franchiseId': franchiseId,
                              'selectedPeriod': selected,
                            },
                          );
                          return const Center(
                              child: Text(
                                  'Unable to load analytics for this period.'));
                        }

                        // --- 5. Check for missing feedback data ---
                        final hasFeedback = summary.feedbackStats != null;
                        if (!hasFeedback) {
                          ErrorLogger.log(
                            message:
                                'Missing feedbackStats in analytics summary',
                            source: 'feedback_stats_parse',
                            screen: 'AnalyticsScreen',
                            severity: 'warning',
                            contextData: {
                              'franchiseId': franchiseId,
                              'period': summary.period,
                            },
                          );
                        }

                        return Padding(
                          padding: const EdgeInsets.all(0),
                          child: Column(
                            children: [
                              // --- Period Dropdown ---
                              Row(
                                children: [
                                  const Text(
                                    "Period:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  const SizedBox(width: 16),
                                  DropdownButton<String>(
                                    value: selected,
                                    items: periods
                                        .map((p) => DropdownMenuItem<String>(
                                              value: p,
                                              child: Text(p),
                                            ))
                                        .toList(),
                                    onChanged: (val) {
                                      setState(() {
                                        _selectedPeriod = val;
                                      });
                                    },
                                  ),
                                ],
                              ),
                              const SizedBox(height: 24),

                              // --- SECTION HEADER: Order & Sales Analytics ---
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.center,
                                children: [
                                  Icon(Icons.bar_chart_rounded,
                                      color: DesignTokens.primaryColor,
                                      size: 28),
                                  const SizedBox(width: 10),
                                  Text(
                                    "Order & Sales Analytics",
                                    style: TextStyle(
                                      color: DesignTokens.primaryColor,
                                      fontWeight: FontWeight.w800,
                                      fontSize: 20,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                                ],
                              ),
                              Padding(
                                padding:
                                    const EdgeInsets.only(top: 4.0, bottom: 12),
                                child: Divider(
                                  color: DesignTokens.primaryColor
                                      .withOpacity(0.18),
                                  thickness: 2,
                                  height: 2,
                                ),
                              ),

                              // --- METRICS LIST ---
                              Expanded(
                                child: ListView(
                                  children: (() {
                                    // -------- Robustness Logic for Metrics --------
                                    final requiredFields = {
                                      'totalOrders': summary.totalOrders,
                                      'totalRevenue': summary.totalRevenue,
                                      'averageOrderValue':
                                          summary.averageOrderValue,
                                      'mostPopularItem':
                                          summary.mostPopularItem,
                                      'retentionRate': summary.retentionRate,
                                      'uniqueCustomers':
                                          summary.uniqueCustomers,
                                      'cancelledOrders':
                                          summary.cancelledOrders,
                                      'updatedAt': summary.updatedAt,
                                    };

                                    final missingMetrics = <String>[];
                                    requiredFields.forEach((key, value) {
                                      if (value == null) {
                                        missingMetrics.add(key);
                                        ErrorLogger.log(
                                          message:
                                              'Missing $key in analytics summary',
                                          source: 'analytics_dashboard',
                                          screen: 'AnalyticsScreen',
                                          severity: 'warning',
                                          contextData: {
                                            'franchiseId': franchiseId,
                                            'period': summary.period,
                                            'field': key,
                                          },
                                        );
                                      }
                                    });

                                    // If all metrics are missing/null, show a single card and return early.
                                    if (missingMetrics.length ==
                                        requiredFields.length) {
                                      return [
                                        Card(
                                          color: Colors.white,
                                          elevation: 2,
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: Center(
                                              child: Text(
                                                'Order & Sales Analytics not available for this period.',
                                                style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(height: 30),
                                        // --- SECTION HEADER: Customer Feedback ---
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.center,
                                          children: [
                                            Icon(Icons.reviews_rounded,
                                                color: Colors.amber[800],
                                                size: 28),
                                            const SizedBox(width: 10),
                                            const Text(
                                              "Customer Feedback",
                                              style: TextStyle(
                                                color: Colors.black87,
                                                fontWeight: FontWeight.w800,
                                                fontSize: 20,
                                                letterSpacing: 0.2,
                                              ),
                                            ),
                                          ],
                                        ),
                                        Padding(
                                          padding: const EdgeInsets.only(
                                              top: 4.0, bottom: 12),
                                          child: Divider(
                                            color: Colors.amber[700]!
                                                .withOpacity(0.15),
                                            thickness: 2,
                                            height: 2,
                                          ),
                                        ),
                                        if (hasFeedback)
                                          _buildFeedbackCard(summary)
                                        else
                                          Card(
                                            color: Colors.white,
                                            elevation: 2,
                                            margin: const EdgeInsets.symmetric(
                                                vertical: 6),
                                            shape: RoundedRectangleBorder(
                                              borderRadius:
                                                  BorderRadius.circular(14),
                                            ),
                                            child: Padding(
                                              padding:
                                                  const EdgeInsets.all(32.0),
                                              child: Center(
                                                child: Text(
                                                  'No customer feedback available for this period.',
                                                  style: TextStyle(
                                                      color: Colors.grey[700],
                                                      fontSize: 16),
                                                ),
                                              ),
                                            ),
                                          ),
                                      ];
                                    }

                                    // ----------- Main branch: show metrics tiles as normal -----------
                                    return [
                                      _buildMetricTile(
                                        "Total Orders",
                                        summary.totalOrders ?? "-",
                                        isMissing: missingMetrics
                                            .contains('totalOrders'),
                                      ),
                                      _buildMetricTile(
                                        "Total Revenue",
                                        summary.totalRevenue != null
                                            ? "\$${summary.totalRevenue.toStringAsFixed(2)}"
                                            : "-",
                                        isMissing: missingMetrics
                                            .contains('totalRevenue'),
                                      ),
                                      _buildMetricTile(
                                        "Average Order Value",
                                        summary.averageOrderValue != null
                                            ? "\$${summary.averageOrderValue.toStringAsFixed(2)}"
                                            : "-",
                                        isMissing: missingMetrics
                                            .contains('averageOrderValue'),
                                      ),
                                      _buildMetricTile(
                                        "Most Popular Item",
                                        summary.mostPopularItem ?? "-",
                                        isMissing: missingMetrics
                                            .contains('mostPopularItem'),
                                      ),
                                      _buildMetricTile(
                                        "Retention Rate",
                                        summary.retentionRate != null
                                            ? "${(summary.retentionRate * 100).toStringAsFixed(1)}%"
                                            : "-",
                                        isMissing: missingMetrics
                                            .contains('retentionRate'),
                                      ),
                                      _buildMetricTile(
                                        "Unique Customers",
                                        summary.uniqueCustomers ?? "-",
                                        isMissing: missingMetrics
                                            .contains('uniqueCustomers'),
                                      ),
                                      _buildMetricTile(
                                        "Cancelled Orders",
                                        summary.cancelledOrders ?? "-",
                                        isMissing: missingMetrics
                                            .contains('cancelledOrders'),
                                      ),
                                      _buildMetricTile(
                                        "Last Updated",
                                        summary.updatedAt?.toString() ?? "-",
                                        isMissing: missingMetrics
                                            .contains('updatedAt'),
                                      ),
                                      // --- Spacer between Analytics & Feedback
                                      const SizedBox(height: 30),
                                      // --- SECTION HEADER: Customer Feedback ---
                                      Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          Icon(Icons.reviews_rounded,
                                              color: Colors.amber[800],
                                              size: 28),
                                          const SizedBox(width: 10),
                                          const Text(
                                            "Customer Feedback",
                                            style: TextStyle(
                                              color: Colors.black87,
                                              fontWeight: FontWeight.w800,
                                              fontSize: 20,
                                              letterSpacing: 0.2,
                                            ),
                                          ),
                                        ],
                                      ),
                                      Padding(
                                        padding: const EdgeInsets.only(
                                            top: 4.0, bottom: 12),
                                        child: Divider(
                                          color: Colors.amber[700]!
                                              .withOpacity(0.15),
                                          thickness: 2,
                                          height: 2,
                                        ),
                                      ),
                                      if (hasFeedback)
                                        _buildFeedbackCard(summary)
                                      else
                                        Card(
                                          color: Colors.white,
                                          elevation: 2,
                                          margin: const EdgeInsets.symmetric(
                                              vertical: 6),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(14),
                                          ),
                                          child: Padding(
                                            padding: const EdgeInsets.all(32.0),
                                            child: Center(
                                              child: Text(
                                                'No customer feedback available for this period.',
                                                style: TextStyle(
                                                    color: Colors.grey[700],
                                                    fontSize: 16),
                                              ),
                                            ),
                                          ),
                                        ),
                                    ];
                                  })(),
                                ),
                              ),
                              // --- Export Button (visible on bottom for UX) ---
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  icon: const Icon(Icons.download_rounded),
                                  label: const Text('Export This Period (CSV)'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: DesignTokens.primaryColor,
                                    foregroundColor:
                                        DesignTokens.foregroundColor,
                                  ),
                                  onPressed: () {
                                    showDialog(
                                      context: context,
                                      builder: (_) =>
                                          ExportAnalyticsDialogSingleSummary(
                                        summary: summary,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
          // Right panel placeholder
          Expanded(
            flex: 9,
            child: Container(),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(String label, dynamic value,
      {bool isMissing = false}) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ListTile(
        title: Text(label),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(value?.toString() ?? "-"),
            if (isMissing)
              Tooltip(
                message: 'Missing data',
                child: Padding(
                  padding: const EdgeInsets.only(left: 4),
                  child:
                      Icon(Icons.info_outline, color: Colors.orange, size: 18),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(AnalyticsSummary summary) {
    return Card(
      color: Colors.white,
      elevation: 2,
      margin: const EdgeInsets.symmetric(vertical: 6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left accent bar
            Container(
              width: 5,
              decoration: BoxDecoration(
                color: DesignTokens.primaryColor.withOpacity(0.9),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(14),
                  bottomLeft: Radius.circular(14),
                ),
              ),
            ),
            // Feedback content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // --- Feedback Block Header ---
                    Wrap(
                      spacing: 16,
                      runSpacing: 8,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.star_rounded,
                                color: Colors.amber[700], size: 22),
                            const SizedBox(width: 6),
                            Text(
                              "Overall Avg: ",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              summary.feedbackStats?['averageStarRating'] !=
                                      null
                                  ? (summary.feedbackStats!['averageStarRating']
                                          as num)
                                      .toStringAsFixed(2)
                                  : "-",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: DesignTokens.primaryColor,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.people_alt_rounded,
                                color: Colors.blueGrey[700], size: 20),
                            const SizedBox(width: 4),
                            Text(
                              "Feedbacks: ",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              summary.feedbackStats?['totalFeedbacks']
                                      ?.toString() ??
                                  "-",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              "Participation Rate: ",
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                            Text(
                              summary.feedbackStats?['participationRate'] !=
                                      null
                                  ? "${(summary.feedbackStats!['participationRate'] * 100).toStringAsFixed(1)}%"
                                  : "-",
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15,
                                color: Colors.black87,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    const Divider(height: 16),
                    // --- Order Feedback ---
                    if (summary.feedbackStats?['orderFeedback'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.fastfood_rounded,
                              color: Colors.red[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "Order Feedback (meals, delivery)",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const Spacer(),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(
                            summary.feedbackStats?['orderFeedback']
                                        ?['avgStarRating'] !=
                                    null
                                ? (summary.feedbackStats!['orderFeedback']
                                        ['avgStarRating'] as num)
                                    .toStringAsFixed(2)
                                : "-",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (summary.feedbackStats?['orderFeedback']?['count'] !=
                          null)
                        Padding(
                          padding: const EdgeInsets.only(left: 28.0),
                          child: Text(
                            "Count: ${summary.feedbackStats!['orderFeedback']!['count']}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (summary.feedbackStats?['orderFeedback']
                              ?['avgCategories'] !=
                          null)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 28.0, top: 6, bottom: 10),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (summary.feedbackStats!['orderFeedback']
                                    ['avgCategories'] as Map)
                                .entries
                                .map<Widget>((entry) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 1),
                                      child: Row(
                                        children: [
                                          Icon(Icons.label_outline,
                                              size: 16, color: Colors.black38),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${entry.key}: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            entry.value != null
                                                ? (entry.value as num)
                                                    .toStringAsFixed(2)
                                                : "-",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: DesignTokens.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                      const Divider(height: 18),
                    ],
                    // --- App Feedback ---
                    if (summary.feedbackStats?['appFeedback'] != null) ...[
                      Row(
                        children: [
                          Icon(Icons.app_settings_alt_rounded,
                              color: Colors.green[700], size: 20),
                          const SizedBox(width: 8),
                          Text(
                            "App Feedback (ordering, UI)",
                            style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.black87),
                          ),
                          const Spacer(),
                          Icon(Icons.star, color: Colors.amber, size: 18),
                          Text(
                            summary.feedbackStats?['appFeedback']
                                        ?['avgStarRating'] !=
                                    null
                                ? (summary.feedbackStats!['appFeedback']
                                        ['avgStarRating'] as num)
                                    .toStringAsFixed(2)
                                : "-",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      if (summary.feedbackStats?['appFeedback']?['count'] !=
                          null)
                        Padding(
                          padding: const EdgeInsets.only(left: 28.0),
                          child: Text(
                            "Count: ${summary.feedbackStats!['appFeedback']!['count']}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ),
                      if (summary.feedbackStats?['appFeedback']
                              ?['avgCategories'] !=
                          null)
                        Padding(
                          padding: const EdgeInsets.only(
                              left: 28.0, top: 6, bottom: 2),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: (summary.feedbackStats!['appFeedback']
                                    ['avgCategories'] as Map)
                                .entries
                                .map<Widget>((entry) => Padding(
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 1),
                                      child: Row(
                                        children: [
                                          Icon(Icons.label_outline,
                                              size: 16, color: Colors.black38),
                                          const SizedBox(width: 6),
                                          Text(
                                            "${entry.key}: ",
                                            style: TextStyle(
                                              fontWeight: FontWeight.w500,
                                              fontSize: 14,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            entry.value != null
                                                ? (entry.value as num)
                                                    .toStringAsFixed(2)
                                                : "-",
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: DesignTokens.primaryColor,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ))
                                .toList(),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// --- Single Summary Export Dialog ---
class ExportAnalyticsDialogSingleSummary extends StatelessWidget {
  final AnalyticsSummary summary;
  const ExportAnalyticsDialogSingleSummary({super.key, required this.summary});

  @override
  Widget build(BuildContext context) {
    final csv = ExportUtils.analyticsSummaryToCsv(summary);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      title: const Text(
        'Export Analytics Data',
        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
        textAlign: TextAlign.center,
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text(
            'Analytics export generated.',
            style: TextStyle(color: Colors.green, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey.shade300),
            ),
            constraints: const BoxConstraints(maxHeight: 220),
            child: SingleChildScrollView(
              child: SelectableText(
                csv,
                style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
              ),
            ),
          ),
        ],
      ),
      actions: [
        Padding(
            padding:
                const EdgeInsets.only(bottom: 16, left: 8, right: 8, top: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                // Share Button
                SizedBox(
                  width: 100, // adjust as needed for your dialog width
                  height: 40,
                  child: OutlinedButton.icon(
                    icon: const Icon(Icons.share, size: 24),
                    label: const Text('Share', style: TextStyle(fontSize: 18)),
                    style: OutlinedButton.styleFrom(
                      side: BorderSide(
                          color: DesignTokens.primaryColor, width: 2),
                      foregroundColor: DesignTokens.primaryColor,
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 0),
                    ),
                    onPressed: () async {
                      final dir = await getTemporaryDirectory();
                      final file = File(
                          '${dir.path}/analytics_export_${summary.period}.csv');
                      await file.writeAsString(csv);
                      await Share.shareXFiles([XFile(file.path)],
                          text: 'Analytics Export (${summary.period})');
                    },
                  ),
                ),
                const SizedBox(width: 16),
                // Close Button
                SizedBox(
                  width: 100, // adjust as needed for your dialog width
                  height: 40,
                  child: ElevatedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: DesignTokens.primaryColor,
                      foregroundColor: Colors.white,
                      textStyle: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.w600),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(22),
                      ),
                      padding: const EdgeInsets.symmetric(
                          vertical: 4, horizontal: 0),
                    ),
                    child: const Text('Close'),
                  ),
                ),
              ],
            )),
      ],
    );
  }
}
