import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:admin_portal/config/feature_config.dart';

class NotificationService {
  late final FirebaseMessaging _messaging;
  final Logger _logger = Logger('NotificationService');

  static final NotificationService _instance = NotificationService._internal();
  NotificationService._internal() {
    _messaging = FirebaseMessaging.instance;
  }

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
        // Optionally, handle notification display in-app here
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
    _logger.info('Request to send notification to $token: $title - $body');
    if (!FeatureConfig.instance.statusEnabled) {
      _logger.info('Notifications are disabled by feature toggle.');
      return;
    }
    // Note: For Flutter web, direct client-to-client notifications are NOT possible.
    // Your backend (Node.js, Python, etc) must send notifications via FCM Admin SDK.
    // This is just a stub for admin simulation/testing.
  }
}

/// Handler for background push notifications.
/// Register this in your main() with FirebaseMessaging.onBackgroundMessage.
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  Logger('NotificationService')
      .info('Handling background message: ${message.notification?.title}');
  // Implement any background logic here, e.g., updating badges, state, etc.
}
