// web_app/lib/core/services/franchise_subscription_service_impl.dart
// CONCRETE FIRESTORE IMPLEMENTATION

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';

class FranchiseSubscriptionServiceImpl implements FranchiseSubscriptionService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  @override
  Future<void> subscribeFranchiseToPlan({
    required String franchiseId,
    required PlatformPlan plan,
  }) async {
    final batch = _db.batch();
    final subscriptionsRef = _db.collection('franchise_subscriptions');

    try {
      // Cancel existing active subscriptions
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

      // Create new subscription
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

      debugPrint('[DEBUG] Writing subscription for franchiseId=$franchiseId');
      batch.set(newRef, newSubscriptionData);

      await updateFeatureMetadataForPlanChange(
        franchiseId: franchiseId,
        grantedFeatures: plan.features,
      );

      await batch.commit();
      debugPrint('[DEBUG] Subscription + metadata committed');

      ErrorLogger.log(
        message: 'Franchise subscribed to platform plan',
        source: 'FranchiseSubscriptionServiceImpl',
        severity: 'info',
        contextData: {
          'franchiseId': franchiseId,
          'planId': plan.id,
        },
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to subscribe franchise to plan: $e',
        source: 'FranchiseSubscriptionServiceImpl',
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

  @override
  Future<void> updateFranchiseSubscription({
    required String documentId,
    required Map<String, dynamic> data,
  }) async {
    try {
      final docRef = _db.collection('franchise_subscriptions').doc(documentId);
      await docRef.set(data, SetOptions(merge: true));

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
      ErrorLogger.log(
        message: 'Failed to update franchise subscription',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionServiceImpl',
        severity: 'error',
        contextData: {'exception': e.toString()},
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

    final newMetadata = {
      for (final featureKey in grantedFeatures)
        featureKey: {
          'enabled': false,
          'features': {},
        },
      'updatedAt': FieldValue.serverTimestamp(),
    };

    await docRef.set(newMetadata);
  }

  @override
  Future<void> saveFranchiseSubscription(
      FranchiseSubscription subscription) async {
    try {
      final docRef = subscription.id.isNotEmpty
          ? _db.collection('franchise_subscriptions').doc(subscription.id)
          : _db.collection('franchise_subscriptions').doc();

      await docRef.set(subscription.toFirestore(), SetOptions(merge: true));
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save franchise subscription',
        stack: stack.toString(),
        source: 'FranchiseSubscriptionServiceImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteFranchiseSubscription(String id) async {
    try {
      await _db.collection('franchise_subscriptions').doc(id).delete();
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Failed to delete franchise_subscription $id',
        stack: st.toString(),
        source: 'FranchiseSubscriptionServiceImpl',
        severity: 'error',
      );
      rethrow;
    }
  }

  @override
  Future<void> deleteManyFranchiseSubscriptions(List<String> ids) async {
    final batch = _db.batch();
    for (final id in ids) {
      batch.delete(_db.collection('franchise_subscriptions').doc(id));
    }
    await batch.commit();
  }

  @override
  Future<List<FranchiseSubscription>> getAllFranchiseSubscriptions() async {
    final snap = await _db.collection('franchise_subscriptions').get();
    return snap.docs
        .map((doc) => FranchiseSubscription.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Stream<List<FranchiseSubscription>> watchAllFranchiseSubscriptions() {
    return _db
        .collection('franchise_subscriptions')
        .orderBy('subscribedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => FranchiseSubscription.fromMap(doc.id, doc.data()))
            .toList());
  }

  @override
  Future<FranchiseSubscription?> getCurrentSubscription(
      String franchiseId) async {
    final querySnapshot = await _db
        .collection('franchise_subscriptions')
        .where('franchiseId', isEqualTo: franchiseId)
        .where('status', isEqualTo: 'active')
        .orderBy('startDate', descending: true)
        .limit(1)
        .get();

    if (querySnapshot.docs.isEmpty) return null;
    final doc = querySnapshot.docs.first;
    return FranchiseSubscription.fromMap(doc.id, doc.data());
  }

  @override
  Future<FranchiseSubscription?> getActiveSubscriptionForFranchise(
      String franchiseId) async {
    final snap = await _db
        .collection('franchise_subscriptions')
        .where('franchiseId', isEqualTo: franchiseId)
        .where('active', isEqualTo: true)
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return FranchiseSubscription.fromMap(
        snap.docs.first.id, snap.docs.first.data());
  }

  @override
  Stream<FranchiseSubscription?> watchCurrentSubscription(String franchiseId) {
    return _db
        .collection('franchise_subscriptions')
        .where('franchiseId', isEqualTo: franchiseId)
        .where('active', isEqualTo: true)
        .orderBy('startDate', descending: true)
        .limit(1)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return FranchiseSubscription.fromMap(doc.id, doc.data());
    });
  }

  @override
  Future<PlatformPlan?> getPlatformPlanById(String planId) async {
    final doc = await _db.collection('platform_plans').doc(planId).get();
    if (!doc.exists) return null;
    return PlatformPlan.fromFirestore(doc);
  }

  @override
  Future<List<PlatformPlan>> getAllPlatformPlans() async {
    final snap = await _db.collection('platform_plans').get();
    return snap.docs
        .map((doc) => PlatformPlan.fromMap(doc.id, doc.data()))
        .toList();
  }

  @override
  Future<List<PlatformPlan>> getPlatformPlans() async {
    final snap = await _db.collection('platform_plans').get();
    return snap.docs
        .map((doc) => PlatformPlan.fromMap(doc.id, doc.data()))
        .toList();
  }
}
