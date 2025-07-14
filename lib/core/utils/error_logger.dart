import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:firebase_auth/firebase_auth.dart';

/// Robust Error Logger for all app error logging.
/// Routes unauth/public errors to logPublicError function.
/// Routes authenticated errors to logAppError function.
class ErrorLogger {
  static const String _publicLogUrl =
      'https://us-central1-doughboyspizzeria-2b3d2.cloudfunctions.net/logPublicError';
  static const String _privateLogUrl =
      'https://us-central1-doughboyspizzeria-2b3d2.cloudfunctions.net/logAppError';

  /// Logs an error to the appropriate endpoint based on authentication status.
  /// Optionally pass extra [contextData] for deeper troubleshooting.
  static Future<void> log({
    required String message,
    String? stack,
    String? source,
    String? severity,
    String? screen,
    Map<String, dynamic>? contextData,
  }) async {
    final user = FirebaseAuth.instance.currentUser;
    final isAuthenticated = user != null;

    final url = isAuthenticated ? _privateLogUrl : _publicLogUrl;

    // Always enrich with basic info
    final enrichedContext = <String, dynamic>{
      ...?contextData,
      if (isAuthenticated) 'userId': user!.uid,
      if (isAuthenticated && user.email != null) 'userEmail': user.email,
    };

    final body = {
      'message': message,
      'stack': stack ?? '',
      'source': source ?? '',
      'severity': severity ?? (isAuthenticated ? 'error' : 'public'),
      'screen': screen ?? '',
      'contextData': enrichedContext,
    };

    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(body),
      );

      if (response.statusCode != 200) {
        // Log to console if the server endpoint failed
        // (avoid infinite loop by not retrying failed logs)
        print(
            '[ErrorLogger] Failed to log error to $url: ${response.statusCode} ${response.body}');
      }
    } catch (e, st) {
      // Log local failures (e.g., no network)
      print('[ErrorLogger] Exception during error log: $e\n$st');
    }
  }
}
