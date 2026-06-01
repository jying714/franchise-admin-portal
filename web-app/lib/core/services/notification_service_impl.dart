// web-app/lib/core/services/notification_service_impl.dart

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:logging/logging.dart';
import 'package:shared_core/shared_core.dart' as shared;
import 'package:franchise_admin_portal/config/feature_config.dart'; // Keep this if you need local loader, but FeatureConfig comes from shared

class NotificationServiceImpl implements shared.NotificationService {
  late final FirebaseMessaging _messaging;
  final Logger _logger = Logger('NotificationServiceImpl');

  static final NotificationServiceImpl _instance =
      NotificationServiceImpl._internal();

  NotificationServiceImpl._internal() {
    _messaging = FirebaseMessaging.instance;
  }

  static NotificationServiceImpl get instance => _instance;

  @override
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
      });

      FirebaseMessaging.onBackgroundMessage(
          shared.NotificationService.firebaseMessagingBackgroundHandler);
    } catch (e) {
      _logger.severe('Notification initialization error: $e');
    }
  }

  @override
  Future<String?> getToken() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      _logger.severe('Error getting FCM token: $e');
      return null;
    }
  }

  @override
  Future<void> sendNotification(String token, String title, String body) async {
    _logger.info('Request to send notification to $token: $title - $body');

    if (!shared.FeatureConfig.instance.statusEnabled) {
      _logger.info('Notifications are disabled by feature toggle.');
      return;
    }

    // Note: Real sending must happen via backend Cloud Function / FCM Admin SDK
  }
}
