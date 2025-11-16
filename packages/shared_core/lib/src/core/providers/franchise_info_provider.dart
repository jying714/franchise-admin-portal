// packages/shared_core/lib/src/core/providers/franchise_info_provider.dart
// PURE DART INTERFACE ONLY

import '../models/franchise_info.dart';

abstract class FranchiseInfoProvider {
  FranchiseInfo? get franchise;
  bool get loading;

  Future<void> loadFranchiseInfo();
  Future<void> reload();
  void clear();
}
