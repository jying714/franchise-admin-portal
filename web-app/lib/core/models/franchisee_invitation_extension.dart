// web_app/lib/core/models/franchisee_invitation_extension.dart
// Firestore + Flutter extensions — ONLY in web_app

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:shared_core/shared_core.dart';

extension FranchiseeInvitationFirestore on FranchiseeInvitation {
  /// Firestore: to map for saving
  Map<String, dynamic> toFirestoreMap() {
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

  /// Color mapping for status
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

  /// Save to Firestore
  Future<void> save(FirestoreService firestore) async {
    try {
      final collection =
          firestore.invitationCollection; // ← Now defined in impl
      await collection.doc(id).set(toFirestoreMap());
    } catch (e, st) {
      ErrorLogger.log(
        message: 'Failed to save FranchiseeInvitation',
        stack: st.toString(),
        severity: 'error',
        source: 'FranchiseeInvitation.save',
        contextData: {'id': id, 'email': email},
      );
      rethrow;
    }
  }

  /// Static: create and save
  static Future<FranchiseeInvitation> createAndSave({
    required String email,
    required String inviterUserId,
    String? franchiseName,
    String? token,
    required FirestoreService firestore,
  }) async {
    final collection = firestore.invitationCollection;
    final docRef = collection.doc();
    final invitation = FranchiseeInvitation(
      id: docRef.id,
      email: email,
      inviterUserId: inviterUserId,
      franchiseName: franchiseName,
      status: 'pending',
      token: token,
      createdAt: DateTime.now(),
    );
    await invitation.save(firestore);
    return invitation;
  }
}
