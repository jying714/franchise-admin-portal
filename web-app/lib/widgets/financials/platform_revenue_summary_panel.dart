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
    final colorScheme = theme.colorScheme;

    String money(double v) {
      try {
        return loc.currencyFormat(v);
      } catch (_) {
        return v.toStringAsFixed(2);
      }
    }

    Widget metric({
      required String label,
      required String value,
      Color? valueColor,
    }) {
      return Expanded(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                  color: valueColor ?? colorScheme.primary,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: DesignTokens.adminCardElevation,
      margin: EdgeInsets.zero,
      color: colorScheme.surface,
      surfaceTintColor: Colors.transparent,
      shadowColor: Colors.black.withValues(alpha: 0.18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(DesignTokens.adminCardRadius),
        side: BorderSide(
          color: colorScheme.outlineVariant.withValues(alpha: 0.35),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              loc.platformOwnerRevenueSummaryTitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.titleMedium?.copyWith(
                color: BrandingConfig.brandRed,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator()),
              )
            else if (_error)
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(loc.genericErrorOccurred,
                        style: TextStyle(color: colorScheme.error)),
                    if (_errorMsg != null)
                      Text(
                        _errorMsg!,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: colorScheme.error),
                      ),
                    TextButton(
                      onPressed: _loadPlatformFinancials,
                      child: Text(loc.retry),
                    ),
                  ],
                ),
              )
            else
              Expanded(
                child: Column(
                  children: [
                    // Top metrics — equal flex with bottom
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            metric(
                              label: loc.platformStatTotalRevenueYtd,
                              value: money(totalRevenueYtd),
                              valueColor: BrandingConfig.brandRed,
                            ),
                            metric(
                              label: loc.platformStatSubscriptionRevenue,
                              value: money(subscriptionRevenue),
                            ),
                            metric(
                              label: loc.platformStatRoyaltyRevenue,
                              value: money(royaltyRevenue),
                            ),
                            metric(
                              label: loc.platformStatOverdueAmount,
                              value: money(overdueAmount),
                              valueColor:
                                  overdueAmount > 0 ? colorScheme.error : null,
                            ),
                          ],
                        ),
                      ),
                    ),
                    // Divider centered between the two equal Expanded rows
                    Divider(
                      height: 1,
                      thickness: 1,
                      color: colorScheme.outlineVariant.withValues(alpha: 0.45),
                    ),
                    Expanded(
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            metric(
                              label: loc.platformKpiMrr,
                              value: money(mrr),
                              valueColor: BrandingConfig.brandRed,
                            ),
                            metric(
                              label: loc.platformKpiArr,
                              value: money(arr),
                            ),
                            metric(
                              label: loc.platformKpiActiveFranchises,
                              value: '$activeFranchises',
                            ),
                            metric(
                              label: loc.platformKpiRecentPayouts,
                              value: money(recentPayouts),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
