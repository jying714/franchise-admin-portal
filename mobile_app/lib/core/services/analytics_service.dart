import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:logging/logging.dart';

/// AnalyticsService
/// Use this service for logging any app, admin, or user events to Firebase Analytics,
/// and for retrieving analytics metrics for the admin dashboard.
class AnalyticsService {
  final FirebaseAnalytics _analytics = FirebaseAnalytics.instance;
  final Logger _logger = Logger('AnalyticsService');

  // --- Event Logging ---

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

  // =======================
  // === USER EVENTS =======
  // =======================

  Future<void> logCategoryViewed(String categoryName) async {
    await logEvent('category_viewed', {'category': categoryName});
  }

  Future<void> logCategoryTap(String categoryName) async {
    await logEvent('category_tap', {'category': categoryName});
  }

  Future<void> logMenuItemCustomize(
      String menuItemId, String categoryName) async {
    await logEvent('menu_item_customize', {
      'menu_item_id': menuItemId,
      'category': categoryName,
    });
  }

  Future<void> logMenuItemAddedToCart(
      String menuItemId, String categoryName, int quantity) async {
    await logEvent('menu_item_added_to_cart', {
      'menu_item_id': menuItemId,
      'category': categoryName,
      'quantity': quantity,
    });
  }

  Future<void> logBannerTap(String bannerId) async {
    await logEvent('banner_tap', {'banner_id': bannerId});
  }

  Future<void> logOrderPlaced(String orderId, double total) async {
    await logEvent('order_placed', {
      'order_id': orderId,
      'total': total,
    });
  }

  Future<void> logCartCleared() async {
    await logEvent('cart_cleared', {});
  }

  Future<void> logLogin(String method) async {
    await logEvent('login', {'method': method});
  }

  Future<void> logSignUp(String method) async {
    await logEvent('sign_up', {'method': method});
  }

  // ==========================
  // === ADMIN/ADMIN PANEL ====
  // ==========================

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

  // =======================
  // === FUTURE EVENTS =====
  // =======================
  // Add new log methods here as new app features are developed.
  // Always check event parameter type compatibility.
}
