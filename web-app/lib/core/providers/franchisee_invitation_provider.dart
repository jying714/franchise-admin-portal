// File: lib/core/providers/franchisee_invitation_provider.dart

import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/franchisee_invitation.dart';
import 'package:franchise_admin_portal/widgets/financials/franchisee_invitation_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';
import 'package:cloud_functions/cloud_functions.dart';

/// Provider for Franchisee Invitations. Owns invitation state, exposes
/// all major actions (invite, cancel, delete, refresh, etc.).
/// UI may use this as a ChangeNotifierProvider.
class FranchiseeInvitationProvider with ChangeNotifier {
  final FranchiseeInvitationService service;

  List<FranchiseeInvitation> _invitations = [];
  bool _loading = false;
  String? _lastError;

  List<FranchiseeInvitation> get invitations => _invitations;
  bool get loading => _loading;
  String? get lastError => _lastError;

  // Optionally filter (status, inviter, etc.) for future extension
  String? _filterStatus;

  // Stream subscription handle for live updates
  Stream<List<FranchiseeInvitation>>? _subscription;
  VoidCallback? _cancelSubscription;

  FranchiseeInvitationProvider({required this.service});

  // === State Management ===

  /// Start listening to all invitations (for real-time UI updates).
  void subscribeInvitations({String? status, String? inviterUserId}) {
    _filterStatus = status;
    _cancelSubscription?.call(); // Cancel any existing sub
    _subscription = service.invitationsStream(
      status: status,
      inviterUserId: inviterUserId,
    );
    final sub = _subscription!.listen((list) {
      _invitations = list;
      notifyListeners();
    }, onError: (e, stack) async {
      _lastError = e.toString();
      await ErrorLogger.log(
        message: 'Subscription error in FranchiseeInvitationProvider',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProvider.subscribeInvitations',
        screen: 'FranchiseeInvitation',
        contextData: {'exception': e.toString()},
      );
      notifyListeners();
    });
    _cancelSubscription = () => sub.cancel();
  }

  /// Stop listening to invitations (cleanup)
  void unsubscribeInvitations() {
    _cancelSubscription?.call();
    _subscription = null;
    _cancelSubscription = null;
  }

  /// One-time fetch (not streamed)
  Future<void> fetchInvitations(
      {String? status, String? inviterUserId, String? email}) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      _invitations = await service.fetchInvitations(
        status: status ?? _filterStatus,
        inviterUserId: inviterUserId,
        email: email,
      );
    } catch (e) {
      _lastError = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  /// Fetch invitation by Firestore doc ID (for dialog/detail screens)
  Future<FranchiseeInvitation?> fetchInvitationById(String id) async {
    try {
      return await service.fetchInvitationById(id);
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return null;
    }
  }

  // === Invitation Actions ===
  bool sending = false;
  Future<void> sendInvitation({
    required String email,
    required String franchiseName,
    required String role,
    String? notes,
  }) async {
    sending = true;
    notifyListeners();

    final HttpsCallable inviteFn =
        FirebaseFunctions.instance.httpsCallable('inviteAndSetRole');

    try {
      final result = await inviteFn.call({
        'email': email,
        'franchiseName': franchiseName,
        'role': role,
        if (notes != null) 'notes': notes,
        // Optionally provide a default password for new users if your function requires
        // 'password': 'SetRandomlyOrGenerateOnUI',
      });

      // Refresh invitation list
      await fetchInvitations();
      // You can also handle success (e.g. store result if needed)
    } on FirebaseFunctionsException catch (e, stack) {
      // Optionally: handle different error codes/types
      // Use your error logger
      await ErrorLogger.log(
        message: 'Failed to send invitation',
        stack: stack.toString(),
        severity: 'error',
        source: 'FranchiseeInvitationProvider.sendInvitation',
        screen: 'PlatformOwnerDashboardScreen',
        contextData: {
          'exception': e.toString(),
          'email': email,
          'franchiseName': franchiseName,
          'role': role,
        },
      );
      rethrow;
    } finally {
      sending = false;
      notifyListeners();
    }
  }

  /// Send a new invite (calls cloud function)
  Future<bool> inviteFranchisee({
    required String email,
    required String role,
    required String inviterUserId,
    String? franchiseName,
    String? password,
    Map<String, dynamic>? extraData,
  }) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await service.inviteFranchisee(
        email: email,
        role: role,
        inviterUserId: inviterUserId,
        franchiseName: franchiseName,
        password: password,
        extraData: extraData,
      );
      _loading = false;
      await fetchInvitations(); // Refresh
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      await ErrorLogger.log(
        message: 'Failed to invite franchisee',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProvider.inviteFranchisee',
        screen: 'FranchiseeInvitation',
        contextData: {
          'email': email,
          'role': role,
          'exception': e.toString(),
        },
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Update invitation meta (admin-only)
  Future<bool> updateInvitation(String id, Map<String, dynamic> data) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await service.updateInvitation(id, data);
      await fetchInvitations(); // Refresh
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      await ErrorLogger.log(
        message: 'Failed to update invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProvider.updateInvitation',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'data': data, 'exception': e.toString()},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Cancel/revoke an invitation (soft-cancel)
  Future<bool> cancelInvitation(String id, {String? revokedByUserId}) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await service.cancelInvitation(id, revokedByUserId: revokedByUserId);
      await fetchInvitations(); // Refresh
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      await ErrorLogger.log(
        message: 'Failed to cancel invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProvider.cancelInvitation',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'exception': e.toString()},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Delete invitation (hard delete)
  Future<bool> deleteInvitation(String id) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await service.deleteInvitation(id);
      await fetchInvitations(); // Refresh
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      await ErrorLogger.log(
        message: 'Failed to delete invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProvider.deleteInvitation',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'exception': e.toString()},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Expire invitation (for auto-expiry or admin)
  Future<bool> expireInvitation(String id) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await service.expireInvitation(id);
      await fetchInvitations();
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      await ErrorLogger.log(
        message: 'Failed to expire invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProvider.expireInvitation',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'exception': e.toString()},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  /// Mark as re-sent (meta only; actual email/cloud function should be called separately)
  Future<bool> markInvitationResent(String id) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await service.markInvitationResent(id);
      await fetchInvitations();
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      await ErrorLogger.log(
        message: 'Failed to mark invitation as re-sent',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProvider.markInvitationResent',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'exception': e.toString()},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  // === Developer-only Debug Utilities ===
  @visibleForTesting
  Future<void> devClearInvitations() async {
    // For testing only! Use with care.
    for (final invite in _invitations) {
      await deleteInvitation(invite.id);
    }
    await fetchInvitations();
  }

  // === Future Feature Placeholders ===
  /// Bulk invite (planned feature)
  Future<void> bulkInviteFranchisees(
      List<Map<String, dynamic>> inviteDataList) async {
    throw UnimplementedError('Bulk invite is not implemented yet.');
  }

  /// Export invitations (planned feature)
  Future<void> exportInvitations() async {
    throw UnimplementedError('Export invitations is not implemented yet.');
  }

  @override
  void dispose() {
    unsubscribeInvitations();
    super.dispose();
  }
}
