class Category {
  /// Unique Firestore doc ID for this category (immutable, not written back).
  final String id;

  /// Display name for the category (e.g., "Pizzas", "Salads").
  final String name;

  /// Optional image URL (network) or asset path for category icon/thumbnails.
  /// If missing or blank, UI should use a branded fallback asset.
  final String? image;

  /// Optional description of the category (for admin/backend/future use).
  final String? description;

  const Category({
    required this.id,
    required this.name,
    this.image,
    this.description,
  });

  /// Creates a Category from Firestore document data plus its doc ID.
  factory Category.fromFirestore(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      image: (data['image'] as String?)?.trim(),
      description: (data['description'] as String?)?.trim(),
    );
  }

  /// Serializes this Category for writing to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (image != null && image!.isNotEmpty) 'image': image,
      if (description != null && description!.isNotEmpty)
        'description': description,
    };
  }
}
