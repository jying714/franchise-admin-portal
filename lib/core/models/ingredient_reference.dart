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
    // Support both admin export and runtime keys:
    final id = data['id'] ?? data['ingredientId'] ?? '';
    final name = data['name'] ?? '';
    final typeId = data['typeId'] ?? data['type'] ?? '';
    final isRemovable = data['isRemovable'] ?? data['removable'] ?? true;
    double? upcharge;
    final rawUpcharge = data['upcharge'] ?? data['price'];
    if (rawUpcharge is num) {
      upcharge = rawUpcharge.toDouble();
    } else if (rawUpcharge is String) {
      upcharge = double.tryParse(rawUpcharge);
    } else if (rawUpcharge is Map) {
      // If you want to pick a default size, for example "Large"
      upcharge = (rawUpcharge['Large'] as num?)?.toDouble() ??
          rawUpcharge.values
              .cast<num?>()
              .firstWhere((v) => v != null, orElse: () => null)
              ?.toDouble();
    } else {
      upcharge = null;
    }
    final doubled = data['doubled'] as bool?;
    final side = data['side'] as String?;

    if (id == '' || name == '' || typeId == '') {
      print(
          '[IngredientReference.fromMap] WARNING: missing required fields! map=$data');
    }

    return IngredientReference(
      id: id,
      name: name,
      typeId: typeId,
      doubled: doubled,
      isRemovable: isRemovable,
      upcharge: upcharge,
      side: side,
    );
  }

  bool get isValid => id.isNotEmpty && name.isNotEmpty && typeId.isNotEmpty;

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

  /// Checks if this ingredient reference matches an ID (case-insensitive).
  bool matchesId(String? otherId) =>
      otherId != null && id.toLowerCase() == otherId.toLowerCase();

  /// Checks if this ingredient reference matches a name (case-insensitive, trimmed).
  bool matchesName(String? otherName) =>
      otherName != null &&
      name.trim().toLowerCase() == otherName.trim().toLowerCase();

  /// Checks if this reference matches a typeId (case-insensitive).
  bool matchesTypeId(String? otherTypeId) =>
      otherTypeId != null && typeId.toLowerCase() == otherTypeId.toLowerCase();

  /// Checks if this reference matches the given label (case-insensitive, trimmed).
  bool matchesLabel(String? label) =>
      label != null && name.trim().toLowerCase() == label.trim().toLowerCase();

  /// Batch utility: returns all referenced IDs from a list of IngredientReferences.
  static List<String> extractIds(List<IngredientReference> refs) =>
      refs.map((e) => e.id).where((id) => id.isNotEmpty).toList();
}
