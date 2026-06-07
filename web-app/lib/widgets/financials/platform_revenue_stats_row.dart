import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:franchise_admin_portal/generated/app_localizations.dart';

class PlatformRevenueStatsRow extends StatelessWidget {
  final double totalRevenueYtd;
  final double subscriptionRevenue;
  final double royaltyRevenue;
  final double overdueAmount;

  const PlatformRevenueStatsRow({
    super.key,
    required this.totalRevenueYtd,
    required this.subscriptionRevenue,
    required this.royaltyRevenue,
    required this.overdueAmount,
  });

  String _formatCurrency(BuildContext context, double value) {
    final loc = AppLocalizations.of(context);
    if (loc == null) return value.toStringAsFixed(2);
    return loc.currencyFormat(value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      return const Card(
        color: Colors.red,
        child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('Localization missing! [debug]')),
      );
    }
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    final stats = [
      _RevenueStatBlock(
          label: loc.platformStatTotalRevenueYtd,
          value: _formatCurrency(context, totalRevenueYtd),
          highlight: true),
      _RevenueStatBlock(
          label: loc.platformStatSubscriptionRevenue,
          value: _formatCurrency(context, subscriptionRevenue)),
      _RevenueStatBlock(
          label: loc.platformStatRoyaltyRevenue,
          value: _formatCurrency(context, royaltyRevenue)),
      _RevenueStatBlock(
          label: loc.platformStatOverdueAmount,
          value: _formatCurrency(context, overdueAmount),
          warning: overdueAmount > 0),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: stats)
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stats
                      .map((w) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: w))
                      .toList(),
                ),
        );
      },
    );
  }
}

class _RevenueStatBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool warning;

  const _RevenueStatBlock(
      {required this.label,
      required this.value,
      this.highlight = false,
      this.warning = false});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final labelColor =
        warning ? colorScheme.error : colorScheme.onSurfaceVariant;
    final valueColor = highlight
        ? BrandingConfig.brandRed
        : (warning ? colorScheme.error : colorScheme.primary);

    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceVariant.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(DesignTokens.cardBorderRadiusSmall),
        border: Border.all(
          color: warning
              ? colorScheme.error
              : (highlight
                  ? BrandingConfig.brandRed.withValues(alpha: 0.25)
                  : colorScheme.outlineVariant.withValues(alpha: 0.15)),
          width: highlight ? 2 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.headlineMedium?.copyWith(
                color: valueColor,
                fontWeight: highlight ? FontWeight.bold : FontWeight.w600,
                letterSpacing: -1),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: labelColor, fontWeight: FontWeight.w500),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
