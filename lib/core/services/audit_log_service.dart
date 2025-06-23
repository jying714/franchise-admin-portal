import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/models/audit_log.dart';

class AuditLogService {
  final CollectionReference auditLogsRef =
      FirebaseFirestore.instance.collection('audit_logs');

  // Generic flexible addLog for admin and other use-cases
  Future<void> addLog({
    required String userId,
    required String action,
    String? targetType,
    String? targetId,
    dynamic details, // Accepts String or Map
  }) async {
    final log = AuditLog(
      id: '',
      userId: userId,
      action: action,
      targetType: targetType ?? '',
      targetId: targetId ?? '',
      details: details is Map ? details.toString() : details?.toString(),
      timestamp: DateTime.now(),
    );
    await auditLogsRef.add(log.toFirestore());
  }

  Stream<List<AuditLog>> getLogs({String? targetType, String? userId}) {
    Query query = auditLogsRef.orderBy('timestamp', descending: true);
    if (targetType != null) {
      query = query.where('targetType', isEqualTo: targetType);
    }
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            AuditLog.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  Future<List<AuditLog>> getLogsOnce(
      {String? targetType, String? userId}) async {
    Query query = auditLogsRef.orderBy('timestamp', descending: true);
    if (targetType != null) {
      query = query.where('targetType', isEqualTo: targetType);
    }
    if (userId != null) {
      query = query.where('userId', isEqualTo: userId);
    }
    final snap = await query.get();
    return snap.docs
        .map((doc) =>
            AuditLog.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
