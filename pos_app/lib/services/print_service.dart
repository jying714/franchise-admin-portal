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

  static String _shortOrderId(String id) {
    final t = id.trim();
    if (t.length <= 8) return t;
    return t.substring(t.length - 8);
  }

  static String _stamp(DateTime dt) {
    String two(int n) => n.toString().padLeft(2, '0');
    return '${dt.year}-${two(dt.month)}-${two(dt.day)} '
        '${two(dt.hour)}:${two(dt.minute)}';
  }

  /// Settings smoke: one page, same StarGraphic path as tickets.
  Future<bool> printTestPage() async {
    try {
      return _emit(
        role: PosPrintRole.receipt,
        body: [
          '======== TEST PAGE ========',
          'FranchiseHQ POS',
          'Host: ${PosPrinterConfig.host}',
          'Time: ${DateTime.now().toIso8601String()}',
          '======================================',
        ].join('\n'),
      );
    } catch (e, st) {
      debugPrint('[POS] test page failed: $e\n$st');
      return false;
    }
  }

  static String _typeLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'dine_in':
      case 'dinein':
        return 'Dine-in';
      case 'carry_out':
      case 'carryout':
      case 'pickup':
        return 'Carry-out';
      case 'delivery':
        return 'Delivery';
      default:
        return raw.trim().isEmpty ? '—' : raw.trim();
    }
  }

  static String _payLabel(String raw) {
    switch (raw.trim().toLowerCase()) {
      case 'card':
      case 'stripe':
        return 'Card';
      case 'cash':
        return 'Cash';
      case 'split':
        return 'Split';
      default:
        return raw.trim().isEmpty ? '—' : raw.trim();
    }
  }

  static String? _modLine(String key, Object? value) {
    final k = key.trim();
    if (k.isEmpty) return null;
    if (value == null) return null;
    if (value is List) {
      final parts = value
          .map((e) => e.toString().trim())
          .where((s) => s.isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return '   - $k: ${parts.join(', ')}';
    }
    if (value is Map) {
      final parts = value.entries
          .map((e) => '${e.key}: ${e.value}')
          .where((s) => s.trim().isNotEmpty)
          .toList();
      if (parts.isEmpty) return null;
      return '   - $k: ${parts.join(', ')}';
    }
    final s = value.toString().trim();
    if (s.isEmpty || s == '[]' || s == '{}') return null;
    final unwrapped = (s.startsWith('[') && s.endsWith(']'))
        ? s.substring(1, s.length - 1).trim()
        : s;
    if (unwrapped.isEmpty) return null;
    return '   - $k: $unwrapped';
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
    buf.writeln('Time:  ${_stamp(DateTime.now())}');
    buf.writeln('Order: ${_shortOrderId(order.id)}');
    buf.writeln('Type:  ${_typeLabel(order.deliveryType)}');
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
          final line = _modLine(e.key, e.value);
          if (line != null) buf.writeln(line);
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
    buf.writeln('Time:  ${_stamp(DateTime.now())}');
    buf.writeln('Order: ${_shortOrderId(order.id)}');
    buf.writeln('Type:  ${_typeLabel(order.deliveryType)}');
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
    buf.writeln('Paid:     ${_payLabel(paymentMethod)}');
    final method = paymentMethod.trim().toLowerCase();
    final isCard = method == 'card' || method == 'stripe';
    if (!isCard) {
      buf.writeln('Tendered  \$${amountTendered.toStringAsFixed(2)}');
      buf.writeln('Change    \$${changeDue.toStringAsFixed(2)}');
    }
    buf.writeln('======================================');
    return buf.toString();
  }
}
