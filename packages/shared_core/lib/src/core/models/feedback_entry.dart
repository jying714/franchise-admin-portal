// lib/core/models/feedback.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class FeedbackEntry {
  final String id;
  final int rating;
  final String? comment;
  final List<String> categories;
  final DateTime timestamp;
  final String userId;
  final bool anonymous;
  final String orderId;
  final String subject;
  final String message;
  final String feedbackMode;
  FeedbackEntry({
    required this.id,
    required this.rating,
    this.comment,
    required this.categories,
    required this.timestamp,
    required this.userId,
    required this.anonymous,
    required this.orderId,
    this.subject = '',
    this.message = '',
    this.feedbackMode = 'orderExperience',
  });

  String get title => subject.isNotEmpty ? subject : 'Feedback';

  factory FeedbackEntry.fromFirestore(Map<String, dynamic> data, String id) {
    return FeedbackEntry(
      id: id,
      rating: data['rating'] ?? 0,
      comment: data['comment'],
      categories: (data['categories'] as List<dynamic>?)?.cast<String>() ?? [],
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
      userId: data['userId'] ?? '',
      anonymous: data['anonymous'] ?? false,
      orderId: data['orderId'] ?? '',
      subject: data['subject'] ?? '',
      message: data['message'] ?? data['comment'] ?? '',
      feedbackMode: data['feedbackMode'] ?? 'orderExperience',
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'rating': rating,
      'comment': comment,
      'categories': categories,
      'timestamp': Timestamp.fromDate(timestamp),
      'userId': userId,
      'anonymous': anonymous,
      'orderId': orderId,
      'subject': subject,
      'message': message,
      'feedbackMode': feedbackMode,
    };
  }

  FeedbackEntry copyWith({
    String? id,
    int? rating,
    String? comment,
    List<String>? categories,
    DateTime? timestamp,
    String? userId,
    bool? anonymous,
    String? orderId,
    String? subject,
    String? message,
  }) {
    return FeedbackEntry(
      id: id ?? this.id,
      rating: rating ?? this.rating,
      comment: comment ?? this.comment,
      categories: categories ?? this.categories,
      timestamp: timestamp ?? this.timestamp,
      userId: userId ?? this.userId,
      anonymous: anonymous ?? this.anonymous,
      orderId: orderId ?? this.orderId,
      subject: subject ?? this.subject,
      message: message ?? this.message,
    );
  }
}
