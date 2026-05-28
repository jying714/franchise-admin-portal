import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/config/ui_config.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef GetToppingUpcharge = double Function();
typedef CurrencyFormat = String Function(BuildContext, double);

class ToppingCostLabel extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations loc;
  final GetToppingUpcharge getToppingUpcharge;
  final CurrencyFormat currencyFormat;

  const ToppingCostLabel({
    super.key,
    required this.theme,
    required this.loc,
    required this.getToppingUpcharge,
    required this.currencyFormat,
  });

  @override
  Widget build(BuildContext context) {
    final upcharge = getToppingUpcharge();
    return Row(
      children: [
        Text(
          loc.additionalToppingCostLabel ?? "Additional topping cost:",
          style: theme.textTheme.bodySmall?.copyWith(
            color: UiConfig.secondaryTextColor,
            fontFamily: shared.DesignTokens.fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          currencyFormat(context, upcharge),
          style: theme.textTheme.bodySmall?.copyWith(
            color: UiConfig.primaryColor,
            fontWeight: UiConfig.bold,
            fontFamily: shared.DesignTokens.fontFamily,
          ),
        ),
      ],
    );
  }
}
