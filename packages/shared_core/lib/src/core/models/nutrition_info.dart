import 'package:cloud_firestore/cloud_firestore.dart';

/// Nutritional information for a menu item
class NutritionInfo {
  final int calories; // Total calories
  final double fat; // Total fat (grams)
  final double carbs; // Total carbohydrates (grams)
  final double protein; // Total protein (grams)
  final double? fiber; // Dietary fiber (grams, optional)
  final double? sugar; // Sugar (grams, optional)
  final double? sodium; // Sodium (mg, optional)
  final double? cholesterol; // Cholesterol (mg, optional)
  final String? servingSize; // e.g., "1 slice (100g)"
  Map<String, dynamic> toJson() => toFirestore();

  NutritionInfo({
    this.calories = 0,
    this.fat = 0.0,
    this.carbs = 0.0,
    this.protein = 0.0,
    this.fiber,
    this.sugar,
    this.sodium,
    this.cholesterol,
    this.servingSize,
  });

  // From Firestore/Map
  factory NutritionInfo.fromFirestore(Map<String, dynamic> data) {
    return NutritionInfo(
      calories: data['calories'] ?? 0,
      fat: (data['fat'] ?? 0.0).toDouble(),
      carbs: (data['carbs'] ?? 0.0).toDouble(),
      protein: (data['protein'] ?? 0.0).toDouble(),
      fiber: data['fiber'] != null ? (data['fiber'] as num).toDouble() : null,
      sugar: data['sugar'] != null ? (data['sugar'] as num).toDouble() : null,
      sodium:
          data['sodium'] != null ? (data['sodium'] as num).toDouble() : null,
      cholesterol: data['cholesterol'] != null
          ? (data['cholesterol'] as num).toDouble()
          : null,
      servingSize: data['servingSize'],
    );
  }

  // To Firestore (for saving)
  Map<String, dynamic> toFirestore() {
    return {
      'calories': calories,
      'fat': fat,
      'carbs': carbs,
      'protein': protein,
      if (fiber != null) 'fiber': fiber,
      if (sugar != null) 'sugar': sugar,
      if (sodium != null) 'sodium': sodium,
      if (cholesterol != null) 'cholesterol': cholesterol,
      if (servingSize != null) 'servingSize': servingSize,
    };
  }

  /// Alias for export/admin tools.
  Map<String, dynamic> toMap() => toFirestore();

  // For copyWith pattern (editing)
  NutritionInfo copyWith({
    int? calories,
    double? fat,
    double? carbs,
    double? protein,
    double? fiber,
    double? sugar,
    double? sodium,
    double? cholesterol,
    String? servingSize,
  }) {
    return NutritionInfo(
      calories: calories ?? this.calories,
      fat: fat ?? this.fat,
      carbs: carbs ?? this.carbs,
      protein: protein ?? this.protein,
      fiber: fiber ?? this.fiber,
      sugar: sugar ?? this.sugar,
      sodium: sodium ?? this.sodium,
      cholesterol: cholesterol ?? this.cholesterol,
      servingSize: servingSize ?? this.servingSize,
    );
  }
}
