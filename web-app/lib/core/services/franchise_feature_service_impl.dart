// web_app/lib/core/services/franchise_feature_service_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

class FranchiseFeatureServiceImpl implements FranchiseFeatureService {
  final FirebaseFirestore _firestore;

  FranchiseFeatureServiceImpl({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  @override
  Future<List<String>> getGrantedFeaturesFromSubscription(
      String franchiseId) async {
    try {
      final query = await _firestore
          .collection('franchise_subscriptions')
          .where('franchiseId', isEqualTo: franchiseId)
          .where('status', isEqualTo: 'active')
          .orderBy('startDate', descending: true)
          .limit(1)
          .get();

      if (query.docs.isEmpty) return [];

      final data = query.docs.first.data();
      if (data == null || data['planSnapshot'] == null) return [];

      final planSnapshot = data['planSnapshot'] as Map<String, dynamic>;
      final features = planSnapshot['features'];

      if (features is List) {
        return features.map((f) => f.toString()).toList();
      }

      return [];
    } catch (e, st) {
      ErrorLogger.log(
        message:
            'Failed to load granted features for franchise $franchiseId via query',
        stack: st.toString(),
        source: 'FranchiseFeatureService.getGrantedFeaturesFromSubscription',
        contextData: {'franchiseId': franchiseId},
      );
      return [];
    }
  }

  @override
  Future<FeatureState?> getFeatureMetadata(String franchiseId) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      ErrorLogger.log(
        message: 'getFeatureMetadata called with blank/unknown franchiseId',
        stack: '',
        source: 'franchise_feature_service.dart',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
    try {
      final docRef = _firestore
          .collection('franchises')
          .doc(franchiseId)
          .collection('feature_metadata')
          .doc(franchiseId);

      final snapshot = await docRef.get();
      if (!snapshot.exists || snapshot.data() == null) return null;

      final rawData = snapshot.data()!;
      final featureState = FeatureState.fromMap(rawData);

      debugPrint(
          '[FranchiseFeatureService] Loaded feature metadata for $franchiseId, '
          'liveSnapshotEnabled=${featureState.liveSnapshotEnabled}');

      return featureState;
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Failed to get feature_metadata',
        stack: st.toString(),
        source: 'FranchiseFeatureService.getFeatureMetadata',
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
  }

  @override
  Future<bool> saveFeatureMetadata({
    required String franchiseId,
    required FeatureState metadata,
  }) async {
    try {
      final granted = await getGrantedFeaturesFromSubscription(franchiseId);
      final errors = validateFeatureMetadata(
        grantedFeatures: granted,
        metadata: metadata,
      );

      if (errors.isNotEmpty) {
        ErrorLogger.log(
          message: 'Invalid feature metadata attempted to be saved',
          severity: 'warning',
          source: 'FranchiseFeatureService.saveFeatureMetadata',
          contextData: {'errors': errors, 'franchiseId': franchiseId},
        );
        return false;
      }

      final docRef = _firestore
          .collection('franchises')
          .doc(franchiseId)
          .collection('feature_metadata')
          .doc(franchiseId);

      final saveMap = {
        ...metadata.modules.map((k, v) => MapEntry(k, v.toMap())),
        'liveSnapshotEnabled': metadata.liveSnapshotEnabled,
      };

      await docRef.set(saveMap, SetOptions(merge: true));

      return true;
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Exception while saving feature metadata',
        stack: st.toString(),
        source: 'FranchiseFeatureService.saveFeatureMetadata',
        contextData: {'franchiseId': franchiseId},
      );
      return false;
    }
  }

  @override
  Future<void> updateModuleEnabled(
      String franchiseId, String moduleKey, bool enabled) async {
    final docRef = _firestore
        .collection('franchises')
        .doc(franchiseId)
        .collection('feature_metadata')
        .doc(franchiseId);

    await docRef.set({
      moduleKey: {'enabled': enabled}
    }, SetOptions(merge: true));
  }

  @override
  Future<void> updateModuleFeatures(
      String franchiseId, String moduleKey, Map<String, bool> updates) async {
    final updatesMap =
        updates.map((k, v) => MapEntry('$moduleKey.features.$k', v));

    final docRef = _firestore
        .collection('franchises')
        .doc(franchiseId)
        .collection('feature_metadata')
        .doc(franchiseId);

    await docRef.set(updatesMap, SetOptions(merge: true));
  }

  @override
  Future<void> removeModule(String franchiseId, String moduleKey) async {
    final docRef = _firestore
        .collection('franchises')
        .doc(franchiseId)
        .collection('feature_metadata')
        .doc(franchiseId);

    await docRef.update({moduleKey: FieldValue.delete()});
  }

  @override
  Future<void> removeFeature(
      String franchiseId, String moduleKey, String featureKey) async {
    final docRef = _firestore
        .collection('franchises')
        .doc(franchiseId)
        .collection('feature_metadata')
        .doc(franchiseId);

    await docRef
        .update({'$moduleKey.features.$featureKey': FieldValue.delete()});
  }

  @override
  Future<Map<String, bool>> getFlatFeatureFlags(String franchiseId) async {
    final docRef = _firestore
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('feature_flags');

    final snapshot = await docRef.get();
    if (!snapshot.exists || snapshot.data() == null) return {};

    final raw = snapshot.data()!;
    return raw.map((k, v) => MapEntry(k, v == true));
  }

  @override
  Future<void> saveFlatFeatureFlags(
      String franchiseId, Map<String, bool> flags) async {
    final docRef = _firestore
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('feature_flags');

    await docRef.set(flags, SetOptions(merge: true));
  }

  @override
  List<String> validateFeatureMetadata({
    required List<String> grantedFeatures,
    required FeatureState metadata,
  }) {
    final errors = <String>[];

    metadata.modules.forEach((moduleKey, module) {
      if (!grantedFeatures.contains(moduleKey)) {
        errors.add('Module "$moduleKey" is not granted by the current plan.');
      }

      module.features.forEach((featureKey, enabled) {
        if (enabled && !grantedFeatures.contains(moduleKey)) {
          errors.add(
              'Subfeature "$moduleKey.$featureKey" is enabled, but the parent module is not granted.');
        }
      });
    });

    return errors;
  }

  @override
  Future<bool> isLiveSnapshotEnabled(String franchiseId) async {
    try {
      final featureState = await getFeatureMetadata(franchiseId);
      final enabled = featureState?.liveSnapshotEnabled ?? false;
      debugPrint(
          '[FranchiseFeatureService] liveSnapshotEnabled for $franchiseId: $enabled');
      return enabled;
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Failed to check liveSnapshotEnabled',
        stack: st.toString(),
        source: 'FranchiseFeatureService.isLiveSnapshotEnabled',
        severity: 'error',
        contextData: {'franchiseId': franchiseId},
      );
      return false;
    }
  }

  @override
  Future<void> updateLiveSnapshotFlag(String franchiseId, bool enabled) async {
    if (franchiseId.isEmpty || franchiseId == 'unknown') {
      ErrorLogger.log(
        message: 'updateLiveSnapshotFlag called with blank/unknown franchiseId',
        stack: '',
        source: 'FranchiseFeatureService.updateLiveSnapshotFlag',
        severity: 'warning',
        contextData: {'franchiseId': franchiseId, 'requestedValue': enabled},
      );
      return;
    }

    try {
      final docRef = _firestore
          .collection('franchises')
          .doc(franchiseId)
          .collection('feature_metadata')
          .doc(franchiseId);

      await docRef.set(
        {'liveSnapshotEnabled': enabled},
        SetOptions(merge: true),
      );

      debugPrint(
          '[FranchiseFeatureService] liveSnapshotEnabled updated → $enabled for franchiseId=$franchiseId');

      ErrorLogger.log(
        message: 'liveSnapshotEnabled flag updated',
        source: 'FranchiseFeatureService.updateLiveSnapshotFlag',
        severity: 'info',
        contextData: {
          'franchiseId': franchiseId,
          'newValue': enabled,
        },
      );
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Failed to update liveSnapshotEnabled flag',
        stack: st.toString(),
        source: 'FranchiseFeatureService.updateLiveSnapshotFlag',
        severity: 'error',
        contextData: {
          'franchiseId': franchiseId,
          'requestedValue': enabled,
        },
      );
      rethrow;
    }
  }
}
