import 'package:flutter/material.dart';
import 'package:admin_portal/config/design_tokens.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

typedef GetToppingUpcharge = double Function();
typedef CurrencyFormat = String Function(BuildContext, double);

class ToppingCostLabel extends StatelessWidget {
  final ThemeData theme;
  final AppLocalizations loc;
  final GetToppingUpcharge getToppingUpcharge;
  final CurrencyFormat currencyFormat;

  const ToppingCostLabel({
    Key? key,
    required this.theme,
    required this.loc,
    required this.getToppingUpcharge,
    required this.currencyFormat,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final upcharge = getToppingUpcharge();
    return Row(
      children: [
        Text(
          loc.additionalToppingCostLabel ?? "Additional topping cost:",
          style: theme.textTheme.bodySmall?.copyWith(
            color: DesignTokens.secondaryTextColor,
            fontFamily: DesignTokens.fontFamily,
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(width: 8),
        Text(
          currencyFormat(context, upcharge),
          style: theme.textTheme.bodySmall?.copyWith(
            color: DesignTokens.primaryColor,
            fontWeight: FontWeight.bold,
            fontFamily: DesignTokens.fontFamily,
          ),
        ),
      ],
    );
  }
}
