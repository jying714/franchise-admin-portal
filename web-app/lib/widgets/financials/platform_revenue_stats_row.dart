import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
    if (loc == null) {
      print(
          '[_formatCurrency] loc is null! Localization not available for this context.');
      // Return a sensible fallback string instead of a widget:
      return value.toStringAsFixed(2); // Or just return '--'
    }
    // Uses intl/currency formatting per locale if available
    return loc.currencyFormat(value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context);
    if (loc == null) {
      print(
          '[PlatformRevenueStatsRow] loc is null! Localization not available for this context.');
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

    // Modular/future expansion - add new stat blocks below as needed
    final stats = [
      _RevenueStatBlock(
        label: loc.platformStatTotalRevenueYtd,
        value: _formatCurrency(context, totalRevenueYtd),
        highlight: true,
      ),
      _RevenueStatBlock(
        label: loc.platformStatSubscriptionRevenue,
        value: _formatCurrency(context, subscriptionRevenue),
      ),
      _RevenueStatBlock(
        label: loc.platformStatRoyaltyRevenue,
        value: _formatCurrency(context, royaltyRevenue),
      ),
      _RevenueStatBlock(
        label: loc.platformStatOverdueAmount,
        value: _formatCurrency(context, overdueAmount),
        warning: overdueAmount > 0,
      ),
      // ðŸ’¡ Future Feature Placeholders (uncomment/add here)
      // _RevenueStatBlock(label: loc.platformStatRefunds, value: ...),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: stack vertically on narrow screens
        final isWide = constraints.maxWidth > 800;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 0),
          child: isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: stats,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: stats
                      .map((w) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8),
                            child: w,
                          ))
                      .toList(),
                ),
        );
      },
    );
  }
}

// Modular stat block with theme/config tokens
class _RevenueStatBlock extends StatelessWidget {
  final String label;
  final String value;
  final bool highlight;
  final bool warning;

  const _RevenueStatBlock({
    required this.label,
    required this.value,
    this.highlight = false,
    this.warning = false,
  });

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
        color: theme.colorScheme.surfaceVariant.withOpacity(0.13),
        borderRadius: BorderRadius.circular(DesignTokens.cardBorderRadiusSmall),
        border: Border.all(
          color: warning
              ? colorScheme.error
              : (highlight
                  ? BrandingConfig.brandRed.withOpacity(0.25)
                  : colorScheme.outlineVariant.withOpacity(0.15)),
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
              letterSpacing: -1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: labelColor,
              fontWeight: FontWeight.w500,
              letterSpacing: 0,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}


