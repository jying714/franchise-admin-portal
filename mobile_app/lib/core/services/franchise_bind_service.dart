import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_mobile_app/core/utils/app_local_storage.dart';
import 'package:franchise_mobile_app/features/main_menu/main_menu_screen.dart';
import 'package:franchise_mobile_app/main.dart' show IngredientMetadataProvider;

/// Single bind pipeline for customer franchise context (Decision 11).
class FranchiseBindService {
  FranchiseBindService._();

  static const String _recentsKey = 'franchiseRecents';
  static const int _maxRecents = 8;

  /// Bind [franchiseId], optional cart clear on cross-franchise switch,
  /// branding reload, recents, optional navigate to MainMenu.
  /// Returns true on success; false if user cancels cart dialog or id invalid.
  static Future<bool> bind(
    BuildContext context,
    String franchiseId, {
    bool navigateToMainMenu = true,
  }) async {
    final id = franchiseId.trim();
    if (id.isEmpty || id == 'unknown' || id.contains('/')) return false;

    final fp = Provider.of<shared.FranchiseProvider>(context, listen: false);
    final fromId = fp.currentFranchiseId;

    // CF5: leaving a different franchise with a non-empty cart → confirm + clear.
    if (fromId.isNotEmpty && fromId != 'unknown' && fromId != id) {
      final cleared = await _confirmAndClearCartIfNeeded(context, fromId);
      if (!cleared) return false;
      if (!context.mounted) return false;
    }

    await fp.setFranchiseId(id);
    await _recordRecent(id);

    try {
      final ingredients =
          Provider.of<IngredientMetadataProvider>(context, listen: false);
      await ingredients.reloadForFranchise(id);
    } catch (_) {}

    try {
      final doc = await FirebaseFirestore.instance
          .collection('franchises')
          .doc(id)
          .get();
      if (doc.exists && doc.data() != null) {
        fp.setBrandingFromFranchiseDoc(doc.data()!);
      }
    } catch (_) {}

    if (!context.mounted) return true;

    if (navigateToMainMenu) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainMenuScreen()),
        (route) => false,
      );
    }
    return true;
  }

  static Future<List<String>> getRecents() {
    return AppLocalStorage().getStringListAsync(_recentsKey);
  }

  static Future<void> _recordRecent(String franchiseId) async {
    final storage = AppLocalStorage();
    final existing = await storage.getStringListAsync(_recentsKey);
    final next = <String>[
      franchiseId,
      ...existing.where((id) => id != franchiseId),
    ];
    if (next.length > _maxRecents) {
      next.removeRange(_maxRecents, next.length);
    }
    await storage.setStringList(_recentsKey, next);
  }

  /// Returns true if safe to proceed (no cart, empty cart, or user confirmed clear).
  /// Returns false if user cancels.
  static Future<bool> _confirmAndClearCartIfNeeded(
    BuildContext context,
    String fromFranchiseId,
  ) async {
    final user = FirebaseAuth.instance.currentUser;
    // Signed-out: cart UI already gated; nothing to clear.
    if (user == null) return true;

    final firestore =
        Provider.of<shared.FirestoreService>(context, listen: false);

    shared.Order? cart;
    try {
      cart =
          await firestore.getCart(user.uid, franchiseId: fromFranchiseId).first;
    } catch (_) {
      return true; // fail open — do not block switch on cart read errors
    }

    if (cart == null || cart.items.isEmpty) return true;
    if (!context.mounted) return false;

    final proceed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          title: const Text('Switch restaurant?'),
          content: const Text(
            'Your cart has items for the current restaurant. '
            'Switching will clear that cart. Continue?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(false),
              child: const Text('Cancel'),
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: scheme.error),
              onPressed: () => Navigator.of(ctx).pop(true),
              child: const Text('Clear cart & switch'),
            ),
          ],
        );
      },
    );

    if (proceed != true) return false;

    try {
      await firestore.updateCart(cart.copyWith(items: []));
    } catch (_) {
      // Still allow switch; empty cart is best-effort.
    }
    return true;
  }
}
