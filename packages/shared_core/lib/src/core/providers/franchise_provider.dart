// shared_core/lib/src/core/providers/franchise_provider.dart

import 'package:shared_core/src/core/models/user.dart' as admin_user;
import 'package:shared_core/src/core/models/franchise_info.dart';
import 'package:shared_core/src/core/utils/local_storage.dart';

/// Pure business logic for franchise selection and user context
/// NO Flutter, NO ChangeNotifier, NO VoidCallback
class FranchiseProvider {
  Function()?
      onFranchiseChanged; // <-- Fixed: Function() instead of VoidCallback
  String _franchiseId = 'unknown';
  bool _loading = true;
  admin_user.User? _adminUser;
  final LocalStorage _storage;

  String get franchiseId => _franchiseId.isEmpty ? 'unknown' : _franchiseId;
  bool get loading => _loading;
  bool get isFranchiseSelected =>
      _franchiseId != 'unknown' && _franchiseId.isNotEmpty;
  admin_user.User? get adminUser => _adminUser;
  bool get isDeveloper => _adminUser?.isDeveloper ?? false;
  bool get hasValidFranchise =>
      _franchiseId.isNotEmpty && _franchiseId != 'unknown';

  FranchiseProvider(this._storage) {
    _loadFranchiseId();
  }

  void setAdminUser(admin_user.User? user) {
    _adminUser = user;
  }

  Future<void> _loadFranchiseId() async {
    _loading = true;
    final id = await _storage.getString('selectedFranchiseId');
    _franchiseId = (id != null && id.isNotEmpty) ? id : 'unknown';
    _loading = false;
  }

  Future<void> setFranchiseId(String id) async {
    if (id.isEmpty || _franchiseId == id) return;

    _franchiseId = id;
    if (onFranchiseChanged != null) onFranchiseChanged!();
    await _storage.setString('selectedFranchiseId', id);
  }

  Future<void> setInitialFranchiseId(String id) async {
    if (_franchiseId == id) return;

    _franchiseId = id;
    final existing = await _storage.getString('selectedFranchiseId');
    if (existing != id) {
      await _storage.setString('selectedFranchiseId', id);
    }
  }

  Future<void> clear() async {
    _franchiseId = 'unknown';
    _adminUser = null;
    await _storage.remove('selectedFranchiseId');
  }

  List<FranchiseInfo> _allFranchises = [];
  List<FranchiseInfo> get allFranchises => List.unmodifiable(_allFranchises);
  void setAllFranchises(List<FranchiseInfo> franchises) {
    _allFranchises = franchises;
  }

  Future<void> initializeWithUser(admin_user.User user) async {
    _adminUser = user;

    if (_franchiseId != 'unknown' && _franchiseId.isNotEmpty) {
      _loading = false;
      return;
    }

    final storedId = await _storage.getString('selectedFranchiseId');
    if (storedId != null && storedId.isNotEmpty) {
      _franchiseId = storedId;
    } else if (user.defaultFranchise != null &&
        user.defaultFranchise!.isNotEmpty) {
      _franchiseId = user.defaultFranchise!;
      await _storage.setString('selectedFranchiseId', _franchiseId);
    } else {
      _franchiseId = 'unknown';
    }

    _loading = false;
  }

  List<FranchiseInfo> get viewableFranchises {
    if (_adminUser == null) return [];

    if (_adminUser!.isPlatformOwner || _adminUser!.isDeveloper) {
      return _allFranchises;
    }

    final allowedIds = _adminUser!.franchiseIds;
    return _allFranchises.where((f) => allowedIds.contains(f.id)).toList();
  }

  void clearFranchiseContext() {
    _franchiseId = '';
    _allFranchises = [];
    _adminUser = null;
  }
}
