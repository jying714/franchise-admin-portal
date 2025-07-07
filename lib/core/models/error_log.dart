import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorLog {
  final String id;
  final String message;
  final String severity;
  final String source;
  final String screen;
  final String? stackTrace;
  final Map<String, dynamic>? contextData;
  final DateTime timestamp;

  ErrorLog({
    required this.id,
    required this.message,
    required this.severity,
    required this.source,
    required this.screen,
    this.stackTrace,
    this.contextData,
    required this.timestamp,
  });

  factory ErrorLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ErrorLog(
      id: doc.id,
      message: data['message'] ?? '',
      severity: data['severity'] ?? 'unknown',
      source: data['source'] ?? '',
      screen: data['screen'] ?? '',
      stackTrace: data['stackTrace'],
      contextData: (data['contextData'] as Map?)?.cast<String, dynamic>(),
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }
}
