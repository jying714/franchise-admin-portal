// lib/core/models/category_model.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

@immutable
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

  ///Sort order
  final int? sortOrder;

  const Category({
    required this.id,
    required this.name,
    this.image,
    this.description,
    this.sortOrder,
  });

  /// Creates a Category from Firestore document data plus its doc ID.
  factory Category.fromFirestore(Map<String, dynamic> data, String id) {
    final cat = Category(
      id: id,
      name: (data['name'] as String?)?.trim() ?? '',
      image: (data['image'] as String?)?.trim(),
      description: (data['description'] as String?)?.trim(),
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] : null,
    );
    if (cat.schemaWarning != null) {
      print('[Category.fromFirestore] WARNING: ${cat.schemaWarning}');
    }
    return cat;
  }

  /// Creates a Category from JSON-decoded map data (used in import dialogs)
  static Category fromMap(Map<String, dynamic> data) {
    final cat = Category(
      id: data['id'] as String? ?? '',
      name: data['name'] as String? ?? '',
      image: data['image'] as String?,
      description: data['description'] as String?,
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] : null,
    );
    if (cat.schemaWarning != null) {
      print('[Category.fromMap] WARNING: ${cat.schemaWarning}');
    }
    return cat;
  }

  /// Serializes this Category for writing to Firestore.
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (image != null && image!.isNotEmpty) 'image': image,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (sortOrder != null) 'sortOrder': sortOrder,
    };
  }

  /// Creates a copy with optional overrides.
  Category copyWith({
    String? id,
    String? name,
    String? image,
    String? description,
    int? sortOrder,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      image: image ?? this.image,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
    );
  }

  /// Equality override to help with provider dirty-state detection.
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          image == other.image &&
          description == other.description;

  @override
  int get hashCode =>
      id.hashCode ^ name.hashCode ^ image.hashCode ^ description.hashCode;

  /// Used in import/export dialogs for JSON encoding
  static String encodeJson(List<Map<String, dynamic>> categoryList) {
    return JsonEncoder.withIndent('  ').convert(categoryList);
  }

  /// Batch validation utility for onboarding.
  static List<String> findMissingReferences(
    List<Category> categories,
    List<String> referencedIdsOrNames,
  ) {
    return referencedIdsOrNames
        .where((ref) => categories
            .every((cat) => !cat.matchesId(ref) && !cat.matchesName(ref)))
        .toList();
  }

  /// Returns true if this Category's id matches the given [id] (case-insensitive).
  bool matchesId(String? otherId) =>
      otherId != null && id.toLowerCase() == otherId.toLowerCase();

  /// Returns true if this Category's name matches the given [name] (case-insensitive, trimmed).
  bool matchesName(String? otherName) =>
      otherName != null &&
      name.trim().toLowerCase() == otherName.trim().toLowerCase();

  /// Static utility to find a category by ID or (fallback) by name from a list.
  static Category? resolveFromReference(
    List<Category> categories, {
    String? id,
    String? name,
  }) {
    // Try by id
    final byId = categories.firstWhereOrNull(
      (cat) => cat.matchesId(id),
    );
    if (byId != null) return byId;

// Try by name (for template onboarding fallbacks)
    final byName = categories.firstWhereOrNull(
      (cat) => cat.matchesName(name),
    );
    return byName;
  }

  /// Returns a warning string if this category is missing critical fields.
  String? get schemaWarning {
    if (id.isEmpty || name.isEmpty) {
      return "Category missing required id or name: id='$id', name='$name'";
    }
    return null;
  }
}
