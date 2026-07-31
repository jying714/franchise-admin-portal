import 'package:flutter/material.dart';
import 'package:provider/provider.dart' as provider;
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/generated/app_localizations.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_section_card.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';

class CashFlowForecastCard extends StatefulWidget {
  final String franchiseId;
  final String? brandId;

  const CashFlowForecastCard({
    super.key,
    required this.franchiseId,
    this.brandId,
  });

  @override
  State<CashFlowForecastCard> createState() => _CashFlowForecastCardState();
}

class _CashFlowForecastCardState extends State<CashFlowForecastCard> {
  late Future<shared.CashFlowForecast?> _forecastFuture;

  @override
  void initState() {
    super.initState();
    _forecastFuture = _loadForecast();
  }

  Future<shared.CashFlowForecast?> _loadForecast() async {
    try {
      final firestoreService = provider.Provider.of<shared.FirestoreService>(
        context,
        listen: false,
      );

      final doc =
          await firestoreService.getCashFlowForecast(widget.franchiseId);
      if (doc == null) return null;

      return shared.CashFlowForecast.fromFirestore(doc, doc['period'] ?? '');
    } catch (e, st) {
      shared.ErrorLogger.log(
        message: 'Failed to load cash flow forecast: $e',
        source: 'CashFlowForecastCard',
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
      title: loc?.featureComingSoonCashFlow ?? 'Cash Flow Forecast',
      icon: Icons.trending_up_rounded,
      franchiseId: widget.franchiseId,
      brandId: widget.brandId,
      developerOnly: true,
      showFuturePlaceholders: false,
      builder: (context) {
        return FutureBuilder<shared.CashFlowForecast?>(
          future: _forecastFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingShimmerWidget();
            }

            if (snapshot.hasError) {
              return _ErrorCard(
                message: loc?.errorLoadingKpi ?? 'Failed to load forecast.',
                onRetry: () => setState(() {
                  _forecastFuture = _loadForecast();
                }),
              );
            }

            final forecast = snapshot.data;
            if (forecast == null) {
              return _FeaturePlaceholder(
                label: loc?.featureComingSoonCashFlow ??
                    'Cash Flow Forecast (coming soon)',
              );
            }

            final brandColor = DesignTokens.primaryColor;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ForecastRow(
                  localizations: loc,
                  forecast: forecast,
                  brandColor: brandColor,
                ),
                const SizedBox(height: 8),
                _FeaturePlaceholder(
                  label: loc?.featureComingSoonRevenueTrends ??
                      'Per-Location Revenue Trends (coming soon)',
                ),
              ],
            );
          },
        );
      },
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final AppLocalizations? localizations;
  final shared.CashFlowForecast forecast;
  final Color brandColor;

  const _ForecastRow({
    required this.localizations,
    required this.forecast,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    Widget forecastTile(
      IconData icon,
      String label,
      double value, {
      Color? color,
      String? tooltip,
    }) {
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
                    color: colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
            ),
            const SizedBox(height: 2),
            Text(
              value.toStringAsFixed(2),
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
        forecastTile(
          Icons.account_balance_wallet_outlined,
          localizations?.openingBalance ?? 'Opening Balance',
          forecast.openingBalance,
          color: colorScheme.primary,
        ),
        forecastTile(
          Icons.trending_up,
          localizations?.projectedInflow ?? 'Projected Inflow',
          forecast.projectedInflow,
          color: Colors.green,
        ),
        forecastTile(
          Icons.trending_down,
          localizations?.projectedOutflow ?? 'Projected Outflow',
          forecast.projectedOutflow,
          color: Colors.redAccent,
        ),
        forecastTile(
          Icons.attach_money,
          localizations?.projectedClosing ?? 'Projected Closing',
          forecast.projectedClosingBalance,
          color: brandColor,
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
            Icon(Icons.error_outline,
                color: Theme.of(context).colorScheme.error),
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
