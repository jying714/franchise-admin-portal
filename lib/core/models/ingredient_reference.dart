import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';

/// Represents a lightweight reference to an ingredient used in menu items.
///
/// This is used to avoid duplicating full ingredient metadata inside each menu item,
/// while still allowing menu-level control over display, placement, and upcharges.
class IngredientReference extends Equatable {
  final String id; // 🔐 Firestore document ID of the ingredient
  final String name;
  final String typeId; // 🔗 Must match an ingredientType defined in schema

  /// Optional override values for UI rendering or pricing
  final bool? doubled; // UI toggle for "Double" portion
  final bool? isRemovable; // Whether customer can deselect this item
  final double? upcharge; // Optional override if ingredient has price

  /// [side] is only relevant for items with placement (left, right, both)
  final String? side; // 'left', 'right', or 'both'

  const IngredientReference({
    required this.id,
    required this.name,
    required this.typeId,
    this.doubled,
    this.isRemovable,
    this.upcharge,
    this.side,
  });

  /// Deserialize from Firestore
  factory IngredientReference.fromMap(Map<String, dynamic> data) {
    return IngredientReference(
      id: data['id'] as String,
      name: data['name'] as String,
      typeId: data['typeId'] as String,
      doubled: data['doubled'] as bool?,
      isRemovable: data['isRemovable'] as bool?,
      upcharge: (data['upcharge'] as num?)?.toDouble(),
      side: data['side'] as String?,
    );
  }

  /// Serialize to Firestore
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'typeId': typeId,
      if (doubled != null) 'doubled': doubled,
      if (isRemovable != null) 'isRemovable': isRemovable,
      if (upcharge != null) 'upcharge': upcharge,
      if (side != null) 'side': side,
    };
  }

  /// Required for form pre-fill & comparison
  IngredientReference copyWith({
    String? id,
    String? name,
    String? typeId,
    bool? doubled,
    bool? isRemovable,
    double? upcharge,
    String? side,
  }) {
    return IngredientReference(
      id: id ?? this.id,
      name: name ?? this.name,
      typeId: typeId ?? this.typeId,
      doubled: doubled ?? this.doubled,
      isRemovable: isRemovable ?? this.isRemovable,
      upcharge: upcharge ?? this.upcharge,
      side: side ?? this.side,
    );
  }

  @override
  List<Object?> get props =>
      [id, name, typeId, doubled, isRemovable, upcharge, side];

  @override
  String toString() => 'IngredientReference($name - $typeId)';
}
