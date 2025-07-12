import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:provider/provider.dart';

import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/widgets/dashboard/dashboard_section_card.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/models/cash_flow_forecast.dart';
import 'package:franchise_admin_portal/core/providers/admin_user_provider.dart';
import 'package:franchise_admin_portal/widgets/loading_shimmer_widget.dart';

class CashFlowForecastCard extends StatefulWidget {
  final String franchiseId;
  final String? brandId;

  const CashFlowForecastCard({
    Key? key,
    required this.franchiseId,
    this.brandId,
  }) : super(key: key);

  @override
  State<CashFlowForecastCard> createState() => _CashFlowForecastCardState();
}

class _CashFlowForecastCardState extends State<CashFlowForecastCard> {
  late Future<CashFlowForecast?> _forecastFuture;
  late ColorScheme _colors;
  bool _isDeveloper = false;

  @override
  void initState() {
    super.initState();
    _forecastFuture = _loadForecast();
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

  Future<CashFlowForecast?> _loadForecast() async {
    try {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      // Replace with your Firestore structure for forecast data:
      final doc =
          await firestoreService.getCashFlowForecast(widget.franchiseId);
      print('Loaded cash flow forecast: $doc');
      print("CashFlowForecastCard franchiseId: ${widget.franchiseId}");
      if (doc == null) return null;
      // Use period as the id if available, or "" if not present:
      return CashFlowForecast.fromFirestore(doc, doc['period'] ?? '');
    } catch (e, st) {
      final firestoreService =
          Provider.of<FirestoreService>(context, listen: false);
      await firestoreService.logError(
        widget.franchiseId,
        message: 'Failed to load cash flow forecast: $e',
        source: 'CashFlowForecastCard',
        screen: 'CashFlowForecastCard',
        stackTrace: st.toString(),
        severity: 'error',
        contextData: {'franchiseId': widget.franchiseId},
      );
      rethrow;
    }
  }

  @override
  Widget build(BuildContext context) {
    _colors = Theme.of(context).colorScheme;
    final localizations = AppLocalizations.of(context);

    if (!_isDeveloper) return const SizedBox.shrink();

    return DashboardSectionCard(
      title: localizations?.featureComingSoonCashFlow ?? 'Cash Flow Forecast',
      icon: Icons.trending_up_rounded,
      franchiseId: widget.franchiseId,
      brandId: widget.brandId,
      developerOnly: true,
      showFuturePlaceholders: false,
      builder: (context) {
        return FutureBuilder<CashFlowForecast?>(
          future: _forecastFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const LoadingShimmerWidget();
            }

            if (snapshot.hasError) {
              return _ErrorCard(
                message: localizations?.errorLoadingKpi ??
                    'Failed to load forecast.',
                onRetry: () => setState(() {
                  _forecastFuture = _loadForecast();
                }),
              );
            }

            final forecast = snapshot.data;
            if (forecast == null) {
              // If no forecast, show placeholder/future feature card.
              return _FeaturePlaceholder(
                label: localizations?.featureComingSoonCashFlow ??
                    'Cash Flow Forecast (coming soon)',
              );
            }

            final brandColor = BrandingConfig.brandRed;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _ForecastRow(
                  localizations: localizations,
                  forecast: forecast,
                  brandColor: brandColor,
                ),
                const SizedBox(height: 8),
                _FeaturePlaceholder(
                  label: localizations?.featureComingSoonRevenueTrends ??
                      'Per-Location Revenue Trends (coming soon)',
                ),
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
          },
        );
      },
    );
  }
}

class _ForecastRow extends StatelessWidget {
  final AppLocalizations? localizations;
  final CashFlowForecast forecast;
  final Color brandColor;

  const _ForecastRow({
    required this.localizations,
    required this.forecast,
    required this.brandColor,
  });

  @override
  Widget build(BuildContext context) {
    final _colors = Theme.of(context).colorScheme;
    final currency = 'USD'; // Replace with dynamic if needed

    Widget _forecastTile(
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
              value.toStringAsFixed(2),
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
        _forecastTile(
          Icons.account_balance_wallet_outlined,
          localizations?.openingBalance ?? 'Opening Balance',
          forecast.openingBalance,
          color: _colors.primary,
        ),
        _forecastTile(
          Icons.trending_up,
          localizations?.projectedInflow ?? 'Projected Inflow',
          forecast.projectedInflow,
          color: Colors.green,
        ),
        _forecastTile(
          Icons.trending_down,
          localizations?.projectedOutflow ?? 'Projected Outflow',
          forecast.projectedOutflow,
          color: Colors.redAccent,
        ),
        _forecastTile(
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
