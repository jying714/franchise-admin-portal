import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:equatable/equatable.dart';
import 'ingredient_reference.dart';

/// Represents a logical group of customizable ingredients,
/// such as "Choose Your Sauce", "Toppings", or "Bread Options".
///
/// A group contains:
/// - A label (displayed to the customer)
/// - A selectionLimit (e.g. choose up to 2 toppings)
/// - A list of valid ingredient references (from IngredientMetadata)
///
/// CustomizationGroup is used inside MenuItem as a nested structure.
class CustomizationGroup extends Equatable {
  final String id;
  final String label;
  final int selectionLimit;
  final List<IngredientReference> ingredients;

  const CustomizationGroup({
    required this.id,
    required this.label,
    required this.selectionLimit,
    required this.ingredients,
  });

  CustomizationGroup copyWith({
    String? id,
    String? label,
    int? selectionLimit,
    List<IngredientReference>? ingredients,
  }) {
    return CustomizationGroup(
      id: id ?? this.id,
      label: label ?? this.label,
      selectionLimit: selectionLimit ?? this.selectionLimit,
      ingredients: ingredients ?? this.ingredients,
    );
  }

  factory CustomizationGroup.fromMap(Map<String, dynamic> map) {
    return CustomizationGroup(
      id: map['id'] ?? '',
      label: map['label'] ?? '',
      selectionLimit: map['selectionLimit'] ?? 1,
      ingredients: (map['ingredients'] as List?)
              ?.where((e) => e != null)
              .map((e) {
            print(
                '[DEBUG] Ingredient entry type: ${e.runtimeType} | value: $e');

            if (e is IngredientReference) return e;
            if (e is Map)
              return IngredientReference.fromMap(Map<String, dynamic>.from(e));
            if (e is String) {
              // Defensive: convert string id to IngredientReference
              return IngredientReference(
                id: e,
                name: e,
                typeId: '',
                isRemovable: true,
              );
            }
            throw Exception("Invalid ingredient entry: $e");
          }).toList() ??
          [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'selectionLimit': selectionLimit,
      'ingredients': ingredients.map((e) => e.toMap()).toList(),
    };
  }

  factory CustomizationGroup.fromFirestore(DocumentSnapshot doc) {
    return CustomizationGroup.fromMap(doc.data() as Map<String, dynamic>);
  }

  Map<String, dynamic> toFirestore() => toMap();

  @override
  List<Object?> get props => [id, label, selectionLimit, ingredients];

  bool get isValid => label.trim().isNotEmpty && ingredients.isNotEmpty;

  @override
  String toString() {
    return 'CustomizationGroup(id: $id, label: $label, limit: $selectionLimit, ingredients: ${ingredients.length})';
  }
}
