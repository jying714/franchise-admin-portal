import 'package:cloud_firestore/cloud_firestore.dart';

class AuditLog {
  final String id;
  final String action;
  final String userId;
  final String? userEmail; // <-- Add this
  final String targetType;
  final String targetId;
  final String? details;
  final DateTime timestamp;
  final String? ipAddress;

  AuditLog({
    required this.id,
    required this.action,
    required this.userId,
    this.userEmail, // <-- Add this
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
      userEmail: data['userEmail'], // <-- Add this
      targetType: data['targetType'] ?? '',
      targetId: data['targetId'] ?? '',
      details: data['details'],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      ipAddress: data['ipAddress'],
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'action': action,
      'userId': userId,
      'userEmail': userEmail, // <-- Add this
      'targetType': targetType,
      'targetId': targetId,
      'details': details,
      'timestamp': Timestamp.fromDate(timestamp),
      'ipAddress': ipAddress,
    };
  }
}
