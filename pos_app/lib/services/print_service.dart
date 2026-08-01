import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

/// Mock kitchen / receipt printer for pilot.
/// Real ESC/POS or cloud print comes later — do not invent hardware config fields yet.
class PrintService {
  const PrintService();

  /// Kitchen ticket when an order is sent to kitchen (or paid → kitchen).
  /// Never throws into the order path; failures are logged only.
  Future<bool> printKitchenTicket({
    required Order order,
    String? tableLabel,
    bool isAppend = false,
  }) async {
    try {
      final body = _formatKitchenTicket(
        order: order,
        tableLabel: tableLabel,
        isAppend: isAppend,
      );
      // ignore: avoid_print
      print(body);
      debugPrint(body);
      return true;
    } catch (e, st) {
      debugPrint('[POS] kitchen ticket mock failed: $e\n$st');
      return false;
    }
  }

  String _formatKitchenTicket({
    required Order order,
    String? tableLabel,
    required bool isAppend,
  }) {
    final buf = StringBuffer();
    buf.writeln('======== KITCHEN TICKET (MOCK) ========');
    if (isAppend) buf.writeln('*** ADD-ON / APPEND ***');
    buf.writeln('Order: ${order.id}');
    buf.writeln('Type:  ${order.deliveryType}');
    if (tableLabel != null && tableLabel.isNotEmpty) {
      buf.writeln('Table: $tableLabel');
    }
    final name = order.userNameDisplay.trim();
    if (name.isNotEmpty) buf.writeln('Name:  $name');
    buf.writeln('--------------------------------------');
    for (final item in order.items) {
      buf.writeln('${item.quantity}x ${item.name}');
      if (item.customizations.isNotEmpty) {
        for (final e in item.customizations.entries) {
          buf.writeln('   - ${e.key}: ${e.value}');
        }
      }
    }
    buf.writeln('--------------------------------------');
    buf.writeln('Items: ${order.items.length}');
    buf.writeln('======================================');
    return buf.toString();
  }

  /// Customer receipt after successful cash / split pay.
  /// Mock only — real printer later.
  Future<bool> printCustomerReceipt({
    required Order order,
    required double amountTendered,
    required double changeDue,
    required String paymentMethod,
  }) async {
    try {
      final body = _formatCustomerReceipt(
        order: order,
        amountTendered: amountTendered,
        changeDue: changeDue,
        paymentMethod: paymentMethod,
      );
      // ignore: avoid_print
      print(body);
      debugPrint(body);
      return true;
    } catch (e, st) {
      debugPrint('[POS] customer receipt mock failed: $e\n$st');
      return false;
    }
  }

  String _formatCustomerReceipt({
    required Order order,
    required double amountTendered,
    required double changeDue,
    required String paymentMethod,
  }) {
    final buf = StringBuffer();
    buf.writeln('======= CUSTOMER RECEIPT (MOCK) =======');
    buf.writeln('Order: ${order.id}');
    buf.writeln('Type:  ${order.deliveryType}');
    final name = order.userNameDisplay.trim();
    if (name.isNotEmpty) buf.writeln('Name:  $name');
    buf.writeln('--------------------------------------');
    for (final item in order.items) {
      final line = item.price * item.quantity;
      buf.writeln(
        '${item.quantity}x ${item.name}  \$${line.toStringAsFixed(2)}',
      );
    }
    buf.writeln('--------------------------------------');
    buf.writeln('Subtotal  \$${order.subtotal.toStringAsFixed(2)}');
    if (order.discount > 0) {
      buf.writeln('Discount -\$${order.discount.toStringAsFixed(2)}');
    }
    buf.writeln('Tax       \$${order.tax.toStringAsFixed(2)}');
    if (order.deliveryFee > 0) {
      buf.writeln('Delivery  \$${order.deliveryFee.toStringAsFixed(2)}');
    }
    buf.writeln('TOTAL     \$${order.total.toStringAsFixed(2)}');
    buf.writeln('--------------------------------------');
    buf.writeln('Paid:     $paymentMethod');
    buf.writeln('Tendered  \$${amountTendered.toStringAsFixed(2)}');
    buf.writeln('Change    \$${changeDue.toStringAsFixed(2)}');
    buf.writeln('======================================');
    return buf.toString();
  }
}
