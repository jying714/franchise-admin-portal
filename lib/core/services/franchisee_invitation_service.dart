// File: lib/core/services/franchisee_invitation_service.dart

import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:franchise_admin_portal/core/models/franchisee_invitation.dart';
import 'package:franchise_admin_portal/core/services/firestore_service.dart';
import 'package:franchise_admin_portal/core/utils/error_logger.dart';

class FranchiseeInvitationService {
  final FirestoreService firestoreService;

  FranchiseeInvitationService({required this.firestoreService});

  /// Stream invitations (optionally filter by status/inviter)
  Stream<List<FranchiseeInvitation>> invitationsStream({
    String? status,
    String? inviterUserId,
  }) {
    return firestoreService.invitationStream(
      status: status,
      inviterUserId: inviterUserId,
    );
  }

  /// Fetch all invitations (optionally filter)
  Future<List<FranchiseeInvitation>> fetchInvitations({
    String? status,
    String? inviterUserId,
    String? email,
  }) async {
    try {
      return await firestoreService.fetchInvitations(
        status: status,
        inviterUserId: inviterUserId,
        email: email,
      );
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to fetch invitations',
        stack: stack.toString(),
        source: 'FranchiseeInvitationService.fetchInvitations',
        screen: 'FranchiseeInvitation',
        contextData: {'exception': e.toString()},
      );
      rethrow;
    }
  }

  /// Fetch invitation by Firestore doc ID
  Future<FranchiseeInvitation?> fetchInvitationById(String id) async {
    try {
      return await firestoreService.fetchInvitationById(id);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to fetch invitation by ID',
        stack: stack.toString(),
        source: 'FranchiseeInvitationService.fetchInvitationById',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'exception': e.toString()},
      );
      rethrow;
    }
  }

  /// Invite a new franchisee via Cloud Function (inviteAndSetRole)
  /// Throws on error.
  Future<void> inviteFranchisee({
    required String email,
    required String role,
    required String inviterUserId,
    String? franchiseName,
    String? password, // may be required by backend if user does not exist
    Map<String, dynamic>? extraData, // For future extensibility
  }) async {
    try {
      final HttpsCallable callable = FirebaseFunctions.instance.httpsCallable(
        'inviteAndSetRole',
      );
      final Map<String, dynamic> data = {
        'email': email,
        'role': role,
        if (password != null) 'password': password,
        if (franchiseName != null) 'franchiseName': franchiseName,
        if (extraData != null) ...extraData,
      };
      final result = await callable.call(data);
      if (result.data?['status'] != 'ok') {
        throw Exception('Invite failed: ${result.data}');
      }
      // Firestore record will be created by function (backend-of-truth)
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to invite franchisee via Cloud Function',
        stack: stack.toString(),
        source: 'FranchiseeInvitationService.inviteFranchisee',
        screen: 'FranchiseeInvitation',
        contextData: {
          'email': email,
          'role': role,
          'exception': e.toString(),
        },
      );
      rethrow;
    }
  }

  /// Update invitation metadata (admin usage)
  Future<void> updateInvitation(String id, Map<String, dynamic> data) async {
    try {
      await firestoreService.updateInvitation(id, data);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to update invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationService.updateInvitation',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'data': data, 'exception': e.toString()},
      );
      rethrow;
    }
  }

  /// Cancel/revoke an invitation (soft-cancel, not hard delete)
  Future<void> cancelInvitation(String id, {String? revokedByUserId}) async {
    try {
      await firestoreService.cancelInvitation(id,
          revokedByUserId: revokedByUserId);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to cancel invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationService.cancelInvitation',
        screen: 'FranchiseeInvitation',
        contextData: {
          'id': id,
          'revokedBy': revokedByUserId,
          'exception': e.toString()
        },
      );
      rethrow;
    }
  }

  /// Delete an invitation (permanent)
  Future<void> deleteInvitation(String id) async {
    try {
      await firestoreService.deleteInvitation(id);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to delete invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationService.deleteInvitation',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'exception': e.toString()},
      );
      rethrow;
    }
  }

  /// Expire invitation (for auto-expiry, admin, or time-based cleanup)
  Future<void> expireInvitation(String id) async {
    try {
      await firestoreService.expireInvitation(id);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to expire invitation',
        stack: stack.toString(),
        source: 'FranchiseeInvitationService.expireInvitation',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'exception': e.toString()},
      );
      rethrow;
    }
  }

  /// Mark as re-sent (record metadata only, actual invite handled by cloud function)
  Future<void> markInvitationResent(String id) async {
    try {
      await firestoreService.markInvitationResent(id);
    } catch (e, stack) {
      await ErrorLogger.log(
        message: 'Failed to mark invitation as re-sent',
        stack: stack.toString(),
        source: 'FranchiseeInvitationService.markInvitationResent',
        screen: 'FranchiseeInvitation',
        contextData: {'id': id, 'exception': e.toString()},
      );
      rethrow;
    }
  }

  // === Developer Only: Debug Util ===
  @visibleForTesting
  Future<List<FranchiseeInvitation>> debugFetchAllInvitationsRaw() async {
    return await firestoreService.fetchInvitations();
  }

  // === Future Feature Placeholders ===

  /// Bulk invite (not yet implemented)
  Future<void> bulkInviteFranchisees(
      List<Map<String, dynamic>> inviteDataList) async {
    throw UnimplementedError('Bulk invitation is a planned feature.');
  }

  /// Export invitatons (not yet implemented)
  Future<void> exportInvitations() async {
    throw UnimplementedError('Export invitations is a planned feature.');
  }
}
