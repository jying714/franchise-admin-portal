// packages/shared_core/lib/src/core/repositories/config_firestore_repository.dart
//
// Concrete ConfigRepository. Phase A2.1: feature toggles only.
// Authority: docs/slices/bounded-context-repos-v1.md

import 'package:cloud_firestore/cloud_firestore.dart' as firestore;

import '../utils/error_logger.dart';
import 'config_repository.dart';

class ConfigFirestoreRepository implements ConfigRepository {
  ConfigFirestoreRepository({firestore.FirebaseFirestore? db})
      : _db = db ?? firestore.FirebaseFirestore.instance;

  final firestore.FirebaseFirestore _db;

  firestore.CollectionReference<Map<String, dynamic>> _franchiseCollection(
    String franchiseId,
    String name,
  ) =>
      _db.collection('franchises').doc(franchiseId).collection(name);

  bool _badFranchise(String franchiseId) =>
      franchiseId.isEmpty ||
      franchiseId == 'unknown' ||
      franchiseId == 'default';

  @override
  Future<Map<String, dynamic>> getGlobalFeatureToggles() async {
    try {
      final doc = await _db.collection('config').doc('features').get();
      return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to getGlobalFeatureToggles',
        source: 'ConfigFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
      );
      return {};
    }
  }

  @override
  Future<Map<String, dynamic>> getFranchiseFeatureToggles(
      String franchiseId) async {
    if (_badFranchise(franchiseId)) return {};

    try {
      final doc = await _franchiseCollection(franchiseId, 'config')
          .doc('features')
          .get();
      return doc.exists ? Map<String, dynamic>.from(doc.data()!) : {};
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to getFranchiseFeatureToggles',
        source: 'ConfigFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
      return {};
    }
  }

  @override
  Future<void> setFranchiseFeatureToggles(
      String franchiseId, Map<String, dynamic> toggles) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _franchiseCollection(franchiseId, 'config')
          .doc('features')
          .set(toggles, firestore.SetOptions(merge: true));
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to setFranchiseFeatureToggles',
        source: 'ConfigFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId},
      );
    }
  }

  @override
  Stream<Map<String, dynamic>> streamFranchiseFeatureToggles(
      String franchiseId) {
    if (_badFranchise(franchiseId)) return Stream.value({});

    return _franchiseCollection(franchiseId, 'config')
        .doc('features')
        .snapshots()
        .map((d) => d.data() ?? {});
  }

  @override
  Future<void> updateFeatureToggle(
      String franchiseId, String key, dynamic value) async {
    if (_badFranchise(franchiseId)) return;

    try {
      await _franchiseCollection(franchiseId, 'config')
          .doc('features')
          .set({key: value}, firestore.SetOptions(merge: true));
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to updateFeatureToggle',
        source: 'ConfigFirestoreRepository',
        severity: 'error',
        stack: stack.toString(),
        contextData: {'franchiseId': franchiseId, 'key': key},
      );
    }
  }
}
