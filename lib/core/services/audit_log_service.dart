import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:franchise_admin_portal/core/models/audit_log.dart';

class AuditLogService {
  final CollectionReference auditLogsRef =
      FirebaseFirestore.instance.collection('audit_logs');

  /// Adds a generic, flexible audit log entry.
  Future<void> addLog({
    required String userId,
    String? userEmail,
    required String action,
    String? targetType,
    String? targetId,
    dynamic details, // Accepts String or Map
  }) async {
    final log = AuditLog(
      id: '',
      userId: userId,
      userEmail: userEmail ?? '',
      action: action,
      targetType: targetType ?? '',
      targetId: targetId ?? '',
      details: details is Map ? details.toString() : details?.toString(),
      timestamp: DateTime.now(),
    );
    await auditLogsRef.add(log.toFirestore());
  }

  /// Shortcut for logging when an error log is viewed.
  Future<void> logViewedErrorLog({
    required String errorLogId,
    required String userId,
    String? userEmail,
  }) async {
    await addLog(
      userId: userId,
      userEmail: userEmail,
      action: 'view_error_log',
      targetType: 'error_log',
      targetId: errorLogId,
    );
  }

  /// Streams audit logs (filterable by targetType or userId).
  Stream<List<AuditLog>> getLogs({String? targetType, String? userId}) {
    Query query = auditLogsRef.orderBy('timestamp', descending: true);
    if (targetType != null && targetType.isNotEmpty) {
      query = query.where('targetType', isEqualTo: targetType);
    }
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }
    return query.snapshots().map((snap) => snap.docs
        .map((doc) =>
            AuditLog.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList());
  }

  /// Gets audit logs once (filterable by targetType or userId).
  Future<List<AuditLog>> getLogsOnce(
      {String? targetType, String? userId}) async {
    Query query = auditLogsRef.orderBy('timestamp', descending: true);
    if (targetType != null && targetType.isNotEmpty) {
      query = query.where('targetType', isEqualTo: targetType);
    }
    if (userId != null && userId.isNotEmpty) {
      query = query.where('userId', isEqualTo: userId);
    }
    final snap = await query.get();
    return snap.docs
        .map((doc) =>
            AuditLog.fromFirestore(doc.data() as Map<String, dynamic>, doc.id))
        .toList();
  }
}
