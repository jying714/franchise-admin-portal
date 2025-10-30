import 'package:admin_portal/core/models/franchise_subscription_model.dart';
import 'package:admin_portal/core/models/enriched/enriched_franchise_subscription.dart';
import 'package:admin_portal/core/models/user.dart' as app_user;
import 'package:admin_portal/core/models/franchise_info.dart';
import 'package:admin_portal/core/services/firestore_service.dart';
import 'package:admin_portal/core/utils/error_logger.dart';
import 'package:flutter/material.dart';

/// Utility to batch enrich franchise subscriptions with franchise + owner data.
class FranchiseSubscriptionEnricher {
  final FirestoreService firestoreService;

  FranchiseSubscriptionEnricher(this.firestoreService);

  /// Fetches enriched data for all franchise subscriptions.
  Future<List<EnrichedFranchiseSubscription>> enrichAllSubscriptions() async {
    try {
      final subscriptions =
          await firestoreService.getAllFranchiseSubscriptions();
      final franchiseIds = subscriptions.map((s) => s.franchiseId).toSet();

      final franchises = await firestoreService.fetchFranchiseList();
      final Map<String, FranchiseInfo> franchiseMap = {
        for (final f in franchises) f.id: f
      };

      final users = await firestoreService.getAllUsers();
      final Map<String, app_user.User> tempMap = {};
      for (final u in users) {
        for (final fid in u.franchiseIds) {
          tempMap.putIfAbsent(
              fid, () => u); // inserts only first user per franchise
        }
      }
      final ownerMap = tempMap;
      debugPrint('[Enricher] Loaded ${users.length} users for owner mapping');
      for (final entry in ownerMap.entries) {
        debugPrint(
          '[Enricher] FranchiseId: ${entry.key} → Owner: ${entry.value.name} (${entry.value.email})',
        );
      }

      return subscriptions.map((sub) {
        return EnrichedFranchiseSubscription(
          subscription: sub,
          franchise: franchiseMap[sub.franchiseId],
          owner: ownerMap[sub.franchiseId],
        );
      }).toList();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to enrich subscriptions',
        source: 'FranchiseSubscriptionEnricher',
        screen: 'franchise_subscription_enricher',
        severity: 'error',
        stack: stack.toString(),
      );
      return [];
    }
  }
}
