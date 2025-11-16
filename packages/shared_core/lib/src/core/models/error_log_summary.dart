// packages/shared_core/lib/src/core/models/error_log_summary.dart

/// Lightweight summary for error log dashboards, stats, and tables
/// Used in `getErrorLogSummaries()` to avoid loading full ErrorLog payloads
class ErrorLogSummary {
  final String id;
  final String severity;
  final String source;
  final String screen;
  final String? userId;
  final DateTime timestamp;
  final bool resolved;
  final bool archived;

  ErrorLogSummary({
    required this.id,
    required this.severity,
    required this.source,
    required this.screen,
    this.userId,
    required this.timestamp,
    this.resolved = false,
    this.archived = false,
  });

  factory ErrorLogSummary.fromMap(Map<String, dynamic> data, String id) {
    DateTime parseTimestamp(dynamic ts) {
      if (ts is DateTime) return ts;
      if (ts is String) return DateTime.tryParse(ts) ?? DateTime.now();
      return DateTime.now();
    }

    return ErrorLogSummary(
      id: id,
      severity: data['severity']?.toString() ?? 'unknown',
      source: data['source']?.toString() ?? '',
      screen: data['screen']?.toString() ?? '',
      userId: data['userId']?.toString(),
      timestamp: parseTimestamp(data['timestamp']),
      resolved: data['resolved'] == true,
      archived: data['archived'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'severity': severity,
        'source': source,
        'screen': screen,
        'userId': userId,
        'timestamp': timestamp.toIso8601String(),
        'resolved': resolved,
        'archived': archived,
      };
}
