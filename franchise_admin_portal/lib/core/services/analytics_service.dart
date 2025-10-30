import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';
import 'package:franchise_admin_portal/core/models/analytics_summary.dart';

/// AnalyticsService
/// Used for logging admin/app events to Firebase Analytics,
/// and for retrieving analytics metrics for the admin dashboard.
class AnalyticsService {
  late final FirebaseAnalytics _analytics;

  AnalyticsService() {
    _analytics = FirebaseAnalytics.instance;
  }
  final Logger _logger = Logger('AnalyticsService');

  // --- Analytics Dashboard Methods ---

  /// Returns a stream of AnalyticsSummary (dashboard metrics) for admin panels.
  Stream<List<AnalyticsSummary>> getSummaryMetrics(String franchiseId) {
    return FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('analytics_summaries')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => AnalyticsSummary.fromFirestore(doc.data(), doc.id))
            .toList());
  }

  /// Returns a Future<List<AnalyticsSummary>> for bulk export or reporting.
  Future<List<AnalyticsSummary>> getAnalyticsSummaries(
      String franchiseId) async {
    final snapshot = await FirebaseFirestore.instance
        .collection('franchises')
        .doc(franchiseId)
        .collection('analytics_summaries')
        .get();
    return snapshot.docs
        .map((doc) => AnalyticsSummary.fromFirestore(doc.data(), doc.id))
        .toList();
  }

  /// Exports analytics summaries as a CSV string (for admin export dialog).
  Future<String> exportSummary(String franchiseId) async {
    final summaries = await getAnalyticsSummaries(franchiseId);

    final buffer = StringBuffer();
    // CSV Header
    buffer.writeln(
        'period,totalRevenue,totalOrders,retention,mostPopularItem,averageOrderValue');
    for (final summary in summaries) {
      buffer.writeln(
          '${summary.period},${summary.totalRevenue},${summary.totalOrders},${summary.retention},${summary.mostPopularItem ?? ""},${summary.averageOrderValue}');
    }
    return buffer.toString();
  }

  // --- Event Logging (Admin/Backend Only) ---

  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    try {
      await _analytics.logEvent(
        name: name,
        parameters: parameters?.cast<String, Object>(),
      );
      _logger.info('Logged event: $name with parameters: $parameters');
    } catch (e, stack) {
      _logger.severe('Analytics error ($name): $e', e, stack);
    }
  }

  // ==========================
  // === ADMIN/ADMIN PANEL ====
  // ==========================

  Future<void> logAdminMenuEditorViewed(String userId) async {
    await logEvent('admin_menu_editor_viewed', {'admin_user_id': userId});
  }

  Future<void> logAdminMenuItemAction({
    required String action, // add, update, delete, bulk_upload
    String? menuItemId,
    String? name,
    int? count,
    String? adminUserId,
  }) async {
    await logEvent('admin_menu_item_$action', {
      if (adminUserId != null) 'admin_user_id': adminUserId,
      if (menuItemId != null) 'menu_item_id': menuItemId,
      if (name != null) 'name': name,
      if (count != null) 'count': count,
    });
  }

  Future<void> logAdminCategoryAction({
    required String action, // add, update, delete, bulk_upload
    String? categoryId,
    String? name,
    int? count,
    String? adminUserId,
  }) async {
    await logEvent('admin_category_$action', {
      if (adminUserId != null) 'admin_user_id': adminUserId,
      if (categoryId != null) 'category_id': categoryId,
      if (name != null) 'name': name,
      if (count != null) 'count': count,
    });
  }

  Future<void> logAdminBulkMenuUpload(
      {required int count, String? adminUserId}) async {
    await logEvent('admin_bulk_menu_upload', {
      'count': count,
      if (adminUserId != null) 'admin_user_id': adminUserId,
    });
  }

  Future<void> logAdminMenuExport({int? count, String? adminUserId}) async {
    await logEvent('admin_menu_export', {
      if (count != null) 'count': count,
      if (adminUserId != null) 'admin_user_id': adminUserId,
    });
  }

  // ========================
  // === ERROR/FEEDBACK =====
  // ========================

  Future<void> logError(
      {required String source, required String message, String? stack}) async {
    await logEvent('error', {
      'source': source,
      'message': message,
      if (stack != null) 'stack': stack,
    });
  }

  Future<void> logFeedbackSubmitted(
      {required String feedbackId, required String userId}) async {
    await logEvent('feedback_submitted', {
      'feedback_id': feedbackId,
      'user_id': userId,
    });
  }

  // =======================
  // === IMAGE EVENTS ======
  // =======================

  Future<void> logImageUpload({
    required String menuItemId,
    required String fileName,
    String? adminUserId,
  }) async {
    await logEvent('menu_item_image_uploaded', {
      'menu_item_id': menuItemId,
      'file_name': fileName,
      if (adminUserId != null) 'admin_user_id': adminUserId,
    });
  }

  Future<void> logImageDelete({
    required String menuItemId,
    required String fileName,
    String? adminUserId,
  }) async {
    await logEvent('menu_item_image_deleted', {
      'menu_item_id': menuItemId,
      'file_name': fileName,
      if (adminUserId != null) 'admin_user_id': adminUserId,
    });
  }

  // ========================
  // === PERMISSIONS/AUDIT ===
  // ========================

  Future<void> logUnauthorizedAccess(
      {required String attemptedAction, required String userId}) async {
    await logEvent('unauthorized_access', {
      'attempted_action': attemptedAction,
      'user_id': userId,
    });
  }

  // ========================
  // === EXPORT/IMPORT ======
  // ========================

  Future<void> logExportAction({
    required String type, // menu, category, order, etc
    int? count,
    String? userId,
  }) async {
    await logEvent('export_action', {
      'type': type,
      if (count != null) 'count': count,
      if (userId != null) 'user_id': userId,
    });
  }

  Future<void> logImportAction({
    required String type,
    int? count,
    String? userId,
  }) async {
    await logEvent('import_action', {
      'type': type,
      if (count != null) 'count': count,
      if (userId != null) 'user_id': userId,
    });
  }

  /// Calls the cloud function 'rollupAnalyticsOnDemand' to trigger a manual rollup.
  Future<void> runManualRollup(String franchiseId) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('rollupAnalyticsOnDemand');
      await callable.call({'franchiseId': franchiseId});
    } catch (e) {
      // Optionally handle/log the error here
      rethrow; // or just throw to propagate error
    }
  }

  // =======================
  // === FUTURE EVENTS =====
  // =======================
  // Add new log methods here as new admin features are developed.
}
