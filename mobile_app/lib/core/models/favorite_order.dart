// lib/core/models/favorite_order.dart

import 'order.dart';

class FavoriteOrder {
  final String id;
  final String name; // Display name, e.g. "My Usual"
  final List<OrderItem> items; // Reuse your OrderItem model
  final DateTime savedAt;

  FavoriteOrder({
    required this.id,
    required this.name,
    required this.items,
    required this.savedAt,
  });

  // Firestore parsing
  factory FavoriteOrder.fromMap(Map<String, dynamic> data, [String? id]) {
    return FavoriteOrder(
      id: id ?? data['id'] as String,
      name: data['name'] as String? ?? '',
      items: (data['items'] as List<dynamic>? ?? [])
          .map((item) => OrderItem.fromMap(item as Map<String, dynamic>))
          .toList(),
      savedAt: (data['savedAt'] != null)
          ? DateTime.parse(data['savedAt'])
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'items': items.map((item) => item.toMap()).toList(),
      'savedAt': savedAt.toIso8601String(),
    };
  }
}
