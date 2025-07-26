import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/models/feature_metadata.dart'
    show FeatureState;
import 'package:franchise_admin_portal/core/models/feature_module.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FranchiseFeatureService {
  final FirebaseFirestore _firestore;

  FranchiseFeatureService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// 🔹 Get the list of all features granted by the current plan
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
      await ErrorLogger.log(
        message:
            'Failed to load granted features for franchise $franchiseId via query',
        stack: st.toString(),
        source: 'FranchiseFeatureService.getGrantedFeaturesFromSubscription',
        contextData: {'franchiseId': franchiseId},
      );
      return [];
    }
  }

  /// 🔹 Load the feature metadata config for onboarding/use
  Future<FeatureState?> getFeatureMetadata(String franchiseId) async {
    try {
      final docRef = _firestore
          .collection('franchises')
          .doc(franchiseId)
          .collection('feature_metadata')
          .doc(franchiseId);

      final snapshot = await docRef.get();
      if (!snapshot.exists || snapshot.data() == null) return null;

      return FeatureState.fromMap(snapshot.data()!);
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Failed to get feature_metadata',
        stack: st.toString(),
        source: 'FranchiseFeatureService.getFeatureMetadata',
        contextData: {'franchiseId': franchiseId},
      );
      return null;
    }
  }

  /// 🔹 Save the feature metadata (if valid)
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
        await ErrorLogger.log(
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

      await docRef.set(metadata.modules.map((k, v) => MapEntry(k, v.toMap())),
          SetOptions(merge: true));

      return true;
    } catch (e, st) {
      await ErrorLogger.log(
        message: 'Exception while saving feature metadata',
        stack: st.toString(),
        source: 'FranchiseFeatureService.saveFeatureMetadata',
        contextData: {'franchiseId': franchiseId},
      );
      return false;
    }
  }

  /// 🔹 Save a single module toggle
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

  /// 🔹 Save toggles inside a module
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

  /// 🔹 Remove a full module (e.g., inventory)
  Future<void> removeModule(String franchiseId, String moduleKey) async {
    final docRef = _firestore
        .collection('franchises')
        .doc(franchiseId)
        .collection('feature_metadata')
        .doc(franchiseId);

    await docRef.update({moduleKey: FieldValue.delete()});
  }

  /// 🔹 Remove one subfeature from module
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

  /// 🔹 Legacy flat flags (optional legacy devtool support)
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

  Future<void> saveFlatFeatureFlags(
      String franchiseId, Map<String, bool> flags) async {
    final docRef = _firestore
        .collection('franchises')
        .doc(franchiseId)
        .collection('config')
        .doc('feature_flags');

    await docRef.set(flags, SetOptions(merge: true));
  }

  /// 🔍 Schema validator for metadata enforcement
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
}
