import 'package:admin_portal/core/providers/user_profile_notifier.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:admin_portal/core/services/analytics_service.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/models/analytics_summary.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:admin_portal/widgets/loading_shimmer_widget.dart';
import '../../widgets/orders/export_analytics_dialog.dart';
import 'package:flutter/services.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';
import 'dart:io';
import 'package:admin_portal/core/utils/export_utils.dart';
import 'package:admin_portal/core/providers/franchise_provider.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:admin_portal/core/providers/admin_user_provider.dart';
import 'package:admin_portal/widgets/orders/feedback_card.dart';

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  String? _selectedPeriod;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final userProvider = context.watch<AdminUserProvider>();
    final franchiseId = context.watch<FranchiseProvider>().franchiseId;

    return Scaffold(
      backgroundColor: colorScheme.background,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 11,
            child: Padding(
              padding:
                  const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Text(
                        "Analytics Dashboard",
                        style: TextStyle(
                          color: colorScheme.onBackground,
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: Icon(Icons.download_rounded,
                            color: colorScheme.onSurface),
                        tooltip: "Export Current Summary (CSV)",
                        onPressed: () async {
                          if (_selectedPeriod == null) return;
                          final summaries = await context
                              .read<AnalyticsService>()
                              .getAnalyticsSummaries(franchiseId);
                          final current = summaries.firstWhere(
                            (s) => s.period == _selectedPeriod,
                            orElse: () => summaries.first,
                          );
                          if (current != null) {
                            showDialog(
                              context: context,
                              builder: (_) =>
                                  ExportAnalyticsDialogSingleSummary(
                                      summary: current),
                            );
                          }
                        },
                      )
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: StreamBuilder<List<AnalyticsSummary>>(
                      stream: context
                          .read<AnalyticsService>()
                          .getSummaryMetrics(franchiseId),
                      builder: (context, snapshot) {
                        if (snapshot.connectionState ==
                            ConnectionState.waiting) {
                          return const LoadingShimmerWidget();
                        }
                        if (snapshot.hasError) {
                          return Center(
                            child: Text(
                              'Error loading analytics data.',
                              style: TextStyle(color: colorScheme.error),
                            ),
                          );
                        }
                        final summaries = snapshot.data ?? [];
                        if (summaries.isEmpty) {
                          return Center(
                            child: Text(
                              'No analytics data available.',
                              style: TextStyle(color: colorScheme.outline),
                            ),
                          );
                        }

                        final sorted = List<AnalyticsSummary>.from(summaries)
                          ..sort((a, b) => b.period.compareTo(a.period));
                        final periods =
                            sorted.map((s) => s.period).toSet().toList();
                        final selected = _selectedPeriod ?? periods.first;
                        final summary = sorted.firstWhere(
                            (s) => s.period == selected,
                            orElse: () => sorted.first);

                        return ListView(
                          children: [
                            Row(
                              children: [
                                Text("Period:",
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: colorScheme.onBackground,
                                    )),
                                const SizedBox(width: 16),
                                DropdownButton<String>(
                                  value: selected,
                                  items: periods
                                      .map((p) => DropdownMenuItem(
                                            value: p,
                                            child: Text(p,
                                                style: TextStyle(
                                                    color:
                                                        colorScheme.onSurface)),
                                          ))
                                      .toList(),
                                  onChanged: (val) =>
                                      setState(() => _selectedPeriod = val),
                                )
                              ],
                            ),
                            const SizedBox(height: 24),
                            Text(
                              "Order & Sales Analytics",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 12),
                            ..._buildMetrics(summary, context),
                            const SizedBox(height: 24),
                            Text(
                              "Customer Feedback",
                              style: TextStyle(
                                color: colorScheme.primary,
                                fontWeight: FontWeight.w800,
                                fontSize: 20,
                              ),
                            ),
                            const SizedBox(height: 12),
                            FeedbackCard(summary: summary),
                          ],
                        );
                      },
                    ),
                  )
                ],
              ),
            ),
          ),
          const Expanded(flex: 9, child: SizedBox()),
        ],
      ),
    );
  }

  List<Widget> _buildMetrics(AnalyticsSummary summary, BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final metrics = <String, dynamic>{
      "Total Orders": summary.totalOrders,
      "Total Revenue": summary.totalRevenue != null
          ? "\$${summary.totalRevenue!.toStringAsFixed(2)}"
          : null,
      "Average Order Value": summary.averageOrderValue != null
          ? "\$${summary.averageOrderValue!.toStringAsFixed(2)}"
          : null,
      "Most Popular Item": summary.mostPopularItem,
      "Retention Rate": summary.retentionRate != null
          ? "${(summary.retentionRate! * 100).toStringAsFixed(1)}%"
          : null,
      "Unique Customers": summary.uniqueCustomers,
      "Cancelled Orders": summary.cancelledOrders,
      "Last Updated": summary.updatedAt?.toString(),
    };

    return metrics.entries.map((e) {
      return Card(
        color: colorScheme.surface,
        child: ListTile(
          title: Text(e.key, style: TextStyle(color: colorScheme.onSurface)),
          trailing: Text(e.value?.toString() ?? '-',
              style: TextStyle(color: colorScheme.onSurface)),
        ),
      );
    }).toList();
  }
}
