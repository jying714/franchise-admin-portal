// packages/shared_core/lib/src/core/services/notification_service.dart

/// Pure abstract interface for notifications (no Firebase imports)
abstract class NotificationService {
  Future<void> initialize();
  Future<String?> getToken();
  Future<void> sendNotification(String token, String title, String body);

  /// Background handler signature (type-safe, no direct dependency)
  static Future<void> firebaseMessagingBackgroundHandler(Object message) async {
    // Default empty implementation - can be overridden in impl
  }
}
