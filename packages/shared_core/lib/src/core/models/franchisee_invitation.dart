// File: lib/core/models/franchisee_invitation.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';
import 'package:shared_core/src/core/services/firestore_service_BACKUP.dart';

/// Model representing a pending or completed franchisee invitation.
/// Includes methods for Firestore serialization/deserialization, robust error logging,
/// and display helpers.
class FranchiseeInvitation {
  final String id;
  final String email;
  final String inviterUserId;
  final String? franchiseName;
  final String
      status; // e.g. "pending", "sent", "accepted", "revoked", "expired"
  final String? token;
  final DateTime createdAt;
  final DateTime? lastSentAt;
  final String? role;

  FranchiseeInvitation({
    required this.id,
    required this.email,
    required this.inviterUserId,
    this.franchiseName,
    required this.status,
    this.token,
    this.role,
    required this.createdAt,
    this.lastSentAt,
  });

  /// For localization of status and info.
  String localizedStatus() {
    // No BuildContext or AppLocalizations in shared_core
    // Return raw English string only
    switch (status) {
      case 'pending':
        return 'Pending';
      case 'sent':
        return 'Sent';
      case 'accepted':
        return 'Accepted';
      case 'revoked':
        return 'Revoked';
      case 'expired':
        return 'Expired';
      default:
        return status;
    }
  }

  /// Color mapping for status, uses config tokens.
  Color statusColor(ColorScheme scheme) {
    switch (status) {
      case 'pending':
        return scheme.primary;
      case 'sent':
        return scheme.secondary;
      case 'accepted':
        return Colors.green;
      case 'revoked':
        return scheme.error;
      case 'expired':
        return scheme.outline;
      default:
        return scheme.outlineVariant;
    }
  }

  /// Firestore: from document snapshot
  factory FranchiseeInvitation.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    try {
      return FranchiseeInvitation(
        id: doc.id,
        email: data['email'] ?? '',
        inviterUserId: data['inviterUserId'] ?? '',
        franchiseName: data['franchiseName'],
        status: data['status'] ?? 'pending',
        token: data['token'],
        role: data['role'],
        createdAt:
            (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
        lastSentAt: (data['lastSentAt'] as Timestamp?)?.toDate(),
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to parse FranchiseeInvitation doc',
        stack: stack.toString(),
        severity: 'error',
        source: 'FranchiseeInvitation.fromDoc',
        contextData: {'exception': e.toString(), 'docId': doc.id},
      );
      rethrow;
    }
  }

  /// Firestore: to map for saving
  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'inviterUserId': inviterUserId,
      if (franchiseName != null) 'franchiseName': franchiseName,
      'status': status,
      if (token != null) 'token': token,
      if (role != null) 'role': role,
      'createdAt': Timestamp.fromDate(createdAt),
      if (lastSentAt != null) 'lastSentAt': Timestamp.fromDate(lastSentAt!),
    };
  }

  /// Robustly create a Firestore doc for this invitation.
  Future<void> saveToFirestore(FirestoreService firestoreService) async {
    try {
      await firestoreService.invitationCollection.doc(id).set(toMap());
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to save FranchiseeInvitation',
        stack: stack.toString(),
        severity: 'error',
        source: 'FranchiseeInvitation.saveToFirestore',
        contextData: {
          'exception': e.toString(),
          'inviteId': id,
          'email': email
        },
      );
      rethrow;
    }
  }

  /// Static helper: create a new invitation and save, returns instance.
  static Future<FranchiseeInvitation> createAndSave({
    required String email,
    required String inviterUserId,
    String? franchiseName,
    String? token,
    required FirestoreService firestoreService,
  }) async {
    final id = firestoreService.invitationCollection.doc().id;
    final invitation = FranchiseeInvitation(
      id: id,
      email: email,
      inviterUserId: inviterUserId,
      franchiseName: franchiseName,
      status: 'pending',
      token: token,
      createdAt: DateTime.now(),
      lastSentAt: null,
    );
    await invitation.saveToFirestore(firestoreService);
    return invitation;
  }

  /// Developer-only: toString
  @override
  String toString() {
    return 'FranchiseeInvitation(id: $id, email: $email, inviter: $inviterUserId, franchiseName: $franchiseName, status: $status, token: $token, createdAt: $createdAt, lastSentAt: $lastSentAt)';
  }
}
