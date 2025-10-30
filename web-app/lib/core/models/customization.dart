import 'dart:math';

enum Portion { whole, left, right }

class Customization {
  final String id;
  final String? ingredientId;
  final String name;
  final bool isGroup;
  final double price;
  final bool required;
  final int? minChoices;
  final int? maxChoices;
  final int? maxFree;
  final int? sortOrder;
  final String? group;
  final List<Customization>? options; // Nested options if group
  final bool isDefault;
  final bool outOfStock;
  final Map<String, double>? upcharges; // Per-size upcharge
  final double? extraUpcharge;
  final double? doubleUpcharge;
  final List<String>? dietaryTags;
  final List<String>? allergens;
  final bool allowExtra;
  final bool allowSide;
  final bool hidden;

  // UI-state (not persisted)
  final bool selected;
  final Portion portion;
  final int quantity;

  Customization({
    String? id,
    this.ingredientId,
    required this.name,
    required this.isGroup,
    this.price = 0.0,
    this.required = false,
    this.minChoices,
    this.maxChoices,
    this.maxFree,
    this.sortOrder,
    this.group,
    this.options,
    this.isDefault = false,
    this.outOfStock = false,
    this.upcharges,
    this.extraUpcharge,
    this.doubleUpcharge,
    this.dietaryTags,
    this.allergens,
    this.allowExtra = false,
    this.allowSide = false,
    this.hidden = false,
    this.selected = false,
    this.portion = Portion.whole,
    this.quantity = 1,
  }) : id = id ?? _randomId();

  Map<String, dynamic> toMap() => toFirestore();

  factory Customization.fromMap(Map<String, dynamic> data) =>
      Customization.fromFirestore(data);

  factory Customization.fromFirestore(Map<String, dynamic> data) {
    double parsedPrice = 0.0;
    Map<String, double>? upcharges;
    final priceField = data['price'];
    if (priceField is num) {
      parsedPrice = priceField.toDouble();
    } else if (priceField is Map) {
      upcharges = priceField.map<String, double>(
          (k, v) => MapEntry(k.toString(), (v as num).toDouble()));
      if (upcharges.isNotEmpty) parsedPrice = upcharges.values.first;
    }

    return Customization(
      id: data['id'] ?? _randomId(),
      ingredientId: data['ingredientId'],
      name: data['name'] ?? '',
      isGroup: data['isGroup'] ?? false,
      price: parsedPrice,
      required: data['required'] ?? false,
      minChoices: data['minChoices'],
      maxChoices: data['maxChoices'],
      maxFree: data['maxFree'],
      sortOrder: data['sortOrder'],
      group: data['group'],
      options: data['options'] != null
          ? (data['options'] as List)
              .map((o) =>
                  Customization.fromFirestore(Map<String, dynamic>.from(o)))
              .toList()
          : null,
      isDefault: data['isDefault'] ?? false,
      outOfStock: data['outOfStock'] ?? false,
      upcharges: upcharges ??
          (data['upcharges'] != null
              ? Map<String, double>.from(data['upcharges'])
              : null),
      extraUpcharge: (data['extraUpcharge'] as num?)?.toDouble(),
      doubleUpcharge: (data['doubleUpcharge'] as num?)?.toDouble(),
      dietaryTags: data['dietaryTags'] != null
          ? List<String>.from(data['dietaryTags'])
          : null,
      allergens: data['allergens'] != null
          ? List<String>.from(data['allergens'])
          : null,
      allowExtra: data['allowExtra'] ?? false,
      allowSide: data['allowSide'] ?? false,
      hidden: data['hidden'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() {
    final priceField =
        (upcharges != null && upcharges!.isNotEmpty) ? upcharges : price;
    return {
      'id': id,
      'ingredientId': ingredientId,
      'name': name,
      'isGroup': isGroup,
      'price': priceField,
      'required': required,
      if (minChoices != null) 'minChoices': minChoices,
      if (maxChoices != null) 'maxChoices': maxChoices,
      if (maxFree != null) 'maxFree': maxFree,
      if (sortOrder != null) 'sortOrder': sortOrder,
      if (group != null) 'group': group,
      if (options != null)
        'options': options!.map((o) => o.toFirestore()).toList(),
      'isDefault': isDefault,
      'outOfStock': outOfStock,
      if (upcharges != null && upcharges!.isNotEmpty) 'upcharges': upcharges,
      if (extraUpcharge != null) 'extraUpcharge': extraUpcharge,
      if (doubleUpcharge != null) 'doubleUpcharge': doubleUpcharge,
      if (dietaryTags != null) 'dietaryTags': dietaryTags,
      if (allergens != null) 'allergens': allergens,
      'allowExtra': allowExtra,
      'allowSide': allowSide,
      'hidden': hidden,
      // No UI-state fields are persisted
    };
  }
}

String _randomId([int len = 16]) {
  const chars = 'abcdefghijklmnopqrstuvwxyz0123456789';
  final rand = Random.secure();
  return List.generate(len, (index) => chars[rand.nextInt(chars.length)])
      .join();
}
