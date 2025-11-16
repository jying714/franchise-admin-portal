// packages/shared_core/lib/src/core/providers/franchisee_invitation_provider.dart
// PURE DART INTERFACE ONLY

import '../models/franchisee_invitation.dart';

abstract class FranchiseeInvitationProvider {
  List<FranchiseeInvitation> get invitations;
  bool get loading;
  String? get lastError;
  bool get sending;

  void subscribeInvitations({String? status, String? inviterUserId});
  void unsubscribeInvitations();
  Future<void> fetchInvitations(
      {String? status, String? inviterUserId, String? email});
  Future<FranchiseeInvitation?> fetchInvitationById(String id);
  Future<bool> inviteFranchisee({
    required String email,
    required String role,
    required String inviterUserId,
    String? franchiseName,
    String? password,
    Map<String, dynamic>? extraData,
  });
  Future<bool> updateInvitation(String id, Map<String, dynamic> data);
  Future<bool> cancelInvitation(String id, {String? revokedByUserId});
  Future<bool> deleteInvitation(String id);
  Future<bool> expireInvitation(String id);
  Future<bool> markInvitationResent(String id);
}
