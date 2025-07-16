import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/config/branding_config.dart';
import 'package:franchise_admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class PlatformFinancialKpiRow extends StatelessWidget {
  final double mrr;
  final double arr;
  final int activeFranchises;
  final double recentPayouts;

  const PlatformFinancialKpiRow({
    super.key,
    required this.mrr,
    required this.arr,
    required this.activeFranchises,
    required this.recentPayouts,
  });

  String _formatCurrency(BuildContext context, double value) {
    final loc = AppLocalizations.of(context)!;
    return loc.currencyFormat(value);
  }

  @override
  Widget build(BuildContext context) {
    final loc = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    final kpis = [
      _KpiBlock(
        label: loc.platformKpiMrr,
        value: _formatCurrency(context, mrr),
        color: BrandingConfig.brandRed,
      ),
      _KpiBlock(
        label: loc.platformKpiArr,
        value: _formatCurrency(context, arr),
        color: theme.colorScheme.secondary,
      ),
      _KpiBlock(
        label: loc.platformKpiActiveFranchises,
        value: activeFranchises.toString(),
        color: theme.colorScheme.primary,
      ),
      _KpiBlock(
        label: loc.platformKpiRecentPayouts,
        value: _formatCurrency(context, recentPayouts),
        color: theme.colorScheme.tertiary,
      ),
      // 💡 Future Feature Placeholder (uncomment as needed)
      // _KpiBlock(label: loc.platformKpiChurn, value: "...", color: Colors.orange),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 800;
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 2.0, horizontal: 0),
          child: isWide
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: kpis,
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: kpis
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

class _KpiBlock extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _KpiBlock({
    required this.label,
    required this.value,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: const BoxConstraints(minWidth: 120),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(DesignTokens.cardBorderRadiusSmall),
        border: Border.all(
          color: color.withOpacity(0.22),
          width: 1.5,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              color: color,
              fontWeight: FontWeight.w700,
              letterSpacing: -0.5,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: color.withOpacity(0.9),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}
