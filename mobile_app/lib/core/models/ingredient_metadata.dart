// lib/core/models/ingredient_metadata.dart

import 'package:flutter/foundation.dart';

@immutable
class IngredientMetadata {
  /// Unique ingredient ID (e.g., "cheese_mozzarella")
  final String id;

  /// Display name (e.g., "Mozzarella Cheese")
  final String name;

  /// Category/group for ingredient (e.g., "cheeses", "meats", "veggies", etc.)
  final String type;

  /// List of allergen tags (e.g., ["dairy", "gluten"])
  final List<String> allergens;

  /// Can this ingredient be removed from default ("included") items?
  final bool removable;

  /// Optional size-based upcharge for adding ingredient as extra
  /// Example: { "Small": 0.85, "Large": 1.95 }
  final Map<String, double>? upcharge;

  /// Can customer double/add extra portion of this ingredient?
  final bool supportsExtra;

  /// Can this ingredient be placed only on half (left/right/side) of an item?
  final bool sidesAllowed;

  /// Optional notes or description
  final String? notes;

  /// Inventory status: true if out of stock (for disabling in UI)
  final bool outOfStock;

  /// Optional image for UI display (future-proof)
  final String? imageUrl;

  /// Can the user select an amount (Light/Regular/Extra) for this ingredient?
  final bool amountSelectable;

  /// List of amount options (e.g., ["Light", "Regular", "Extra"])
  final List<String>? amountOptions;

  const IngredientMetadata({
    required this.id,
    required this.name,
    required this.type,
    required this.allergens,
    required this.removable,
    this.upcharge,
    required this.supportsExtra,
    required this.sidesAllowed,
    this.notes,
    required this.outOfStock,
    this.imageUrl,
    required this.amountSelectable,
    this.amountOptions,
  });

  /// Factory constructor for robust deserialization from Firestore or JSON
  factory IngredientMetadata.fromMap(Map<String, dynamic> data) {
    return IngredientMetadata(
      id: data['id'] as String,
      name: data['name'] as String,
      type: data['type'] as String,
      allergens: data['allergens'] is List
          ? List<String>.from(data['allergens'])
          : <String>[],
      removable: data['removable'] is bool ? data['removable'] : true,
      upcharge: data['upcharge'] != null && data['upcharge'] is Map
          ? (data['upcharge'] as Map)
              .map((k, v) => MapEntry(k.toString(), (v as num).toDouble()))
          : null,
      supportsExtra:
          data['supportsExtra'] is bool ? data['supportsExtra'] : false,
      sidesAllowed: data['sidesAllowed'] is bool ? data['sidesAllowed'] : false,
      notes: data['notes'] is String ? data['notes'] : null,
      outOfStock: data['outOfStock'] is bool ? data['outOfStock'] : false,
      imageUrl: data['imageUrl'] is String ? data['imageUrl'] : null,
      amountSelectable:
          data['amountSelectable'] is bool ? data['amountSelectable'] : false,
      amountOptions: data['amountOptions'] is List
          ? List<String>.from(data['amountOptions'])
          : null,
    );
  }

  /// Serialization for uploading to Firestore/JSON
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'type': type,
      'allergens': allergens,
      'removable': removable,
      if (upcharge != null) 'upcharge': upcharge,
      'supportsExtra': supportsExtra,
      'sidesAllowed': sidesAllowed,
      if (notes != null) 'notes': notes,
      'outOfStock': outOfStock,
      if (imageUrl != null) 'imageUrl': imageUrl,
      'amountSelectable': amountSelectable,
      if (amountOptions != null) 'amountOptions': amountOptions,
    };
  }

  /// Return a copy with one or more fields changed
  IngredientMetadata copyWith({
    String? id,
    String? name,
    String? type,
    List<String>? allergens,
    bool? removable,
    Map<String, double>? upcharge,
    bool? supportsExtra,
    bool? sidesAllowed,
    String? notes,
    bool? outOfStock,
    String? imageUrl,
    bool? amountSelectable,
    List<String>? amountOptions,
  }) {
    return IngredientMetadata(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      allergens: allergens ?? List<String>.from(this.allergens),
      removable: removable ?? this.removable,
      upcharge: upcharge ?? this.upcharge,
      supportsExtra: supportsExtra ?? this.supportsExtra,
      sidesAllowed: sidesAllowed ?? this.sidesAllowed,
      notes: notes ?? this.notes,
      outOfStock: outOfStock ?? this.outOfStock,
      imageUrl: imageUrl ?? this.imageUrl,
      amountSelectable: amountSelectable ?? this.amountSelectable,
      amountOptions: amountOptions ?? this.amountOptions,
    );
  }

  /// Equality and hash code override for correct Set/List/map usage
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is IngredientMetadata &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          type == other.type &&
          listEquals(allergens, other.allergens) &&
          removable == other.removable &&
          mapEquals(upcharge, other.upcharge) &&
          supportsExtra == other.supportsExtra &&
          sidesAllowed == other.sidesAllowed &&
          notes == other.notes &&
          outOfStock == other.outOfStock &&
          imageUrl == other.imageUrl &&
          amountSelectable == other.amountSelectable &&
          listEquals(amountOptions, other.amountOptions);

  @override
  int get hashCode =>
      id.hashCode ^
      name.hashCode ^
      type.hashCode ^
      allergens.hashCode ^
      removable.hashCode ^
      upcharge.hashCode ^
      supportsExtra.hashCode ^
      sidesAllowed.hashCode ^
      notes.hashCode ^
      outOfStock.hashCode ^
      imageUrl.hashCode ^
      amountSelectable.hashCode ^
      amountOptions.hashCode;
}
