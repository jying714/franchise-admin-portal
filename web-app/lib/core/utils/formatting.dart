// web_app/lib/core/utils/formatting.dart

import 'package:flutter/widgets.dart';
import 'package:shared_core/src/core/utils/formatting_core.dart';

class Formatting {
  Formatting._();

  /// Uses current app locale from BuildContext
  static String currencyFormat(BuildContext context, num value) {
    final locale = Localizations.localeOf(context).toString();
    return FormattingCore.formatCurrency(
      value,
      locale: locale,
      currency: 'USD', // or get from franchise settings
    );
  }

  /// Simple static version
  static String formatCurrency(num amount, [String currency = 'USD']) {
    return FormattingCore.formatCurrencySimple(amount, currency);
  }
}
