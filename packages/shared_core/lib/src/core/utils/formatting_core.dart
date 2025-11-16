// packages/shared_core/lib/src/core/utils/formatting_core.dart

import 'package:intl/intl.dart';

/// =======================
/// FormattingCore (PURE DART)
/// =======================
/// Currency formatting with explicit locale and currency code.
/// No Flutter dependencies.
/// =======================

class FormattingCore {
  FormattingCore._();

  /// Format currency with explicit locale and currency code.
  /// Example: formatCurrency(1234.56, locale: 'en_US', currency: 'USD')
  static String formatCurrency(
    num amount, {
    required String locale,
    String currency = 'USD',
  }) {
    final format = NumberFormat.currency(
      locale: locale,
      symbol: _getCurrencySymbol(currency),
      decimalDigits: _getDecimalDigits(currency),
    );
    return format.format(amount);
  }

  /// Helper: map currency code to symbol
  static String _getCurrencySymbol(String currency) {
    switch (currency) {
      case 'USD':
        return '\$';
      case 'EUR':
        return '€';
      case 'GBP':
        return '£';
      case 'JPY':
        return '¥';
      default:
        return currency;
    }
  }

  /// Helper: decimal digits per currency
  static int _getDecimalDigits(String currency) {
    switch (currency) {
      case 'JPY':
        return 0;
      default:
        return 2;
    }
  }

  /// Simple fallback (for testing or non-UI contexts)
  static String formatCurrencySimple(num amount, [String currency = 'USD']) {
    final symbol = _getCurrencySymbol(currency);
    final digits = _getDecimalDigits(currency);
    return '$symbol${amount.toStringAsFixed(digits)}';
  }
}
