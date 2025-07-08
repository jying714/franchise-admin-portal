import 'package:cloud_firestore/cloud_firestore.dart';

class ErrorLog {
  final String id;
  final String message;
  final String severity;
  final String source;
  final String screen;
  final String? stackTrace;
  final Map<String, dynamic>? contextData;
  final Map<String, dynamic>? deviceInfo;
  final String? userId;
  final String? errorType;
  final String? assignedTo;
  final bool resolved;
  final bool archived;
  final List<Map<String, dynamic>> comments;
  final DateTime timestamp;
  final DateTime? updatedAt;

  ErrorLog({
    required this.id,
    required this.message,
    required this.severity,
    required this.source,
    required this.screen,
    this.stackTrace,
    this.contextData,
    this.deviceInfo,
    this.userId,
    this.errorType,
    this.assignedTo,
    this.resolved = false,
    this.archived = false,
    this.comments = const [],
    required this.timestamp,
    this.updatedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'message': message,
      'severity': severity,
      'source': source,
      'screen': screen,
      'stackTrace': stackTrace,
      'contextData': contextData,
      'deviceInfo': deviceInfo,
      'userId': userId,
      'errorType': errorType,
      'assignedTo': assignedTo,
      'resolved': resolved,
      'archived': archived,
      'comments': comments,
      'timestamp': timestamp.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  /// Use this ONLY if you are *certain* the doc is valid (e.g. after tryParse).
  factory ErrorLog.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    DateTime parseTimestamp(dynamic ts) {
      if (ts == null) throw Exception('Missing timestamp');
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      if (ts is String)
        return DateTime.tryParse(ts) ??
            (throw Exception('Invalid string timestamp'));
      throw Exception('Unknown timestamp type');
    }

    List<Map<String, dynamic>> parseComments(dynamic val) {
      if (val is List) {
        return val
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    }

    final DateTime timestamp = parseTimestamp(data['timestamp']);

    return ErrorLog(
      id: doc.id,
      message: data['message'] ?? '',
      severity: data['severity'] ?? 'unknown',
      source: data['source'] ?? '',
      screen: data['screen'] ?? '',
      stackTrace: data['stackTrace'],
      contextData: (data['contextData'] as Map?)?.cast<String, dynamic>(),
      deviceInfo: (data['deviceInfo'] as Map?)?.cast<String, dynamic>(),
      userId: data['userId'],
      errorType: data['errorType'],
      assignedTo: data['assignedTo'],
      resolved: data['resolved'] ?? false,
      archived: data['archived'] ?? false,
      comments: parseComments(data['comments']),
      timestamp: timestamp,
      updatedAt:
          data['updatedAt'] != null ? parseTimestamp(data['updatedAt']) : null,
    );
  }

  /// Robust parser: Returns `null` if timestamp is missing or invalid.
  static ErrorLog? tryParse(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;

    DateTime? parseTimestamp(dynamic ts) {
      if (ts == null) return null;
      if (ts is Timestamp) return ts.toDate();
      if (ts is DateTime) return ts;
      if (ts is String) return DateTime.tryParse(ts);
      return null;
    }

    List<Map<String, dynamic>> parseComments(dynamic val) {
      if (val is List) {
        return val
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    }

    final DateTime? timestamp = parseTimestamp(data['timestamp']);
    if (timestamp == null) {
      // Uncomment for debugging:
      // print('Skipped error log ${doc.id} with invalid timestamp: ${data['timestamp']}');
      return null;
    }

    return ErrorLog(
      id: doc.id,
      message: data['message'] ?? '',
      severity: data['severity'] ?? 'unknown',
      source: data['source'] ?? '',
      screen: data['screen'] ?? '',
      stackTrace: data['stackTrace'],
      contextData: (data['contextData'] as Map?)?.cast<String, dynamic>(),
      deviceInfo: (data['deviceInfo'] as Map?)?.cast<String, dynamic>(),
      userId: data['userId'],
      errorType: data['errorType'],
      assignedTo: data['assignedTo'],
      resolved: data['resolved'] ?? false,
      archived: data['archived'] ?? false,
      comments: parseComments(data['comments']),
      timestamp: timestamp,
      updatedAt:
          data['updatedAt'] != null ? parseTimestamp(data['updatedAt']) : null,
    );
  }
}
