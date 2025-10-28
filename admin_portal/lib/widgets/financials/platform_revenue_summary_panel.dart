import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:franchise_admin_portal/widgets/financials/platform_revenue_stats_row.dart';
import 'package:franchise_admin_portal/widgets/financials/platform_financial_kpi_row.dart';
import 'package:provider/provider.dart';

class PlatformRevenueSummaryPanel extends StatefulWidget {
  const PlatformRevenueSummaryPanel({super.key});

  @override
  State<PlatformRevenueSummaryPanel> createState() =>
      _PlatformRevenueSummaryPanelState();
}

class _PlatformRevenueSummaryPanelState
    extends State<PlatformRevenueSummaryPanel> {
  bool _loading = true;
  bool _error = false;
  String? _errorMsg;

  // Revenue Overview Data (Top Row)
  double totalRevenueYtd = 0;
  double subscriptionRevenue = 0;
  double royaltyRevenue = 0;
  double overdueAmount = 0;

  // KPIs (Second Row)
  double mrr = 0;
  double arr = 0;
  int activeFranchises = 0;
  double recentPayouts = 0;

  @override
  void initState() {
    super.initState();
    _loadPlatformFinancials();
  }

  Future<void> _loadPlatformFinancials() async {
    setState(() {
      _loading = true;
      _error = false;
      _errorMsg = null;
    });

    try {
      // You should implement/extend these methods in firestore_service.dart
      final financials =
          await FirestoreService().fetchPlatformRevenueOverview();
      final kpis = await FirestoreService().fetchPlatformFinancialKpis();

      setState(() {
        totalRevenueYtd = financials.totalRevenueYtd;
        subscriptionRevenue = financials.subscriptionRevenue;
        royaltyRevenue = financials.royaltyRevenue;
        overdueAmount = financials.overdueAmount;

        mrr = kpis.mrr;
        arr = kpis.arr;
        activeFranchises = kpis.activeFranchises;
        recentPayouts = kpis.recentPayouts;
        _loading = false;
      });
    } catch (e, stack) {
      await ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'PlatformRevenueSummaryPanel',
        screen: '_loadPlatformFinancials',
        severity: 'error',
        contextData: {
          'userEmail': Provider.of<AdminUserProvider>(context, listen: false)
              .user
              ?.email,
        },
      );
      setState(() {
        _error = true;
        _errorMsg = e.toString();
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[PlatformRevenueSummaryPanel] loc is null! Localization not available for this context.');
      return Card(
        color: Colors.red.shade100,
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Row(
            children: [
              Icon(Icons.error, color: Colors.red),
              const SizedBox(width: 12),
              Expanded(
                  child: Text('Localization missing! [debug]',
                      style: TextStyle(color: Colors.red))),
            ],
          ),
        ),
      );
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: EdgeInsets.symmetric(vertical: 12, horizontal: 0),
      color:
          isDark ? theme.colorScheme.surfaceVariant : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.cardBorderRadiusLarge),
      ),
      child: Padding(
        padding: const EdgeInsets.all(28.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.platformOwnerRevenueSummaryTitle,
              style: theme.textTheme.titleLarge?.copyWith(
                color: BrandingConfig.brandRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              Center(child: CircularProgressIndicator())
            else if (_error)
              Column(
                children: [
                  Text(
                    loc.genericErrorOccurred,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.error,
                    ),
                  ),
                  if (_errorMsg != null)
                    Text(
                      _errorMsg!,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.error,
                      ),
                    ),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadPlatformFinancials,
                    child: Text(loc.retry),
                  ),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top Row: Revenue Overview
                  PlatformRevenueStatsRow(
                    totalRevenueYtd: totalRevenueYtd,
                    subscriptionRevenue: subscriptionRevenue,
                    royaltyRevenue: royaltyRevenue,
                    overdueAmount: overdueAmount,
                  ),
                  const SizedBox(height: 24),
                  // Second Row: KPIs and Projections
                  PlatformFinancialKpiRow(
                    mrr: mrr,
                    arr: arr,
                    activeFranchises: activeFranchises,
                    recentPayouts: recentPayouts,
                  ),
                  const SizedBox(height: 10),
                  // Future Feature Placeholder
                  if (false)
                    Padding(
                      padding: const EdgeInsets.only(top: 18.0),
                      child: Text(
                        '[Future: SaaS Churn Rate, Growth Cohorts, ARPU]',
                        style: theme.textTheme.labelMedium?.copyWith(
                          color: theme.colorScheme.outline,
                        ),
                      ),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
