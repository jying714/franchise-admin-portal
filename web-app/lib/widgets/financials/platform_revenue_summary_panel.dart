import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';
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

  double totalRevenueYtd = 0;
  double subscriptionRevenue = 0;
  double royaltyRevenue = 0;
  double overdueAmount = 0;

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
    if (!mounted) return;
    setState(() {
      _loading = true;
      _error = false;
      _errorMsg = null;
    });

    try {
      final fs = Provider.of<shared.FirestoreService>(context, listen: false);
      final financials = await fs.fetchPlatformRevenueOverview();
      final kpis = await fs.fetchPlatformFinancialKpis();

      if (!mounted) return;
      setState(() {
        totalRevenueYtd = financials?.totalRevenueYtd ?? 0;
        subscriptionRevenue = financials?.subscriptionRevenue ?? 0;
        royaltyRevenue = financials?.royaltyRevenue ?? 0;
        overdueAmount = financials?.overdueAmount ?? 0;

        mrr = kpis?.mrr ?? 0;
        arr = kpis?.arr ?? 0;
        activeFranchises = kpis?.activeFranchises ?? 0;
        recentPayouts = kpis?.recentPayouts ?? 0;
        _loading = false;
      });
    } catch (e, stack) {
      if (!mounted) return;
      shared.ErrorLogger.log(
        message: e.toString(),
        stack: stack.toString(),
        source: 'PlatformRevenueSummaryPanel',
        severity: 'error',
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
      return const Card(
        color: Colors.red,
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('Localization missing!',
              style: TextStyle(color: Colors.white)),
        ),
      );
    }
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Card(
      elevation: 0,
      margin: const EdgeInsets.symmetric(vertical: 12),
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
              const Center(child: CircularProgressIndicator())
            else if (_error)
              Column(
                children: [
                  Text(loc.genericErrorOccurred,
                      style: TextStyle(color: theme.colorScheme.error)),
                  if (_errorMsg != null)
                    Text(_errorMsg!,
                        style: TextStyle(color: theme.colorScheme.error)),
                  ElevatedButton(
                      onPressed: _loadPlatformFinancials,
                      child: Text(loc.retry)),
                ],
              )
            else
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  PlatformRevenueStatsRow(
                    totalRevenueYtd: totalRevenueYtd,
                    subscriptionRevenue: subscriptionRevenue,
                    royaltyRevenue: royaltyRevenue,
                    overdueAmount: overdueAmount,
                  ),
                  const SizedBox(height: 24),
                  PlatformFinancialKpiRow(
                    mrr: mrr,
                    arr: arr,
                    activeFranchises: activeFranchises,
                    recentPayouts: recentPayouts,
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
