import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_section_card.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';

class FranchiseFinancialKpiCard extends StatefulWidget {
  final String franchiseId;
  final String? brandId;

  const FranchiseFinancialKpiCard({
    super.key,
    required this.franchiseId,
    this.brandId,
  });

  @override
  State<FranchiseFinancialKpiCard> createState() =>
      _FranchiseFinancialKpiCardState();
}

class _FranchiseFinancialKpiCardState extends State<FranchiseFinancialKpiCard> {
  late Future<Map<String, dynamic>> _kpiFuture;

  @override
  void initState() {
    super.initState();
    _kpiFuture = _loadKpis();
  }

  Future<Map<String, dynamic>> _loadKpis() async {
    try {
      final firestoreService = provider.Provider.of<shared.FirestoreService>(
        context,
        listen: false,
      );

      final analytics = await firestoreService
          .getFranchiseAnalyticsSummary(widget.franchiseId);
      final outstanding =
          await firestoreService.getOutstandingInvoices(widget.franchiseId);
      final lastPayout =
          await firestoreService.getLastPayout(widget.franchiseId);

      return {
        'analytics': analytics,
        'outstanding': outstanding,
        'lastPayout': lastPayout,
      };
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'Failed to load KPIs: $e',
        source: 'FranchiseFinancialKpiCard',
        stack: st.toString(),
        severity: 'error',
        contextData: {'franchiseId': widget.franchiseId},
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    final colorScheme = Theme.of(context).colorScheme;

    final adminUser = provider.Provider.of<shared.AdminUserProvider>(
      context,
      listen: true,
    ).user;

    final isAllowed = adminUser?.roles?.any(
            (r) => ['developer', 'hq_owner', 'finance_manager'].contains(r)) ??
        false;

    if (!isAllowed) return const SizedBox.shrink();

    return DashboardSectionCard(
      title: loc?.kpiFinancials ?? 'Financial KPIs',
      icon: Icons.analytics_outlined,
      franchiseId: widget.franchiseId,
      brandId: widget.brandId,
      developerOnly: true,
      showFuturePlaceholders: false,
      builder: (context) {
        return FutureBuilder<Map<String, dynamic>>(
          future: _kpiFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingShimmerWidget();
            }

            if (snapshot.hasError) {
              return Card(
                color: colorScheme.errorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
                child: Padding(
                  padding: EdgeInsets.all(DesignTokens.paddingMd),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          loc?.errorLoadingKpi ?? 'Failed to load KPIs.',
                          style: Theme.of(context).textTheme.bodyMedium,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () =>
                            setState(() => _kpiFuture = _loadKpis()),
                        icon: const Icon(Icons.refresh),
                        label: Text(loc?.retry ?? 'Retry'),
                      ),
                    ],
                  ),
                ),
              );
            }

            final analytics =
                snapshot.data?['analytics'] as Map<String, dynamic>? ?? {};
            final outstanding = snapshot.data?['outstanding'] as double? ?? 0.0;
            final lastPayout =
                snapshot.data?['lastPayout'] as Map<String, dynamic>? ?? {};

            return _KpiRow(
              localizations: loc,
              analytics: analytics,
              outstanding: outstanding,
              lastPayout: lastPayout,
            );
          },
        );
      },
    );
  }
}

class _KpiRow extends StatelessWidget {
  final AppLocalizations? localizations;
  final Map<String, dynamic> analytics;
  final double outstanding;
  final Map<String, dynamic> lastPayout;

  const _KpiRow({
    required this.localizations,
    required this.analytics,
    required this.outstanding,
    required this.lastPayout,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final currency = analytics['currency'] ?? 'USD';

    Widget kpiTile(
      IconData icon,
      String label,
      dynamic value, {
      Color? color,
      String? tooltip,
    }) {
      final displayValue =
          value is num ? value.toStringAsFixed(0) : (value?.toString() ?? '--');

      return Tooltip(
        message: tooltip ?? label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color ?? colorScheme.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: colorScheme.onSurface.withOpacity(0.7),
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              displayValue,
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color ?? colorScheme.primary,
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ],
        ),
      );
    }

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        kpiTile(Icons.attach_money, localizations?.kpiRevenue ?? 'Revenue',
            analytics['totalRevenue'] ?? 0,
            color: colorScheme.primary),
        kpiTile(Icons.receipt_long_outlined,
            localizations?.kpiOutstanding ?? 'Outstanding', outstanding,
            color: Colors.redAccent),
        kpiTile(
            Icons.payments_outlined,
            localizations?.kpiLastPayout ?? 'Last Payout',
            lastPayout['amount'] ?? '--',
            color: Colors.green,
            tooltip: lastPayout['date'] != null
                ? 'Date: ${lastPayout['date']}'
                : null),
        kpiTile(
            Icons.trending_up_outlined,
            localizations?.kpiAvgOrder ?? 'Avg. Order',
            analytics['averageOrderValue'] ?? '--'),
      ],
    );
  }
}
