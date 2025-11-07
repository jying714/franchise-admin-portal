// packages/shared_core/lib/src/core/services/audit_log_service.dart

import '../models/audit_log.dart';
import '../utils/error_logger.dart';

/// Pure interface — no Firebase, no Flutter
abstract class AuditLogService {
  /// Adds a generic audit log entry
  Future<void> addLog({
    required String franchiseId,
    required String userId,
    String? userEmail,
    required String action,
    String? targetType,
    String? targetId,
    dynamic details,
  });

  /// Shortcut for logging when an error log is viewed
  Future<void> logViewedErrorLog({
    required String franchiseId,
    required String errorLogId,
    required String userId,
    String? userEmail,
  });

  /// Streams audit logs (filterable)
  Stream<List<AuditLog>> getLogs({
    required String franchiseId,
    String? targetType,
    String? userId,
  });

  /// Gets audit logs once (filterable)
  Future<List<AuditLog>> getLogsOnce({
    required String franchiseId,
    String? targetType,
    String? userId,
  });

  /// Logs onboarding publish event
  Future<void> logOnboardingPublishAudit({
    required String franchiseId,
    required String userId,
    required Map<String, dynamic> exportSnapshot,
    String? userEmail,
  });

  /// Fetches onboarding-related audit logs
  Future<List<AuditLog>> getOnboardingAuditLogs(String franchiseId);
}
