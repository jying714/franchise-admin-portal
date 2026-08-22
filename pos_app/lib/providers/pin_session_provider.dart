import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:shared_core/shared_core.dart';
import '../core/constants/pos_permissions.dart';

/// Active station session after successful PIN unlock.
class PinSessionProvider extends ChangeNotifier {
  Staff? _staff;
  DateTime? _unlockedAt;
  DateTime? _lastActivityAt;

  StreamSubscription<PosSettings>? _settingsSub;
  final PosFirestoreService _posFs = PosFirestoreService();
  Timer? _idleTimer;
  int _pinSessionTimeoutMinutes = 15;
  int _pinSessionGraceSeconds = 30;
  bool _requiresRepin = false;

  Staff? get staff => _staff;
  bool get isUnlocked => _staff != null && !_requiresRepin;
  bool get requiresRepin => _requiresRepin;
  DateTime? get unlockedAt => _unlockedAt;

  int get pinSessionGraceSeconds => _pinSessionGraceSeconds;

  /// Call when PosSettings load (or default 15).
  void setTimeoutMinutes(int minutes) {
    if (minutes <= 0) return;
    if (minutes == _pinSessionTimeoutMinutes) return;
    _pinSessionTimeoutMinutes = minutes;
    _armIdleTimer();
  }

  void setGraceSeconds(int seconds) {
    if (seconds <= 0) return;
    if (seconds == _pinSessionGraceSeconds) return;
    _pinSessionGraceSeconds = seconds;
  }

  void bindFranchise(String franchiseId) {
    _settingsSub?.cancel();
    if (franchiseId.isEmpty) return;
    _settingsSub = _posFs.streamPosSettings(franchiseId).listen((settings) {
      setTimeoutMinutes(settings.pinSessionTimeoutMinutes);
      setGraceSeconds(settings.pinSessionGraceSeconds);
    });
  }

  bool hasPermission(String permission) {
    final s = _staff;
    if (s == null || _requiresRepin) return false;
    if (s.permissions.contains(PosPermissions.managerOverride)) return true;
    return s.permissions.contains(permission);
  }

  bool requiresFreshPinFor(String permission) {
    return PosPermissions.elevatedRequiresRepin.contains(permission);
  }

  /// Mark activity (navigation, keypress). Resets idle timeout.
  void touch() {
    if (_staff == null) return;
    _lastActivityAt = DateTime.now();
    if (_requiresRepin) return;
    _armIdleTimer();
  }

  /// Unlock after PIN verified against [staff.pinHash] (hash check is caller’s job).
  void unlock(Staff staff) {
    _staff = staff;
    _unlockedAt = DateTime.now();
    _lastActivityAt = _unlockedAt;
    _requiresRepin = false;
    _armIdleTimer();
    notifyListeners();
  }

  /// Force re-PIN for elevated action or idle timeout without full logout.
  void lockForRepin() {
    if (_staff == null) return;
    _requiresRepin = true;
    _idleTimer?.cancel();
    notifyListeners();
  }

  /// Clear session entirely (shift end / switch user).
  void lock() {
    _idleTimer?.cancel();
    _staff = null;
    _unlockedAt = null;
    _lastActivityAt = null;
    _requiresRepin = false;
    notifyListeners();
  }

  void _armIdleTimer() {
    _idleTimer?.cancel();
    if (_staff == null || _requiresRepin) return;
    final timeout = Duration(minutes: _pinSessionTimeoutMinutes);
    _idleTimer = Timer(timeout, () {
      lockForRepin();
    });
  }

  @override
  void dispose() {
    _settingsSub?.cancel();
    _idleTimer?.cancel();
    super.dispose();
  }
}
