// mobile_app/test/helpers/test_helpers.dart
// P2.3 testing foundations placeholder.
// Full mocks and helpers will be expanded after FirestoreService interface stabilization.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_core/shared_core.dart' as shared;

/// Minimal placeholder for future richer test doubles.
class MinimalFirestoreStub {}

/// Basic app wrapper for future widget tests (currently unused by the foundation smoke tests).
Widget createTestAppPlaceholder(
    {required Widget child, String franchiseId = 'test'}) {
  // LocalStorage is abstract in shared; real tests provide a concrete impl.
  // This placeholder exists only for future expansion.
  final fp = shared.FranchiseProvider(_TestLocalStorage());
  fp.setInitialFranchiseId(franchiseId);
  shared.UiConfig.setFranchiseProvider(fp);

  return MultiProvider(
    providers: [
      Provider<shared.FranchiseProvider>.value(value: fp),
    ],
    child: MaterialApp(home: child),
  );
}

class _TestLocalStorage extends shared.LocalStorage {
  final Map<String, String> _store = {};
  @override
  String? getString(String key) => _store[key];
  @override
  Future<void> setString(String key, String value) async => _store[key] = value;
  @override
  Future<void> remove(String key) async => _store.remove(key);
}
