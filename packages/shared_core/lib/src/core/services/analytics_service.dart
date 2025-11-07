// packages/shared_core/lib/src/core/services/analytics_service.dart

import 'package:logging/logging.dart';
import '../models/analytics_summary.dart';

/// Pure interface — no Firebase, no Flutter
abstract class AnalyticsService {
  final Logger _logger = Logger('AnalyticsService');

  /// Returns a stream of AnalyticsSummary (dashboard metrics)
  Stream<List<AnalyticsSummary>> getSummaryMetrics(String franchiseId);

  /// Returns a Future<List<AnalyticsSummary>> for bulk export
  Future<List<AnalyticsSummary>> getAnalyticsSummaries(String franchiseId);

  /// Exports analytics summaries as a CSV string
  Future<String> exportSummary(String franchiseId);

  /// Log an event (admin/backend only)
  Future<void> logEvent(String name, Map<String, dynamic>? parameters);

  // === ADMIN LOG METHODS ===
  Future<void> logAdminMenuEditorViewed(String userId);
  Future<void> logAdminMenuItemAction({
    required String action,
    String? menuItemId,
    String? name,
    int? count,
    String? adminUserId,
  });
  Future<void> logAdminCategoryAction({
    required String action,
    String? categoryId,
    String? name,
    int? count,
    String? adminUserId,
  });
  Future<void> logAdminBulkMenuUpload(
      {required int count, String? adminUserId});
  Future<void> logAdminMenuExport({int? count, String? adminUserId});

  // === ERROR/FEEDBACK ===
  Future<void> logError(
      {required String source, required String message, String? stack});
  Future<void> logFeedbackSubmitted(
      {required String feedbackId, required String userId});

  // === IMAGE EVENTS ===
  Future<void> logImageUpload(
      {required String menuItemId,
      required String fileName,
      String? adminUserId});
  Future<void> logImageDelete(
      {required String menuItemId,
      required String fileName,
      String? adminUserId});

  // === PERMISSIONS/AUDIT ===
  Future<void> logUnauthorizedAccess(
      {required String attemptedAction, required String userId});

  // === EXPORT/IMPORT ===
  Future<void> logExportAction(
      {required String type, int? count, String? userId});
  Future<void> logImportAction(
      {required String type, int? count, String? userId});

  /// Triggers manual analytics rollup via Cloud Function
  Future<void> runManualRollup(String franchiseId);
}
