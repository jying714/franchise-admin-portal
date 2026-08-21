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

  static bool kitchenHasTicket(String status) {
    switch (status.trim().toLowerCase()) {
      case OrderStatus.draft:
      case OrderStatus.open:
      case OrderStatus.needsApproval:
      case '':
        return false;
      default:
        // sent_to_kitchen, ready, completed, cancelled, etc.
        // If kitchen already saw the ticket, void must print.
        return true;
    }
  }

  /// VOID chit after a ticket was already sent to kitchen.
  Future<bool> printKitchenVoid({
    required Order order,
    String? tableLabel,
    List<OrderItem>? onlyItems,
  }) async {
    try {
      final body = _formatKitchenVoid(
        order: order,
        tableLabel: tableLabel,
        onlyItems: onlyItems,
      );
      return _emit(role: PosPrintRole.kitchen, body: body);
    } catch (e, st) {
      debugPrint('[POS] kitchen VOID failed: $e\n$st');
      return false;
    }
  }

  String _formatKitchenVoid({
    required Order order,
    String? tableLabel,
    List<OrderItem>? onlyItems,
  }) {
    final buf = StringBuffer();
    buf.writeln('========== VOID ==========');
    final store = PosPrinterConfig.storeName;
    if (store.isNotEmpty) buf.writeln(store);
    buf.writeln('Time:  ${_stamp(DateTime.now())}');
    buf.writeln('Order: ${_shortOrderId(order.id)}');
    buf.writeln('Type:  ${_typeLabel(order.deliveryType)}');
    if (tableLabel != null && tableLabel.isNotEmpty) {
      buf.writeln('Table: $tableLabel');
    }
    final name = order.userNameDisplay.trim();
    if (name.isNotEmpty) buf.writeln('Name:  $name');
    buf.writeln('--------------------------------------');
    final lines = onlyItems ?? order.items;
    if (onlyItems == null) {
      buf.writeln('*** VOID ENTIRE TICKET ***');
    } else {
      buf.writeln('*** VOID ITEM ***');
    }
    for (final item in lines) {
      buf.writeln('${item.quantity}x ${item.name}');
      if (item.customizations.isNotEmpty) {
        for (final e in item.customizations.entries) {
          final line = _modLine(e.key, e.value);
          if (line != null) buf.writeln(line);
        }
      }
    }
    buf.writeln('======================================');
    return buf.toString();
  }

  Future<bool> printKitchenUpdate({
    required Order order,
    required List<OrderItem> onlyItems,
    String? tableLabel,
  }) async {
    try {
      final body = _formatKitchenUpdate(
        order: order,
        onlyItems: onlyItems,
        tableLabel: tableLabel,
      );
      return _emit(role: PosPrintRole.kitchen, body: body);
    } catch (e, st) {
      debugPrint('[POS] kitchen UPDATE failed: $e\n$st');
      return false;
    }
  }

  String _formatKitchenUpdate({
    required Order order,
    required List<OrderItem> onlyItems,
    String? tableLabel,
  }) {
    final buf = StringBuffer();
    buf.writeln('========== UPDATE ==========');
    final store = PosPrinterConfig.storeName;
    if (store.isNotEmpty) buf.writeln(store);
    buf.writeln('Time:  ${_stamp(DateTime.now())}');
    buf.writeln('Order: ${_shortOrderId(order.id)}');
    buf.writeln('Type:  ${_typeLabel(order.deliveryType)}');
    if (tableLabel != null && tableLabel.isNotEmpty) {
      buf.writeln('Table: $tableLabel');
    }
    final name = order.userNameDisplay.trim();
    if (name.isNotEmpty) buf.writeln('Name:  $name');
    buf.writeln('--------------------------------------');
    buf.writeln('*** ITEM UPDATE ***');
    for (final item in onlyItems) {
      buf.writeln('${item.quantity}x ${item.name}');
      if (item.customizations.isNotEmpty) {
        for (final e in item.customizations.entries) {
          if (e.key == 'voidedAddOns') continue;
          final line = _modLine(e.key, e.value);
          if (line != null) buf.writeln(line);
        }
        final voided = item.customizations['voidedAddOns'];
        if (voided is List && voided.isNotEmpty) {
          final parts = voided
              .map((e) => e.toString().trim())
              .where((s) => s.isNotEmpty)
              .toList();
          if (parts.isNotEmpty) {
            buf.writeln('   - VOIDED: ${parts.join(', ')}');
          }
        }
      }
    }
    buf.writeln('======================================');
    return buf.toString();
  }

  String _formatKitchenTicket({
    required Order order,
    String? tableLabel,
    required bool isAppend,
  }) {
    final buf = StringBuffer();
    buf.writeln('======== KITCHEN TICKET ========');
    final store = PosPrinterConfig.storeName;
    if (store.isNotEmpty) buf.writeln(store);
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
      final status = item.lineStatus.trim().toLowerCase();
      if (status == 'voided' || status == 'comped') continue;
      buf.writeln('${item.quantity}x ${item.name}');
      for (final line in _itemSideLines(item)) {
        buf.writeln(line);
      }
    }
    buf.writeln('--------------------------------------');
    buf.writeln('Items: ${order.items.length}');
    buf.writeln('======================================');
    return buf.toString();
  }

  static bool _isDetailKey(String key) {
    final k = key.trim().toLowerCase();
    return k == 'crust' || k == 'cook' || k == 'cut' || k == 'size';
  }

  List<String> _itemSideLines(OrderItem item) {
    final c = item.customizations;
    final portions = <String, String>{};
    final rawP = c['portions'];
    if (rawP is Map) {
      rawP.forEach((k, v) {
        portions[k.toString()] = v.toString().toLowerCase();
      });
    }
    final doubles = <String>{};
    final rawD = c['doubles'];
    if (rawD is Map) {
      rawD.forEach((k, v) {
        if (v == true) doubles.add(k.toString());
      });
    }

    final labels = <String, String>{};
    final rawL = c['optionLabels'];
    if (rawL is Map) {
      rawL.forEach((k, v) {
        labels[k.toString()] = v.toString();
      });
    }
    String nameOf(String id) => labels[id] ?? id;

    String decorate(String id) {
      final n = nameOf(id);
      return doubles.contains(id) ? '$n DOUBLE' : n;
    }

    final whole = <String>[];
    final left = <String>[];
    final right = <String>[];
    final details = <String>[];

    c.forEach((k, v) {
      if (k == 'addonPrices' ||
          k == 'portions' ||
          k == 'doubles' ||
          k == '_linePrice' ||
          k == 'voidedAddOns' ||
          k == 'wingHalves' ||
          k == 'optionLabels' ||
          k == 'wing_sauce') {
        return;
      }
      if (_isDetailKey(k)) {
        if (v is List) {
          details.add('$k: ${v.join(', ')}');
        } else if (v != null && v.toString().trim().isNotEmpty) {
          details.add('$k: $v');
        }
        return;
      }
      if (v is! List) return;
      for (final e in v) {
        final id = e.toString().trim();
        if (id.isEmpty) continue;
        final p = portions[id] ?? 'whole';
        final line = decorate(id);
        if (p == 'left') {
          left.add(line);
        } else if (p == 'right') {
          right.add(line);
        } else {
          whole.add(line);
        }
      }
    });

    final out = <String>[];
    for (final d in details) {
      out.add('   $d');
    }
    final halves = c['wingHalves'];
    if (halves is Map) {
      String halfName(Object? v) {
        final s = v?.toString() ?? '';
        if (s.isEmpty || s == 'plain') return 'Plain';
        return nameOf(s);
      }

      if (halves['a'] != null) {
        out.add('   HALF 1  ${halfName(halves['a'])}');
      }
      if (halves['b'] != null) {
        out.add('   HALF 2  ${halfName(halves['b'])}');
      }
    }
    if (whole.isNotEmpty) {
      out.add('   WHOLE');
      for (final l in whole) {
        out.add('      $l');
      }
    }
    if (left.isNotEmpty) {
      out.add('   LEFT');
      for (final l in left) {
        out.add('      $l');
      }
    }
    if (right.isNotEmpty) {
      out.add('   RIGHT');
      for (final l in right) {
        out.add('      $l');
      }
    }
    return out;
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
    final store = PosPrinterConfig.storeName;
    if (store.isNotEmpty) buf.writeln(store);
    buf.writeln('Time:  ${_stamp(DateTime.now())}');
    buf.writeln('Order: ${_shortOrderId(order.id)}');
    buf.writeln('Type:  ${_typeLabel(order.deliveryType)}');
    final name = order.userNameDisplay.trim();
    if (name.isNotEmpty) buf.writeln('Name:  $name');
    buf.writeln('--------------------------------------');
    for (final item in order.items) {
      final status = item.lineStatus.trim().toLowerCase();
      if (status == 'voided' || status == 'comped') continue;
      final line = item.effectiveLineTotal;
      buf.writeln(
        '${item.quantity}x ${item.name}  \$${line.toStringAsFixed(2)}',
      );
      for (final side in _itemSideLines(item)) {
        buf.writeln(side);
      }
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
    buf.writeln('--------------------------------------');
    buf.writeln('Thank you!');
    buf.writeln('======================================');
    return buf.toString();
  }
}
