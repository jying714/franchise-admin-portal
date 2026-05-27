class FavoriteOrder {
  final String id;
  final String name;
  final List<dynamic> items;
  final DateTime timestamp;

  FavoriteOrder({required this.id, this.name = '', this.items = const [], DateTime? timestamp}) : timestamp = timestamp ?? DateTime.now();
}
