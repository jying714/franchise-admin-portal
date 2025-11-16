// packages/shared_core/lib/src/core/models/error_log.dart
// PURE DART — NO cloud_firestore, NO flutter

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

  /// For Firestore writes (do NOT include 'id' as field!)
  Map<String, dynamic> toFirestore() {
    return {
      'message': message,
      'severity': severity,
      'source': source,
      'screen': screen,
      if (stackTrace != null) 'stackTrace': stackTrace,
      if (contextData != null) 'contextData': contextData,
      if (deviceInfo != null) 'deviceInfo': deviceInfo,
      if (userId != null) 'userId': userId,
      if (errorType != null) 'errorType': errorType,
      if (assignedTo != null) 'assignedTo': assignedTo,
      'resolved': resolved,
      'archived': archived,
      'comments': comments,
      'timestamp': timestamp, // impl will convert to Timestamp
      if (updatedAt != null) 'updatedAt': updatedAt,
    };
  }

  /// For table views, debug export, etc. (INCLUDES 'id')
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

  factory ErrorLog.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTimestamp(dynamic ts) {
      if (ts == null) {
        throw Exception(
            '[ErrorLog] Missing required "timestamp" field in log: $id');
      }
      if (ts is DateTime) return ts;
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      throw Exception('[ErrorLog] Unrecognized timestamp format in log: $id');
    }

    List<Map<String, dynamic>> parseComments(dynamic val) {
      if (val == null) return [];
      if (val is List) {
        return val
            .where((e) => e is Map || e is Map<String, dynamic>)
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      }
      return [];
    }

    final dynamic ts = data['timestamp'] ?? data['createdAt'];
    if (ts == null) {
      throw Exception('Missing timestamp in ErrorLog "$id"');
    }

    final DateTime timestamp = parseTimestamp(ts);

    return ErrorLog(
      id: id,
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
