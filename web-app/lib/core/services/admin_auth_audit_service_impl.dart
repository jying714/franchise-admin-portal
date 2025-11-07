// web-app/lib/core/services/admin_auth_audit_service_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:shared_core/src/core/services/admin_auth_audit_service.dart';

class AdminAuthAuditServiceImpl implements AdminAuthAuditService {
  final FirebaseFirestore _db;
  final fb_auth.FirebaseAuth _auth;

  AdminAuthAuditServiceImpl({
    FirebaseFirestore? firestore,
    fb_auth.FirebaseAuth? firebaseAuth,
  })  : _db = firestore ?? FirebaseFirestore.instance,
        _auth = firebaseAuth ?? fb_auth.FirebaseAuth.instance;

  @override
  Future<void> logEvent({
    required String type,
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

  @override
  Stream<List<Map<String, dynamic>>> streamRecentEvents({int limit = 50}) {
    return _db
        .collection('admin_auth_audit_logs')
        .orderBy('timestamp', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => doc.data()).toList());
  }
}
