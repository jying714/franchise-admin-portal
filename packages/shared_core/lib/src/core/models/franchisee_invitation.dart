// packages/shared_core/lib/src/core/models/franchisee_invitation.dart
// PURE DART MODEL ONLY — NO Firestore, NO Flutter, NO services

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

  /// For localization of status (English only — no l10n in shared_core)
  String get localizedStatus {
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

  /// For JSON export / debugging
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'inviterUserId': inviterUserId,
      'franchiseName': franchiseName,
      'status': status,
      'token': token,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'lastSentAt': lastSentAt?.toIso8601String(),
    };
  }

  /// From map (used by impl)
  factory FranchiseeInvitation.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseDate(dynamic d) {
      if (d is DateTime) return d;
      if (d is String) return DateTime.tryParse(d) ?? DateTime.now();
      return DateTime.now();
    }

    return FranchiseeInvitation(
      id: id,
      email: data['email'] ?? '',
      inviterUserId: data['inviterUserId'] ?? '',
      franchiseName: data['franchiseName'],
      status: data['status'] ?? 'pending',
      token: data['token'],
      role: data['role'],
      createdAt: parseDate(data['createdAt']),
      lastSentAt:
          data['lastSentAt'] != null ? parseDate(data['lastSentAt']) : null,
    );
  }

  @override
  String toString() {
    return 'FranchiseeInvitation(id: $id, email: $email, status: $status)';
  }
}
