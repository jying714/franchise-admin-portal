import 'package:shared_core/shared_core.dart' as shared;

class FavoriteOrder {
  final String id;
  final String name;
  final List<shared.OrderItem> items; // Use shared type
  final DateTime timestamp;

  FavoriteOrder({
    required this.id,
    this.name = '',
    this.items = const [],
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();
}
