// shared_core/lib/src/core/providers/franchise_provider.dart

import 'package:shared_core/src/core/models/user.dart' as admin_user;
import 'package:shared_core/src/core/models/franchise_info.dart';
import 'package:shared_core/src/core/utils/local_storage.dart';

/// Pure business logic for franchise selection and user context
class FranchiseProvider {
  Function()? onFranchiseChanged;

  String _franchiseId = 'unknown';
  bool _loading = true;
  admin_user.User? _adminUser;
  final LocalStorage _storage;

  // Main getters
  String get currentFranchiseId =>
      _franchiseId.isEmpty ? 'unknown' : _franchiseId;
  String get franchiseId =>
      currentFranchiseId; // alias for backward compatibility

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
    _bumpConfig();
  }

  Future<void> setFranchiseId(String id) async {
    if (id.isEmpty || _franchiseId == id) return;

    _franchiseId = id;
    await _storage.setString('selectedFranchiseId', id);
    _bumpConfig();
  }

  Future<void> setInitialFranchiseId(String id) async {
    if (_franchiseId == id) return;

    _franchiseId = id;
    final existing = await _storage.getString('selectedFranchiseId');
    if (existing != id) {
      await _storage.setString('selectedFranchiseId', id);
    }
    _bumpConfig();
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
    } else if (user.franchiseIds.isNotEmpty) {
      _franchiseId = user.franchiseIds.first; // fallback to first available
      await _storage.setString('selectedFranchiseId', _franchiseId);
    } else {
      _franchiseId = 'unknown';
    }

    _loading = false;
    _bumpConfig();
  }

  Future<void> clear() async {
    _franchiseId = 'unknown';
    _adminUser = null;
    _brandingData = const {};
    await _storage.remove('selectedFranchiseId');
    _bumpConfig();
  }

  List<FranchiseInfo> _allFranchises = [];
  List<FranchiseInfo> get allFranchises => List.unmodifiable(_allFranchises);

  void setAllFranchises(List<FranchiseInfo> franchises) {
    _allFranchises = franchises;
    _bumpConfig();
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
    _franchiseId = 'unknown';
    _allFranchises = [];
    _adminUser = null;
    _brandingData = const {};
    _configVersion++;
    if (onFranchiseChanged != null) onFranchiseChanged!();
  }

  // === P2: Dynamic Theming & White-Label Foundations ===
  // FranchiseProvider is now the single source of truth for per-franchise branding.
  // Mobile UiConfig and ThemeData pull from these (with DesignTokens fallbacks).
  // Callers (main/HomeWrapper/profile) fetch franchise doc and call setters.

  int _configVersion = 0;
  int get currentConfigVersion => _configVersion;

  Map<String, dynamic> _brandingData = const {};
  Map<String, dynamic> get currentBranding => Map.unmodifiable(_brandingData);

  /// Live primary color for current franchise (hex). Falls back to Doughboys red.
  String get currentPrimaryColorHex {
    final direct = _brandingData['primaryColorHex'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final nested = _brandingData['branding'];
    if (nested is Map && nested['primaryColorHex'] is String) {
      return nested['primaryColorHex'] as String;
    }
    return '#E31837';
  }

  /// Live secondary/accent color (hex).
  String get currentSecondaryColorHex {
    final direct = _brandingData['secondaryColorHex'] as String?;
    if (direct != null && direct.isNotEmpty) return direct;
    final nested = _brandingData['branding'];
    if (nested is Map && nested['secondaryColorHex'] is String) {
      return nested['secondaryColorHex'] as String;
    }
    return '#FFD700';
  }

  String get currentAppName {
    return (_brandingData['appName'] as String?) ??
        (_brandingData['name'] as String?) ??
        'Franchise App';
  }

  String? get currentLogoUrl {
    return (_brandingData['logoUrl'] as String?) ??
        (_brandingData['logo'] as String?);
  }

  /// Update from full franchises/{id} document snapshot data.
  /// Safe to call any time; bumps version so listeners (theme) can react.
  void setBrandingFromFranchiseDoc(Map<String, dynamic> docData) {
    _brandingData = Map<String, dynamic>.from(docData);
    _configVersion++;
    if (onFranchiseChanged != null) onFranchiseChanged!();
  }

  /// Merge basic info (name/logo) from FranchiseInfo + optional extra branding.
  void applyBrandingFromInfo(FranchiseInfo info, {Map<String, dynamic>? extraBranding}) {
    _brandingData = {
      ..._brandingData,
      'name': info.name,
      'logoUrl': info.logoUrl,
      if (extraBranding != null) ...extraBranding,
    };
    _configVersion++;
    if (onFranchiseChanged != null) onFranchiseChanged!();
  }

  // Bump version + notify on all mutating ops for theme reactivity via version selector.
  void _bumpConfig() {
    _configVersion++;
    if (onFranchiseChanged != null) onFranchiseChanged!();
  }
}
