// web_app/lib/core/providers/franchisee_invitation_provider_impl.dart

import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'dart:async';

class FranchiseeInvitationProviderImpl extends ChangeNotifier
    implements FranchiseeInvitationProvider {
  final FranchiseeInvitationService _service;

  List<FranchiseeInvitation> _invitations = [];
  bool _loading = false;
  String? _lastError;
  bool _sending = false;

  StreamSubscription<List<FranchiseeInvitation>>? _subscription;
  VoidCallback? _cancelSubscription;

  FranchiseeInvitationProviderImpl(
      {required FranchiseeInvitationService service})
      : _service = service;

  @override
  List<FranchiseeInvitation> get invitations => _invitations;

  @override
  bool get loading => _loading;

  @override
  String? get lastError => _lastError;

  @override
  bool get sending => _sending;

  @override
  void subscribeInvitations({String? status, String? inviterUserId}) {
    _cancelSubscription?.call();
    _subscription = _service
        .invitationsStream(status: status, inviterUserId: inviterUserId)
        .listen(
      (list) {
        _invitations = list;
        notifyListeners();
      },
      onError: (e, stack) {
        _lastError = e.toString();
        ErrorLogger.log(
          message: 'Subscription error in FranchiseeInvitationProvider',
          stack: stack.toString(),
          source: 'FranchiseeInvitationProviderImpl.subscribeInvitations',
          contextData: {'exception': e.toString()},
        );
        notifyListeners();
      },
    );
    _cancelSubscription = () => _subscription?.cancel();
  }

  @override
  void unsubscribeInvitations() {
    _cancelSubscription?.call();
    _subscription = null;
    _cancelSubscription = null;
  }

  @override
  Future<void> fetchInvitations(
      {String? status, String? inviterUserId, String? email}) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      _invitations = await _service.fetchInvitations(
        status: status,
        inviterUserId: inviterUserId,
        email: email,
      );
    } catch (e) {
      _lastError = e.toString();
    }
    _loading = false;
    notifyListeners();
  }

  @override
  Future<FranchiseeInvitation?> fetchInvitationById(String id) async {
    try {
      return await _service.fetchInvitationById(id);
    } catch (e) {
      _lastError = e.toString();
      notifyListeners();
      return null;
    }
  }

  @override
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
      await _service.inviteFranchisee(
        email: email,
        role: role,
        inviterUserId: inviterUserId,
        franchiseName: franchiseName,
        password: password,
        extraData: extraData,
      );
      await fetchInvitations();
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      ErrorLogger.log(
        message: 'Failed to invite franchisee',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProviderImpl.inviteFranchisee',
        contextData: {'email': email, 'role': role},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> updateInvitation(String id, Map<String, dynamic> data) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _service.updateInvitation(id, data);
      await fetchInvitations();
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      ErrorLogger.log(
        message: 'Failed to update invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProviderImpl.updateInvitation',
        contextData: {'id': id},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> cancelInvitation(String id, {String? revokedByUserId}) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _service.cancelInvitation(id, revokedByUserId: revokedByUserId);
      await fetchInvitations();
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      ErrorLogger.log(
        message: 'Failed to cancel invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProviderImpl.cancelInvitation',
        contextData: {'id': id},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> deleteInvitation(String id) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _service.deleteInvitation(id);
      await fetchInvitations();
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      ErrorLogger.log(
        message: 'Failed to delete invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProviderImpl.deleteInvitation',
        contextData: {'id': id},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> expireInvitation(String id) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _service.expireInvitation(id);
      await fetchInvitations();
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      ErrorLogger.log(
        message: 'Failed to expire invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProviderImpl.expireInvitation',
        contextData: {'id': id},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  Future<bool> markInvitationResent(String id) async {
    _loading = true;
    _lastError = null;
    notifyListeners();
    try {
      await _service.markInvitationResent(id);
      await fetchInvitations();
      _loading = false;
      return true;
    } catch (e, stack) {
      _lastError = e.toString();
      ErrorLogger.log(
        message: 'Failed to mark invitation as re-sent',
        stack: stack.toString(),
        source: 'FranchiseeInvitationProviderImpl.markInvitationResent',
        contextData: {'id': id},
      );
      _loading = false;
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    unsubscribeInvitations();
    super.dispose();
  }
}
