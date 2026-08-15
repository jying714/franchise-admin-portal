/// Canonical menu modifier contract (Decision 10 / menu-modifier-system-rebuild-v1).
/// Options may be ingredient-linked OR label-only (Cook/Cut/Crust, temps, etc.).

/// Known profiles — open string so franchises can add more without code deploy.
/// Known profiles — open string so franchises can add more without code deploy.
abstract final class MenuProfile {
  static const String standard = 'standard';
  static const String pizza = 'pizza';
  static const String calzone = 'calzone';
  static const String wings = 'wings';
  static const String drinks = 'drinks';
  static const String sub = 'sub';
  static const String salad = 'salad';

  static const List<String> known = [
    standard,
    pizza,
    calzone,
    wings,
    drinks,
    sub,
    salad,
  ];
}

enum ModifierSelectMode {
  single,
  multi,
  quantity;

  static ModifierSelectMode fromString(String? raw) {
    switch ((raw ?? '').trim().toLowerCase()) {
      case 'multi':
        return ModifierSelectMode.multi;
      case 'quantity':
        return ModifierSelectMode.quantity;
      case 'single':
      default:
        return ModifierSelectMode.single;
    }
  }

  String get firestoreValue => name;
}

class ModifierOption {
  final String id;

  /// Display label. Required when [ingredientId] is null (structural choices).
  final String label;

  /// Shared catalog ingredient when option is real food (sauces, toppings).
  final String? ingredientId;
  final bool defaultSelected;
  final double? upcharge;
  final Map<String, double>? upchargeBySize;
  final int? maxQuantity;

  const ModifierOption({
    required this.id,
    required this.label,
    this.ingredientId,
    this.defaultSelected = false,
    this.upcharge,
    this.upchargeBySize,
    this.maxQuantity,
  });

  bool get isLabelOnly => ingredientId == null || ingredientId!.trim().isEmpty;

  bool get isValid =>
      id.trim().isNotEmpty &&
      (label.trim().isNotEmpty ||
          (ingredientId != null && ingredientId!.trim().isNotEmpty));

  factory ModifierOption.fromMap(Map<String, dynamic> map) {
    Map<String, double>? bySize;
    final rawSize = map['upchargeBySize'];
    if (rawSize is Map) {
      bySize = rawSize.map(
        (k, v) => MapEntry(
          k.toString(),
          (v is num) ? v.toDouble() : double.tryParse('$v') ?? 0.0,
        ),
      );
    }
    return ModifierOption(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? map['name'] ?? '').toString(),
      ingredientId: map['ingredientId']?.toString(),
      defaultSelected: map['defaultSelected'] == true,
      upcharge: (map['upcharge'] as num?)?.toDouble(),
      upchargeBySize: bySize,
      maxQuantity: map['maxQuantity'] as int?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      if (ingredientId != null && ingredientId!.isNotEmpty)
        'ingredientId': ingredientId,
      'defaultSelected': defaultSelected,
      if (upcharge != null) 'upcharge': upcharge,
      if (upchargeBySize != null && upchargeBySize!.isNotEmpty)
        'upchargeBySize': upchargeBySize,
      if (maxQuantity != null) 'maxQuantity': maxQuantity,
    };
  }

  ModifierOption copyWith({
    String? id,
    String? label,
    String? ingredientId,
    bool? defaultSelected,
    double? upcharge,
    Map<String, double>? upchargeBySize,
    int? maxQuantity,
  }) {
    return ModifierOption(
      id: id ?? this.id,
      label: label ?? this.label,
      ingredientId: ingredientId ?? this.ingredientId,
      defaultSelected: defaultSelected ?? this.defaultSelected,
      upcharge: upcharge ?? this.upcharge,
      upchargeBySize: upchargeBySize ?? this.upchargeBySize,
      maxQuantity: maxQuantity ?? this.maxQuantity,
    );
  }
}

class ModifierGroup {
  final String id;
  final String label;
  final ModifierSelectMode selectMode;
  final int min;
  final int max;
  final int? maxFree;
  final int? sortOrder;
  final bool allowsPortion;
  final bool allowsDouble;
  final List<ModifierOption> options;

  /// Franchise ingredient_types doc id used to filter bindable options.
  /// Salad dressings: set from config/menu_profile_salad.dressingsSourceTypeId.
  final String? sourceTypeId;

  const ModifierGroup({
    required this.id,
    required this.label,
    this.selectMode = ModifierSelectMode.single,
    this.min = 0,
    this.max = 1,
    this.maxFree,
    this.sortOrder,
    this.allowsPortion = false,
    this.allowsDouble = false,
    this.options = const [],
    this.sourceTypeId,
  });

  bool get isValid =>
      id.trim().isNotEmpty && label.trim().isNotEmpty && min >= 0 && max >= min;

  factory ModifierGroup.fromMap(Map<String, dynamic> map) {
    final rawOpts = map['options'];
    final options = <ModifierOption>[];
    if (rawOpts is List) {
      for (final e in rawOpts) {
        if (e is Map) {
          options.add(
            ModifierOption.fromMap(Map<String, dynamic>.from(e)),
          );
        }
      }
    }
    return ModifierGroup(
      id: (map['id'] ?? '').toString(),
      label: (map['label'] ?? '').toString(),
      selectMode: ModifierSelectMode.fromString(
        map['selectMode']?.toString(),
      ),
      min: (map['min'] as int?) ?? 0,
      max: (map['max'] as int?) ?? 1,
      maxFree: map['maxFree'] as int?,
      sortOrder: map['sortOrder'] as int?,
      allowsPortion: map['allowsPortion'] == true,
      allowsDouble: map['allowsDouble'] == true,
      options: options,
      sourceTypeId: map['sourceTypeId']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'label': label,
      'selectMode': selectMode.firestoreValue,
      'min': min,
      'max': max,
      if (maxFree != null) 'maxFree': maxFree,
      if (sortOrder != null) 'sortOrder': sortOrder,
      'allowsPortion': allowsPortion,
      'allowsDouble': allowsDouble,
      if (sourceTypeId != null && sourceTypeId!.trim().isNotEmpty)
        'sourceTypeId': sourceTypeId,
      'options': options.map((o) => o.toMap()).toList(),
    };
  }

  ModifierGroup copyWith({
    String? id,
    String? label,
    ModifierSelectMode? selectMode,
    int? min,
    int? max,
    int? maxFree,
    int? sortOrder,
    bool? allowsPortion,
    bool? allowsDouble,
    List<ModifierOption>? options,
    String? sourceTypeId,
  }) {
    return ModifierGroup(
      id: id ?? this.id,
      label: label ?? this.label,
      selectMode: selectMode ?? this.selectMode,
      min: min ?? this.min,
      max: max ?? this.max,
      maxFree: maxFree ?? this.maxFree,
      sortOrder: sortOrder ?? this.sortOrder,
      allowsPortion: allowsPortion ?? this.allowsPortion,
      allowsDouble: allowsDouble ?? this.allowsDouble,
      options: options ?? this.options,
      sourceTypeId: sourceTypeId ?? this.sourceTypeId,
    );
  }
}
