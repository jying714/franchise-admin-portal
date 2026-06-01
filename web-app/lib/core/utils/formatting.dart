// web_app/lib/core/utils/formatting.dart

import 'package:flutter/widgets.dart';
import 'package:shared_core/shared_core.dart' as shared; // migrated from src/

class Formatting {
  Formatting._();

  /// Uses current app locale from BuildContext
  static String currencyFormat(BuildContext context, num value) {
    final locale = Localizations.localeOf(context).toString();
    return shared.FormattingCore.formatCurrency(
      value,
      locale: locale,
      currency: 'USD', // or get from franchise settings
    );
  }

  /// Simple static version
  static String formatCurrency(num amount, [String currency = 'USD']) {
    return shared.FormattingCore.formatCurrencySimple(amount, currency);
  }
}
