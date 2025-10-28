import 'package:cloud_firestore/cloud_firestore.dart';
import 'menu_item.dart';

class ScheduledOrder {
  final String id;
  final String userId;
  final List<MenuItem> items;
  final String frequency; // e.g., "weekly", "monthly"
  final DateTime nextRun;
  final bool isPaused;
  final DateTime createdAt;

  ScheduledOrder({
    required this.id,
    required this.userId,
    required this.items,
    required this.frequency,
    required this.nextRun,
    this.isPaused = false,
    required this.createdAt,
  });

  factory ScheduledOrder.fromFirestore(Map<String, dynamic> data, String id) {
    return ScheduledOrder(
      id: id,
      userId: data['userId'] ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => MenuItem.fromFirestore(item, item['id'] as String))
          .toList(),
      frequency: data['frequency'] ?? 'weekly',
      nextRun: (data['nextRun'] as Timestamp).toDate(),
      isPaused: data['isPaused'] ?? false,
      createdAt: (data['createdAt'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'userId': userId,
      'items': items.map((item) => item.toFirestore()).toList(),
      'frequency': frequency,
      'nextRun': Timestamp.fromDate(nextRun),
      'isPaused': isPaused,
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  ScheduledOrder copyWith({
    String? id,
    String? userId,
    List<MenuItem>? items,
    String? frequency,
    DateTime? nextRun,
    bool? isPaused,
    DateTime? createdAt,
  }) {
    return ScheduledOrder(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      items: items ?? this.items,
      frequency: frequency ?? this.frequency,
      nextRun: nextRun ?? this.nextRun,
      isPaused: isPaused ?? this.isPaused,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
