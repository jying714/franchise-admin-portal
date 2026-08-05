import 'dart:convert';

import 'package:crypto/crypto.dart';

/// PIN verifier helpers. Store only [hashPin] output on Staff.pinHash.
/// Format: `v1:<saltHex>:<sha256Hex>` — must match POS unlock.
class PinHash {
  PinHash._();

  static String hashPin(String pin, {String? saltHex}) {
    final salt =
        saltHex ?? DateTime.now().microsecondsSinceEpoch.toRadixString(16);
    final bytes = utf8.encode('$salt:$pin');
    final digest = sha256.convert(bytes);
    return 'v1:$salt:${digest.toString()}';
  }

  static bool verify(String pin, String? stored) {
    if (stored == null || stored.isEmpty) return false;
    final parts = stored.split(':');
    if (parts.length != 3 || parts[0] != 'v1') return false;
    final salt = parts[1];
    final expected = parts[2];
    final bytes = utf8.encode('$salt:$pin');
    final actual = sha256.convert(bytes).toString();
    return actual == expected;
  }
}
