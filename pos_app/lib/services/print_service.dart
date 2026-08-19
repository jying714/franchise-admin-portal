import 'package:flutter/foundation.dart';
import 'package:flutter_star_prnt_plus/flutter_star_prnt.dart';
import 'package:shared_core/shared_core.dart';
import 'pos_printer_config.dart';

/// Print roles for routing (Admin category map comes later).
enum PosPrintRole { kitchen, receipt }

/// Station print entry point.
/// Dev / no-paper: always emit full ticket to console.
/// Later: same methods try LAN (TSP100) then fall back to console — order path never throws.
class PrintService {
  /// Optional LAN host/IP for TSP100 (or any raw-9100 printer).
  /// Prefer `--dart-define=POS_PRINTER_HOST=192.168.x.x` for station builds.
  final String? host;

  const PrintService({this.host});

  String get _effectiveHost {
    final fromField = host?.trim() ?? '';
    if (fromField.isNotEmpty) return fromField;
    return PosPrinterConfig.host;
  }

  /// Console is the guaranteed dev fail-safe (no paper / no LAN yet).
  /// When a host is configured later, try device first, then still console on failure.
  Future<bool> _emit({required PosPrintRole role, required String body}) async {
    final header = '[POS][print][${role.name}]';
    // Always console first (dev / no-paper fail-safe).
    // ignore: avoid_print
    print('$header\n$body');
    debugPrint('$header\n$body');

    final target = _effectiveHost;
    if (target.isEmpty) {
      return true;
    }

    try {
      await _sendStarGraphic(host: target, body: body);
      debugPrint('$header StarGraphic ok → TCP:$target');
    } catch (e, st) {
      debugPrint('$header StarGraphic failed (TCP:$target): $e\n$st');
    }
    return true;
  }

  /// TSP100 / TSP143 LAN: Star Raster (StarGraphic), not ESC/POS on 9100.
  Future<void> _sendStarGraphic({
    required String host,
    required String body,
  }) async {
    final commands = PrintCommands();
    commands.appendBitmapText(text: body);
    commands.appendCutPaper(StarCutPaperAction.FullCutWithFeed);
    await StarPrnt.sendCommands(
      portName: 'TCP:$host',
      emulation: 'StarGraphic',
      printCommands: commands,
    );
  }

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
      return _emit(role: PosPrintRole.kitchen, body: body);
    } catch (e, st) {
      debugPrint('[POS] kitchen ticket failed: $e\n$st');
      return false;
    }
  }

  String _formatKitchenTicket({
    required Order order,
    String? tableLabel,
    required bool isAppend,
  }) {
    final buf = StringBuffer();
    buf.writeln('======== KITCHEN TICKET ========');
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
      return _emit(role: PosPrintRole.receipt, body: body);
    } catch (e, st) {
      debugPrint('[POS] customer receipt failed: $e\n$st');
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
    buf.writeln('======= CUSTOMER RECEIPT =======');
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
