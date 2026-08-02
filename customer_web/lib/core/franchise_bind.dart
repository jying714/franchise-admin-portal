// customer_web/lib/core/franchise_bind.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart' as shared;

import 'constants.dart';

/// Single bind pipeline for customer_web (Decision 11 parity).
///
/// Path bind is Phase 1. Hostname bind is a no-op stub until domain_index exists.
class FranchiseBind {
  FranchiseBind._();

  /// Bind by franchiseId from path /f/{id}.
  /// Loads franchise doc → setBrandingFromFranchiseDoc.
  /// Returns true on success.
  static Future<bool> bindById(
    shared.FranchiseProvider fp,
    String franchiseId,
  ) async {
    final id = franchiseId.trim();
    if (id.isEmpty || id == 'unknown' || id.contains('/')) {
      return false;
    }

    await fp.setFranchiseId(id);

    try {
      final doc = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        fp.setBrandingFromFranchiseDoc(doc.data()!);
      }
    } catch (e, st) {
      debugPrint('[FranchiseBind] branding load failed: $e\n$st');
      // Still keep the id bound; branding falls back to defaults.
    }
    return true;
  }

  /// Hostname → franchiseId (Phase 10+).
  /// Returns null until domain_index / storefrontDomain is implemented.
  /// Callers must not invent a silent default when this returns null.
  static Future<String?> resolveFranchiseIdFromHost(String host) async {
    final normalized = host.trim().toLowerCase();
    if (normalized.isEmpty ||
        normalized == 'localhost' ||
        normalized.endsWith('.web.app') ||
        normalized.endsWith('.firebaseapp.com')) {
      return null;
    }

    // Future:
    // final snap = await FirebaseFirestore.instance
    //     .collection(CustomerWebConstants.domainIndexCollection)
    //     .doc(normalized)
    //     .get();
    // return snap.data()?['franchiseId'] as String?;
    //
    // Or query franchises where storefrontDomain == normalized.
    debugPrint(
      '[FranchiseBind] hostname resolve stub — no domain_index yet: $normalized',
    );
    return null;
  }

  /// Cold-start helper: try path id first, else hostname, else null.
  static Future<String?> resolveInitialFranchiseId({
    String? pathFranchiseId,
    String? host,
  }) async {
    final fromPath = pathFranchiseId?.trim();
    if (fromPath != null &&
        fromPath.isNotEmpty &&
        fromPath != 'unknown' &&
        !fromPath.contains('/')) {
      return fromPath;
    }
    if (host != null && host.isNotEmpty) {
      return resolveFranchiseIdFromHost(host);
    }
    return null;
  }
}
