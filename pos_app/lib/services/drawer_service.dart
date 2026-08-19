import 'package:flutter/foundation.dart';
import 'package:flutter_star_prnt_plus/flutter_star_prnt.dart';
import 'pos_printer_config.dart';

/// Cash drawer via the receipt TSP100 DK port (Star Graphic).
/// Console always; LAN kick when POS_PRINTER_HOST is set. Never throws.
class DrawerService {
  const DrawerService();

  String get _effectiveHost => PosPrinterConfig.host;

  /// Open drawer. Never throws into payment / refund paths.
  Future<bool> openDrawer({String? reason}) async {
    final label = reason == null || reason.isEmpty ? 'kick' : reason;
    // ignore: avoid_print
    print('[POS][drawer] $label');
    debugPrint('[POS][drawer] $label');

    final host = _effectiveHost;
    if (host.isEmpty) {
      return true;
    }

    try {
      final commands = PrintCommands();
      commands.push(<String, dynamic>{'openCashDrawer': 1});
      await StarPrnt.sendCommands(
        portName: 'TCP:$host',
        emulation: 'StarGraphic',
        printCommands: commands,
      );
      debugPrint('[POS][drawer] StarGraphic ok → TCP:$host');
    } catch (e, st) {
      debugPrint('[POS][drawer] StarGraphic failed (TCP:$host): $e\n$st');
    }
    return true;
  }
}
