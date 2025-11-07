// web-app/lib/core/services/audit_log_service_impl.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_core/src/core/services/audit_log_service.dart';
import 'package:shared_core/src/core/models/audit_log.dart';
import 'package:shared_core/src/core/utils/error_logger.dart';

class AuditLogServiceImpl implements AuditLogService {
  CollectionReference auditLogsRef() =>
      FirebaseFirestore.instance.collection('audit_logs');

  @override
  Future<void> addLog({
    required String franchiseId,
    required String userId,
    String? userEmail,
    required String action,
    String? targetType,
    String? targetId,
    dynamic details,
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
    final data = log.toFirestore();
    data['franchiseId'] = franchiseId;
    await auditLogsRef().add(data);
  }

  @override
  Future<void> logViewedErrorLog({
    required String franchiseId,
    required String errorLogId,
    required String userId,
    String? userEmail,
  }) async {
    await addLog(
      franchiseId: franchiseId,
      userId: userId,
      userEmail: userEmail,
      action: 'view_error_log',
      targetType: 'error_log',
      targetId: errorLogId,
    );
  }

  @override
  Stream<List<AuditLog>> getLogs({
    required String franchiseId,
    String? targetType,
    String? userId,
  }) {
    Query query = auditLogsRef()
        .where('franchiseId', isEqualTo: franchiseId)
        .orderBy('timestamp', descending: true);
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

  @override
  Future<List<AuditLog>> getLogsOnce({
    required String franchiseId,
    String? targetType,
    String? userId,
  }) async {
    Query query = auditLogsRef()
        .where('franchiseId', isEqualTo: franchiseId)
        .orderBy('timestamp', descending: true);
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

  @override
  Future<void> logOnboardingPublishAudit({
    required String franchiseId,
    required String userId,
    required Map<String, dynamic> exportSnapshot,
    String? userEmail,
  }) async {
    try {
      await addLog(
        franchiseId: franchiseId,
        userId: userId,
        userEmail: userEmail,
        action: 'onboarding_publish',
        targetType: 'onboarding',
        targetId: franchiseId,
        details: exportSnapshot,
      );
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to log onboarding publish audit',
        stack: stack.toString(),
        source: 'AuditLogServiceImpl.logOnboardingPublishAudit',
        contextData: {
          'franchiseId': franchiseId,
          'userId': userId,
          'exportSnapshotKeys': exportSnapshot.keys.toList(),
        },
      );
      rethrow;
    }
  }

  @override
  Future<List<AuditLog>> getOnboardingAuditLogs(String franchiseId) async {
    try {
      final query = auditLogsRef()
          .where('franchiseId', isEqualTo: franchiseId)
          .where('targetType', isEqualTo: 'onboarding')
          .orderBy('timestamp', descending: true);

      final snapshot = await query.get();
      return snapshot.docs
          .map((doc) => AuditLog.fromFirestore(
              doc.data() as Map<String, dynamic>, doc.id))
          .toList();
    } catch (e, stack) {
      ErrorLogger.log(
        message: 'Failed to fetch onboarding audit logs',
        stack: stack.toString(),
        source: 'AuditLogServiceImpl.getOnboardingAuditLogs',
        contextData: {'franchiseId': franchiseId},
      );
      rethrow;
    }
  }
}
