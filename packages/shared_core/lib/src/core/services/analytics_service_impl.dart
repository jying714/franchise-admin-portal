import 'package:flutter/foundation.dart';
import 'analytics_service.dart';
import '../utils/error_logger.dart';
import '../models/analytics_summary.dart';

class AnalyticsServiceImpl implements AnalyticsService {
  @override
  Stream<List<AnalyticsSummary>> getSummaryMetrics(String franchiseId) {
    // TODO: Implement real stream later
    return Stream.value([]);
  }

  @override
  Future<List<AnalyticsSummary>> getAnalyticsSummaries(
      String franchiseId) async {
    return [];
  }

  @override
  Future<String> exportSummary(String franchiseId) async {
    return '';
  }

  @override
  Future<void> logEvent(String name, Map<String, dynamic>? parameters) async {
    if (kDebugMode) {
      print('[Analytics] Event: $name ${parameters ?? {}}');
    }
  }

  @override
  Future<void> logCategoryTap({
    required String franchiseId,
    required String categoryId,
    required String categoryName,
  }) async {
    try {
      if (kDebugMode) {
        print(
            '📊 Analytics: Category Tap - $categoryName ($categoryId) in franchise $franchiseId');
      }
      // TODO: Later integrate with Firebase Analytics or log to Firestore
    } catch (e) {
      ErrorLogger.log(
        message: e.toString(),
        source: 'logCategoryTap',
        stack: StackTrace.current.toString(),
      );
    }
  }

  // Stub the rest for now (add real logic later)
  @override
  Future<void> logAdminMenuEditorViewed(String userId) async {}
  @override
  Future<void> logAdminMenuItemAction({
    required String action,
    String? menuItemId,
    String? name,
    int? count,
    String? adminUserId,
  }) async {}
  @override
  Future<void> logAdminCategoryAction({
    required String action,
    String? categoryId,
    String? name,
    int? count,
    String? adminUserId,
  }) async {}
  @override
  Future<void> logAdminBulkMenuUpload(
      {required int count, String? adminUserId}) async {}
  @override
  Future<void> logAdminMenuExport({int? count, String? adminUserId}) async {}
  @override
  Future<void> logError(
      {required String source, required String message, String? stack}) async {}
  @override
  Future<void> logFeedbackSubmitted(
      {required String feedbackId, required String userId}) async {}
  @override
  Future<void> logImageUpload(
      {required String menuItemId,
      required String fileName,
      String? adminUserId}) async {}
  @override
  Future<void> logImageDelete(
      {required String menuItemId,
      required String fileName,
      String? adminUserId}) async {}
  @override
  Future<void> logUnauthorizedAccess(
      {required String attemptedAction, required String userId}) async {}
  @override
  Future<void> logExportAction(
      {required String type, int? count, String? userId}) async {}
  @override
  Future<void> logImportAction(
      {required String type, int? count, String? userId}) async {}
  @override
  Future<void> runManualRollup(String franchiseId) async {}
}
