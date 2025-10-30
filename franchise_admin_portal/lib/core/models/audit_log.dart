import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:convert';

class AuditLog {
  final String id;
  final String action;
  final String userId;
  final String? userEmail;
  final String targetType;
  final String targetId;
  final String? details; // Stored as JSON string if export snapshot
  final DateTime timestamp;
  final String? ipAddress;

  AuditLog({
    required this.id,
    required this.action,
    required this.userId,
    this.userEmail,
    required this.targetType,
    required this.targetId,
    this.details,
    required this.timestamp,
    this.ipAddress,
  });

  factory AuditLog.fromFirestore(Map<String, dynamic> data, String id) {
    return AuditLog(
      id: id,
      action: data['action'] ?? '',
      userId: data['userId'] ?? '',
      userEmail: data['userEmail'],
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      details: data['details'],
      timestamp: (data['timestamp'] is Timestamp)
          ? (data['timestamp'] as Timestamp).toDate()
          : (data['timestamp'] is String)
              ? DateTime.tryParse(data['timestamp']) ?? DateTime.now()
              : DateTime.now(),
      ipAddress: data['ipAddress'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'userId': userId,
      'userEmail': userEmail,
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
    };
  }

  // === UI/Widget Support Getters ===

  /// For widget compatibility, eventType resolves to action.
  String get eventType => action;

  /// For audit trail widget (named createdAt for UI consistency).
  DateTime get createdAt => timestamp;

  /// For audit trail, fallback to userEmail if you have no user name.
  String? get userName =>
      userEmail; // Extend to use actual names if/when you store them

  /// Decodes exportSnapshot if details contains JSON. Returns null if not a JSON export.
  Map<String, dynamic>? get exportSnapshot {
    if (details == null) return null;
    try {
      final map = jsonDecode(details!);
      if (map is Map<String, dynamic>) return map;
    } catch (_) {}
    return null;
  }
}

class AuditLogEventType {
  static const publishOnboarding = 'onboarding_publish';
  static const cancelOnboarding = 'onboarding_cancel';
  static const editOnboarding = 'onboarding_edit';
  // Add more if your app emits more audit event types
}
