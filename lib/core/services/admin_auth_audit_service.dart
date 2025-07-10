import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;

class AdminAuthAuditService {
  final FirebaseFirestore _db;
  final fb_auth.FirebaseAuth _auth;

  AdminAuthAuditService({
    FirebaseFirestore? firestore,
    fb_auth.FirebaseAuth? firebaseAuth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  Future<void> logEvent({
    required String
        type, // e.g., 'login', 'logout', 'impersonation', 'switchFranchise'
    String? franchiseId,
    Map<String, dynamic>? metadata,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    final logRef = _db.collection('admin_auth_audit_logs').doc();
    await logRef.set({
      'uid': user.uid,
      'email': user.email,
      'type': type,
      'franchiseId': franchiseId,
      'timestamp': FieldValue.serverTimestamp(),
      'metadata': metadata ?? {},
    });
  }

  Stream<List<Map<String, dynamic>>> streamRecentEvents({int limit = 50}) {
    return _db
        .collection('admin_auth_audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}
