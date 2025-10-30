import 'package:intl/intl.dart';
import 'package:flutter/widgets.dart';

// Accepts context and value, uses the current app locale:
String currencyFormat(BuildContext context, num value) {
  final locale = Localizations.localeOf(context).toString();
  final format = NumberFormat.simpleCurrency(locale: locale);
  final result = format.format(value);
  //print('currencyFormat output: $result');
  return format.format(value);
}

String formatCurrency(num amount, [String currency = 'USD']) {
  // Simple version, you may want intl/NumberFormat for real apps
  return '\$${amount.toStringAsFixed(2)}'; // TODO: Support multi-currency
}
