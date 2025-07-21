// 📁 lib/core/services/franchise_subscription_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:franchise_admin_portal/core/models/franchise_subscription_model.dart';
import 'package:franchise_admin_portal/core/models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FranchiseSubscriptionService {
  final FirebaseFirestore _db;

  FranchiseSubscriptionService({FirebaseFirestore? firestoreInstance})
      : _db = firestoreInstance ?? FirebaseFirestore.instance;

  /// Subscribe a franchise to a new platform plan. Deactivates any active subscription first.
  Future<void> subscribeFranchiseToPlan({
    required String franchiseId,
    required PlatformPlan plan,
  }) async {
    final batch = _db.batch();
    final subscriptionsRef = _db.collection('franchise_subscriptions');

    try {
      final existing = await subscriptionsRef
          .where('franchiseId', isEqualTo: franchiseId)
          .where('active', isEqualTo: true)
          .get();

      for (final doc in existing.docs) {
        batch.update(doc.reference, {
          'active': false,
          'status': 'cancelled', // 👈 Mark as no longer current
          'cancelledAt': FieldValue.serverTimestamp(), // optional timestamp
        });
      }

      final newRef = subscriptionsRef.doc();

      debugPrint(
          '[🔥DEBUG] Creating new subscription for franchiseId=$franchiseId with planId=${plan.id}');
      debugPrint('[🔥DEBUG] Subscription document ID: ${newRef.id}');

      final now = Timestamp.now();
      final billingCycleDays = plan.billingInterval == 'yearly' ? 365 : 30;

      final newSubscriptionData = {
        // 🔑 Identifiers & links
        'franchiseId': franchiseId,
        'platformPlanId': plan.id,

        // 🕒 Timestamps & state
        'subscribedAt': FieldValue.serverTimestamp(),
        'startDate': FieldValue.serverTimestamp(),
        'nextBillingDate': Timestamp.fromDate(
            DateTime.now().add(Duration(days: billingCycleDays))),

        // 🔁 Billing logic
        'billingCycleInDays': billingCycleDays,
        'billingInterval': plan.billingInterval,
        'autoRenew': true,

        // 💳 Price tracking
        'priceAtSubscription': plan.price,

        // 📌 State tracking
        'active': true,
        'status': 'active',

        // 📦 Immutable plan snapshot at signup time
        'planSnapshot': {
          'name': plan.name,
          'description': plan.description,
          'features': plan.includedFeatures,
          'currency': plan.currency,
          'price': plan.price,
          'billingInterval': plan.billingInterval,
          'isCustom': plan.isCustom,
          'planVersion': plan.planVersion ?? 'v1', // Optional default
        },
        // 💳 Merchant service metadata (placeholder defaults until real values assigned)
        'paymentProviderCustomerId': null,
        'cardLast4': null,
        'cardBrand': null,
        'paymentMethodId': null,
        'billingEmail': null,
        'paymentStatus': null,
        'receiptUrl': null,
      };

      debugPrint(
          '[🔥DEBUG] Writing subscription document with fields: $newSubscriptionData');

      batch.set(newRef, newSubscriptionData);

      debugPrint('[🔥DEBUG] Committing batch write...');
      await batch.commit();
      debugPrint('[🔥DEBUG] Batch commit complete ✅');

      await ErrorLogger.log(
        message: 'Franchise subscribed to platform plan',
        source: 'FranchiseSubscriptionService',
        screen: 'confirm_plan_subscription_dialog',
        severity: 'info',
        contextData: {
          'franchiseId': franchiseId,
          'planId': plan.id,
          'planName': plan.name,
        },
      );
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to subscribe franchise to plan: $e',
        source: 'FranchiseSubscriptionService',
        screen: 'confirm_plan_subscription_dialog',
        severity: 'error',
        stack: stack.toString(),
        contextData: {
          'franchiseId': franchiseId,
          'planId': plan.id,
        },
      );
      rethrow;
    }
  }

  /// Fetch all franchise subscriptions (platform-wide, admin access).
  Future<List<FranchiseSubscription>> getAllFranchiseSubscriptions() async {
    try {
      final snap = await _db.collection('franchise_subscriptions').get();
      final list = snap.docs
          .map((doc) => FranchiseSubscription.fromMap(doc.id, doc.data()))
          .toList();

      debugPrint(
          '[FranchiseSubscriptionService] Fetched ${list.length} subscriptions.');
      return list;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to fetch franchise subscriptions',
        source: 'FranchiseSubscriptionService',
        screen: 'platform_owner_dashboard',
        severity: 'error',
        stack: stack.toString(),
      );
      rethrow;
    }
  }

  /// Fetch the active subscription for a specific franchise
  Future<FranchiseSubscription?> getActiveSubscriptionForFranchise(
      String franchiseId) async {
    try {
      final snap = await _db
          .collection('franchise_subscriptions')
          .where('franchiseId', isEqualTo: franchiseId)
          .where('active', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;

      final doc = snap.docs.first;
      return FranchiseSubscription.fromMap(doc.id, doc.data());
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to get active subscription for franchise',
        source: 'FranchiseSubscriptionService',
        screen: 'franchise_subscription_check',
        severity: 'warning',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
  }

  Future<FranchiseSubscription?> getCurrentSubscription(
      String franchiseId) async {
    try {
      print(
          '[FranchiseSubscriptionService] getCurrentSubscription: Fetching for franchiseId=$franchiseId');
      final querySnapshot = await _db
          .collection('franchise_subscriptions')
          .where('franchiseId', isEqualTo: franchiseId)
          .where('status', isEqualTo: 'active')
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        print(
            '[FranchiseSubscriptionService] No active subscription found for franchiseId=$franchiseId');
        return null;
      }

      final doc = querySnapshot.docs.first;
      final sub = FranchiseSubscription.fromMap(doc.id, doc.data());
      print(
          '[FranchiseSubscriptionService] Loaded active subscription: ${sub.platformPlanId}');
      return sub;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Error loading active subscription: $e',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionService',
        screen: 'getCurrentSubscription',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
        },
      );
      return null;
    }
  }

  /// 🔄 Real-time stream of current subscription for a franchise
  Stream<FranchiseSubscription?> watchCurrentSubscription(String franchiseId) {
    try {
      print(
          '[FranchiseSubscriptionService] watchCurrentSubscription: Listening for franchiseId=$franchiseId');
      return _db
          .collection('franchise_subscriptions')
          .where('franchiseId', isEqualTo: franchiseId)
          .where('active', isEqualTo: true)
          .orderBy('startDate', descending: true)
          .limit(1)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isEmpty) {
          print(
              '[FranchiseSubscriptionService] Stream: No active subscription found.');
          return null;
        }

        final doc = snapshot.docs.first;
        final sub = FranchiseSubscription.fromMap(doc.id, doc.data());
        print(
            '[FranchiseSubscriptionService] Stream: Emitting active subscription: ${sub.platformPlanId}');
        return sub;
      }).handleError((error, stack) async {
        print('[FranchiseSubscriptionService] Stream error: $error');
        await ErrorLogger.log(
          message: 'Stream error in watchCurrentSubscription: $error',
          stack: stack.toString(),
          source: 'FranchiseSubscriptionService',
          screen: 'watchCurrentSubscription',
          severity: 'error',
          contextData: {
            'franchiseId': franchiseId,
          },
        );
      });
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to initialize watchCurrentSubscription: $e',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionService',
        screen: 'watchCurrentSubscription',
        severity: 'fatal',
        contextData: {
          'franchiseId': franchiseId,
        },
      );
      // Return an empty stream with null
      return Stream.value(null);
    }
  }

  Future<PlatformPlan?> getPlatformPlanById(String planId) async {
    try {
      final doc = await _db.collection('platform_plans').doc(planId).get();

      if (!doc.exists) {
        await ErrorLogger.log(
          message: 'PlatformPlan not found for ID: $planId',
          source: 'FranchiseSubscriptionService',
          screen: 'plan_resolution_fallback',
          severity: 'warning',
          contextData: {'missingId': planId},
          stack: '',
        );
        return null;
      }

      return PlatformPlan.fromFirestore(doc);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Error fetching PlatformPlan by ID: $planId',
        source: 'FranchiseSubscriptionService',
        screen: 'plan_resolution_fallback',
        stack: stack.toString(),
        severity: 'error',
        contextData: {
          'exception': e.toString(),
          'planId': planId,
        },
      );
      return null;
    }
  }
}
