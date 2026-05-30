// packages/shared_core/lib/src/core/models/category.dart
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:collection/collection.dart';

@immutable
class Category {
  /// Unique Firestore document ID
  final String id;

  /// Primary name (used as fallback)
  final String name;

  /// Preferred display name (some documents use this)
  final String? displayName;

  /// Image URL for category icon/thumbnail
  final String? image;

  /// Description of the category
  final String? description;

  /// Sort order in menu
  final int? sortOrder;

  /// Active status
  final bool isActive;

  /// Status string (backup field)
  final String? status;

  const Category({
    required this.id,
    required this.name,
    this.displayName,
    this.image,
    this.description,
    this.sortOrder,
    this.isActive = true,
    this.status,
  });

  /// Creates a Category from Firestore document
  factory Category.fromFirestore(Map<String, dynamic> data, String id) {
    return Category(
      id: id,
      name: (data['name'] as String?)?.trim() ??
          (data['displayName'] as String?)?.trim() ??
          '',
      displayName: (data['displayName'] as String?)?.trim(),
      image: (data['image'] as String?)?.trim() ??
          (data['imageUrl'] as String?)?.trim(),
      description: (data['description'] as String?)?.trim(),
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] : null,
      isActive:
          data['isActive'] as bool? ?? (data['status'] == 'active') ?? true,
      status: data['status'] as String?,
    );
  }

  /// Creates from JSON map (used in import/export)
  factory Category.fromMap(Map<String, dynamic> data) {
    final id = (data['id'] as String?) ?? '';
    return Category(
      id: id,
      name: (data['name'] as String?)?.trim() ??
          (data['displayName'] as String?)?.trim() ??
          '',
      displayName: (data['displayName'] as String?)?.trim(),
      image: (data['image'] as String?)?.trim() ??
          (data['imageUrl'] as String?)?.trim(),
      description: (data['description'] as String?)?.trim(),
      sortOrder: data['sortOrder'] is int ? data['sortOrder'] : null,
      isActive:
          data['isActive'] as bool? ?? (data['status'] == 'active') ?? true,
      status: data['status'] as String?,
    );
  }

  /// Serializes for Firestore write
  Map<String, dynamic> toFirestore() {
    return {
      'name': name,
      if (displayName != null && displayName!.isNotEmpty)
        'displayName': displayName,
      if (image != null && image!.isNotEmpty) 'image': image,
      if (description != null && description!.isNotEmpty)
        'description': description,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'isActive': isActive,
      if (status != null) 'status': status,
    };
  }

  /// Copy with overrides
  Category copyWith({
    String? id,
    String? name,
    String? displayName,
    String? image,
    String? description,
    int? sortOrder,
    bool? isActive,
    String? status,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      displayName: displayName ?? this.displayName,
      image: image ?? this.image,
      description: description ?? this.description,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
      status: status ?? this.status,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Category &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          displayName == other.displayName &&
          image == other.image &&
          description == other.description &&
          sortOrder == other.sortOrder &&
          isActive == other.isActive;

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      displayName.hashCode ^
      image.hashCode ^
      description.hashCode ^
      sortOrder.hashCode ^
      isActive.hashCode;

  String? get schemaWarning {
    if (id.isEmpty || name.isEmpty) {
      return "Category missing required id or name: id='$id', name='$name'";
    }
    return null;
  }

  /// Utility methods
  bool matchesId(String? otherId) =>
      otherId != null && id.toLowerCase() == otherId.toLowerCase();

  bool matchesName(String? otherName) =>
      otherName != null &&
      name.trim().toLowerCase() == otherName.trim().toLowerCase();

  static Category? resolveFromReference(
    List<Category> categories, {
    String? id,
    String? name,
  }) {
    final byId = categories.firstWhereOrNull((cat) => cat.matchesId(id));
    if (byId != null) return byId;

    return categories.firstWhereOrNull((cat) => cat.matchesName(name));
  }
}
