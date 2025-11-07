// packages/shared_core/lib/src/core/services/admin_auth_audit_service.dart

/// Pure interface — no Firebase, no Flutter
abstract class AdminAuthAuditService {
  /// Logs an admin auth event (login, logout, impersonation, etc.)
  Future<void> logEvent({
    required String type,
    String? franchiseId,
    Map<String, dynamic>? metadata,
  });

  /// Streams recent admin auth audit events
  Stream<List<Map<String, dynamic>>> streamRecentEvents({int limit = 50});
}
