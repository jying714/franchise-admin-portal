// 📁 lib/core/services/franchise_subscription_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/franchise_subscription_model.dart';
import '../models/platform_plan_model.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FranchiseSubscriptionService {
  final FirebaseFirestore _db;

  FranchiseSubscriptionService({FirebaseFirestore? firestoreInstance})
      : _db = firestoreInstance ?? FirebaseFirestore.instance;

  // ===========================================================================
  // 🔥 Franchise Subscription – Core Lifecycle
  // ===========================================================================

  /// Subscribe a franchise to a new platform plan. Deactivates any active subscription first.
  Future<void> subscribeFranchiseToPlan({
    required String franchiseId,
    required PlatformPlan plan,
  }) async {
    final batch = _db.batch();
    final subscriptionsRef = _db.collection('franchise_subscriptions');

    try {
      // 🔁 Cancel existing active subscriptionso
      final existing = await subscriptionsRef
          .where('franchiseId', isEqualTo: franchiseId)
          .where('active', isEqualTo: true)
          .get();

      for (final doc in existing.docs) {
        batch.update(doc.reference, {
          'active': false,
          'status': 'cancelled',
          'cancelledAt': FieldValue.serverTimestamp(),
        });
      }

      // 🆕 Create new subscription
      final newRef = subscriptionsRef.doc();
      final billingCycleDays = plan.billingInterval == 'yearly' ? 365 : 30;

      final newSubscriptionData = {
        'franchiseId': franchiseId,
        'platformPlanId': plan.id,
        'subscribedAt': FieldValue.serverTimestamp(),
        'startDate': FieldValue.serverTimestamp(),
        'nextBillingDate': Timestamp.fromDate(
          DateTime.now().add(Duration(days: billingCycleDays)),
        ),
        'billingCycleInDays': billingCycleDays,
        'billingInterval': plan.billingInterval,
        'autoRenew': true,
        'priceAtSubscription': plan.price,
        'active': true,
        'status': 'active',
        'planSnapshot': {
          'name': plan.name,
          'description': plan.description,
          'features': plan.features,
          'currency': plan.currency,
          'price': plan.price,
          'billingInterval': plan.billingInterval,
          'isCustom': plan.isCustom,
          'planVersion': plan.planVersion ?? 'v1',
        },
        'paymentProviderCustomerId': null,
        'cardLast4': null,
        'cardBrand': null,
        'paymentMethodId': null,
        'billingEmail': null,
        'paymentStatus': null,
        'receiptUrl': null,
      };

      debugPrint(
          '[🔥DEBUG] Writing subscription for franchiseId=$franchiseId with planId=${plan.id}');
      batch.set(newRef, newSubscriptionData);

      // 🌱 Seed feature_metadata from plan features
      // final Map<String, dynamic> featureMetadata = {
      //   'modules': {
      //     for (final featureKey in plan.features)
      //       featureKey: {
      //         'enabled': true,
      //         'features': {'enabled': true},
      //       },
      //   },
      //   'updatedAt': FieldValue.serverTimestamp(),
      // };

      await updateFeatureMetadataForPlanChange(
        franchiseId: franchiseId,
        grantedFeatures: plan.features,
      );

      // 🧾 Commit both subscription and feature writes
      await batch.commit();
      debugPrint('[🔥DEBUG] Subscription + feature metadata committed ✅');

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

  /// Update an existing franchise subscription (merge)
  Future<void> updateFranchiseSubscription({
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = _db.collection('franchise_subscriptions').doc(documentId);
      await docRef.set(data, SetOptions(merge: true));

      // 🔍 Optional logic: sync feature metadata if features or plan changed
      final franchiseId = data['franchiseId'];
      final planSnapshot = data['planSnapshot'];
      final updatedFeatures = planSnapshot?['features'];

      if (franchiseId != null &&
          updatedFeatures is List &&
          updatedFeatures.isNotEmpty) {
        await updateFeatureMetadataForPlanChange(
          franchiseId: franchiseId,
          grantedFeatures: List<String>.from(updatedFeatures),
        );
      }
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to update franchise subscription',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionService',
        screen: 'updateFranchiseSubscription',
        severity: 'error',
        contextData: {'exception': e.toString(), 'inputData': data},
      );
      rethrow;
    }
  }

  Future<void> updateFeatureMetadataForPlanChange({
    required String franchiseId,
    required List<String> grantedFeatures,
  }) async {
    final docRef = _db
        .collection('franchises')
        .doc(franchiseId)
        .collection('feature_metadata')
        .doc(franchiseId);

    // ⛔ Features are GRANTED, but disabled by default
    final Map<String, dynamic> newMetadata = {
      for (final featureKey in grantedFeatures)
        featureKey: {
          'enabled': false, // <- toggled during onboarding
          'features': {},
        },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(newMetadata);
  }

  /// Save (create or overwrite) a subscription (move from FirestoreService)
  Future<void> saveFranchiseSubscription(
      FranchiseSubscription subscription) async {
    try {
      final docRef = subscription.id.isNotEmpty
          ? _db.collection('franchise_subscriptions').doc(subscription.id)
          : _db
              .collection('franchise_subscriptions')
              .doc(); // Will generate new ID

      await docRef.set(
        subscription.toFirestore(),
        SetOptions(merge: true),
      );

      debugPrint(
          '[FranchiseSubscriptionService] Saved subscription: ${docRef.id}');
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to save franchise subscription',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionService',
        screen: 'saveFranchiseSubscription',
        severity: 'error',
        contextData: {
          'subscriptionId': subscription.id,
          'franchiseId': subscription.franchiseId,
        },
      );
      rethrow;
    }
  }

  /// Delete a specific franchise subscription
  Future<void> deleteFranchiseSubscription(String id) async {
    try {
      await _db.collection('franchise_subscriptions').doc(id).delete();
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to delete franchise_subscription $id',
        stack: st.toString(),
        source: 'FranchiseSubscriptionService',
        screen: 'deleteFranchiseSubscription',
        severity: 'error',
        contextData: {'subscriptionId': id, 'exception': e.toString()},
      );
      rethrow;
    }
  }

  /// Batch delete multiple franchise subscriptions (move from FirestoreService)
  Future<void> deleteManyFranchiseSubscriptions(List<String> ids) async {
    final batch = _db.batch();

    try {
      for (final id in ids) {
        final docRef = _db.collection('franchise_subscriptions').doc(id);
        batch.delete(docRef);
      }

      await batch.commit();
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to delete multiple franchise subscriptions',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionService',
        screen: 'deleteManyFranchiseSubscriptions',
        severity: 'error',
        contextData: {'ids': ids, 'exception': e.toString()},
      );
      rethrow;
    }
  }

  // ===========================================================================
  // 🔎 Franchise Subscription – Queries
  // ===========================================================================

  /// Get all subscriptions (admin/global access)
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

  /// Stream all subscriptions in real-time (for dev tools UI)
  Stream<List<FranchiseSubscription>> watchAllFranchiseSubscriptions() {
    return _db
        .collection('franchise_subscriptions')
        .orderBy('subscribedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FranchiseSubscription.fromMap(doc.id, doc.data()))
            .toList());
  }

  /// Get current (active) subscription for franchise
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

  /// Get active subscription (older alt logic with `.active`)
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

  /// Stream active subscription for a franchise
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

  /// Get subscription by Firestore document ID

  // ===========================================================================
  // 📦 Platform Plans – Management + Resolution
  // ===========================================================================

  /// Get a platform plan by ID
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

  /// Get all platform plans
  Future<List<PlatformPlan>> getAllPlatformPlans() async {
    try {
      debugPrint(
          '[FranchiseSubscriptionService] getAllPlatformPlans: Fetching...');
      final snap = await _db.collection('platform_plans').get();

      final plans = snap.docs.map((doc) {
        final plan = PlatformPlan.fromMap(doc.id, doc.data());
        debugPrint('[FranchiseSubscriptionService] Loaded plan: ${plan.name}');
        return plan;
      }).toList();

      debugPrint('[FranchiseSubscriptionService] Total plans: ${plans.length}');
      return plans;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Error loading platform plans: $e',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionService',
        screen: 'getAllPlatformPlans',
        severity: 'error',
      );
      return [];
    }
  }

  Future<List<PlatformPlan>> getPlatformPlans() async {
    try {
      debugPrint(
          '[FranchiseSubscriptionService] getPlatformPlans: Fetching all plans...');
      final snap = await _db.collection('platform_plans').get();

      debugPrint(
          '[FranchiseSubscriptionService] Retrieved ${snap.docs.length} documents');

      final plans = snap.docs.map((doc) {
        final plan = PlatformPlan.fromMap(doc.id, doc.data());
        debugPrint(
            '[FranchiseSubscriptionService] Plan loaded: ${plan.name} (active: ${plan.active})');
        return plan;
      }).toList();

      debugPrint('[FranchiseSubscriptionService] Parsed ${plans.length} plans');
      return plans;
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Error loading platform plans: $e',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionService',
        screen: 'getPlatformPlans',
        severity: 'error',
      );
      return [];
    }
  }
}
