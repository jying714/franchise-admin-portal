import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:doughboys_pizzeria_final/config/feature_config.dart';

class NotificationService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final Logger _logger = Logger('NotificationService');

  // Singleton pattern
  static final NotificationService _instance = NotificationService._internal();
  NotificationService._internal();

  static NotificationService get instance => _instance;

  /// Call this at app startup to request notification permissions and set up handlers.
  Future<void> initialize() async {
    try {
      NotificationSettings settings = await _messaging.requestPermission();
      if (settings.authorizationStatus == AuthorizationStatus.authorized) {
        _logger.info('Notification permission granted');
      } else {
        _logger.warning('Notification permission denied: $settings');
      }

      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        _logger.info(
            'Received foreground notification: ${message.notification?.title}');
        // Optionally, handle notification display in-app
      });

      FirebaseMessaging.onBackgroundMessage(
          _firebaseMessagingBackgroundHandler);
    } catch (e) {
      _logger.severe('Notification initialization error: $e');
    }
  }

  /// Returns the current device's FCM token (for push notifications).
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      _logger.severe('Error getting FCM token: $e');
      return null;
    }
  }

  /// Simulate sending a notification.
  /// In production, POST to your backend server which will send via FCM Admin SDK.
  Future<void> sendNotification(String token, String title, String body) async {
    _logger.info('Sending notification to $token: $title - $body');
    // Check if status notifications are enabled by feature toggle:
    if (!FeatureConfig.instance.statusEnabled) {
      _logger.info('Notifications are disabled by feature toggle.');
      return;
    }
    // In a real implementation, call your backend/cloud function here.
  }
}

/// Handler for background push notifications.
/// Be sure to register this in your main() with FirebaseMessaging.onBackgroundMessage.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logger('NotificationService')
      .info('Handling background message: ${message.notification?.title}');
  // Implement any background logic here (e.g., badge update)
}
