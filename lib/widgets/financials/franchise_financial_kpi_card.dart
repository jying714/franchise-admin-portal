import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_section_card.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/formatting.dart'
    as formatting;
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';

class FranchiseFinancialKpiCard extends StatefulWidget {
  final String franchiseId;
  final String? brandId;

  const FranchiseFinancialKpiCard({
    Key? key,
    required this.franchiseId,
    this.brandId,
  }) : super(key: key);

  @override
  State<FranchiseFinancialKpiCard> createState() =>
      _FranchiseFinancialKpiCardState();
}

class _FranchiseFinancialKpiCardState extends State<FranchiseFinancialKpiCard> {
  late Future<Map<String, dynamic>> _kpiFuture;
  late ColorScheme _colors;
  bool _isDeveloper = false;

  @override
  void initState() {
    super.initState();
    _kpiFuture = _loadKpis();
    _checkRole();
  }

  void _checkRole() {
    final user = context.read<AdminUserProvider>().user;
    final roles = user?.roles ?? [];
    setState(() {
      _isDeveloper = roles.contains('developer') ||
          roles.contains('hq_owner') ||
          roles.contains('finance_manager');
    });
  }

  Future<Map<String, dynamic>> _loadKpis() async {
    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);

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
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      ErrorLogger.log(
        message: 'Failed to load KPIs: $e',
        source: 'FranchiseFinancialKpiCard',
        screen: 'FranchiseFinancialKpiCard',
        stack: st.toString(),
        severity: 'error',
        contextData: {
          'franchiseId': widget.franchiseId,
        },
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    print('[FranchiseFinancialKpiCard] build called');
    _colors = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    if (!_isDeveloper) return const SizedBox.shrink();

    return DashboardSectionCard(
      title: localizations?.kpiFinancials ?? 'Financial KPIs',
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

            Widget cardContent;

            if (snapshot.hasError) {
              cardContent = Card(
                color: Theme.of(context).colorScheme.errorContainer,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(DesignTokens.paddingMd),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: Colors.redAccent),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          localizations?.errorLoadingKpi ??
                              'Failed to load KPIs.',
                          style:
                              Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    color: DesignTokens.textColor,
                                  ),
                        ),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() {
                          _kpiFuture = _loadKpis();
                        }),
                        icon: const Icon(Icons.refresh),
                        label: Text(localizations?.retry ?? 'Retry'),
                      ),
                    ],
                  ),
                ),
              );
            } else {
              final analytics =
                  snapshot.data?['analytics'] as Map<String, dynamic>? ?? {};
              final outstanding = snapshot.data?['outstanding'] ?? 0.0;
              final lastPayout =
                  snapshot.data?['lastPayout'] as Map<String, dynamic>? ?? {};

              cardContent = Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _KpiRow(
                    localizations: localizations,
                    analytics: analytics,
                    outstanding: outstanding,
                    lastPayout: lastPayout,
                  ),
                  const SizedBox(height: 8),
                  if (_isDeveloper &&
                      Theme.of(context).brightness == Brightness.dark)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Text(
                        'Debug: FranchiseId=${widget.franchiseId}, BrandId=${widget.brandId}',
                        style: Theme.of(context)
                            .textTheme
                            .labelSmall
                            ?.copyWith(color: _colors.outline),
                      ),
                    ),
                ],
              );
            }

            // --------- THIS IS THE KEY FIX ---------
            return LayoutBuilder(
              builder: (context, constraints) {
                // If the card is being rendered in a small fixed height (GridView/SizedBox), force scroll
                if (constraints.maxHeight < 320) {
                  // 320 is a reasonable height for all content to fit; adjust as needed
                  return SingleChildScrollView(
                    child: ConstrainedBox(
                      constraints:
                          BoxConstraints(minHeight: constraints.maxHeight),
                      child: cardContent,
                    ),
                  );
                } else {
                  // Allow content to expand naturally if there is space
                  return cardContent;
                }
              },
            );
            // ---------------------------------------
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
  });

  @override
  Widget build(BuildContext context) {
    final _colors = Theme.of(context).colorScheme;
    final currency = analytics['currency'] ?? 'USD';

    Widget _kpiTile(
      IconData icon,
      String label,
      dynamic value, {
      Color? color,
      String? tooltip,
    }) {
      return Tooltip(
        message: tooltip ?? label,
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: 32, color: color ?? _colors.primary),
            const SizedBox(height: 6),
            Text(
              label,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: _colors.onSurface.withOpacity(0.6),
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value is num
                  ? formatting.formatCurrency(value, currency)
                  : (value?.toString() ?? '--'),
              style: Theme.of(context).textTheme.titleLarge?.copyWith(
                    color: color ?? _colors.primary,
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
        _kpiTile(
          Icons.attach_money,
          localizations?.kpiRevenue ?? 'Revenue',
          analytics['totalRevenue'] ?? 0,
          color: _colors.primary,
        ),
        _kpiTile(
          Icons.receipt_long_outlined,
          localizations?.kpiOutstanding ?? 'Outstanding',
          outstanding,
          color: Colors.redAccent,
        ),
        _kpiTile(
          Icons.payments_outlined,
          localizations?.kpiLastPayout ?? 'Last Payout',
          lastPayout['amount'] ?? '--',
          color: Colors.green,
          tooltip: lastPayout['date'] != null
              ? '${localizations?.kpiPayoutDate ?? 'Date'}: ${lastPayout['date']}'
              : null,
        ),
        _kpiTile(
          Icons.trending_up_outlined,
          localizations?.kpiAvgOrder ?? 'Avg. Order',
          analytics['averageOrderValue'] ?? '--',
        ),
      ],
    );
  }
}

class _ErrorCard extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorCard({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Theme.of(context).colorScheme.errorContainer,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        child: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.redAccent),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Theme.of(context).colorScheme.onErrorContainer,
                    ),
              ),
            ),
            TextButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: Text(AppLocalizations.of(context)?.retry ?? 'Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _FeaturePlaceholder extends StatelessWidget {
  final String label;
  const _FeaturePlaceholder({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
        ),
        borderRadius: BorderRadius.circular(DesignTokens.radiusLg),
      ),
      child: Row(
        children: [
          const Icon(Icons.lightbulb_outline, size: 20, color: Colors.amber),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontStyle: FontStyle.italic,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
