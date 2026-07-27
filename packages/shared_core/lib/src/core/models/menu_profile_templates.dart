import 'ingredient_type_model.dart';
import 'modifier_group.dart';

/// Ingredient type names that must not appear in food ingredient pickers.
/// These belong on [ModifierGroup]s as label-only options (Decision 10).
abstract final class StructuralIngredientTypes {
  static const Set<String> names = {
    'cook',
    'cut',
    'crust',
    'cook type',
    'cook types',
    'cut style',
    'cut styles',
    'crust type',
    'crust types',
  };

  static bool isStructuralName(String? name) {
    final n = (name ?? '').trim().toLowerCase();
    if (n.isEmpty) return false;
    return names.contains(n);
  }

  static bool isStructuralType({
    required String? typeId,
    required String? typeName,
    List<IngredientType> types = const [],
  }) {
    if (isStructuralName(typeName)) return true;
    if (typeId == null || typeId.isEmpty) return false;
    for (final t in types) {
      if (t.id == typeId && isStructuralName(t.name)) return true;
    }
    // last resort: typeId itself is a slug like "cook"
    return isStructuralName(typeId);
  }
}

/// Seeds default [ModifierGroup]s for a [MenuProfile].
/// Structural choices (Cook/Cut/Crust) are label-only options — never ingredient types.
abstract final class MenuProfileTemplates {
  /// Returns a fresh list of groups for [profile]. Unknown profiles → standard (empty).
  static List<ModifierGroup> seedGroups(String? profile) {
    switch ((profile ?? MenuProfile.standard).trim().toLowerCase()) {
      case MenuProfile.pizza:
        return _pizza();
      case MenuProfile.wings:
        return _wings();
      case MenuProfile.drinks:
        return _drinks();
      case MenuProfile.standard:
      default:
        return _standard();
    }
  }

  static List<ModifierGroup> _standard() => const [];

  static List<ModifierGroup> _drinks() {
    // Optional shell only — franchises fill sizes/flavors as label or ingredient options.
    return [
      ModifierGroup(
        id: 'size',
        label: 'Size',
        selectMode: ModifierSelectMode.single,
        min: 1,
        max: 1,
        sortOrder: 0,
        options: const [],
      ),
    ];
  }

  static List<ModifierGroup> _wings() {
    return [
      ModifierGroup(
        id: 'wing_sauce',
        label: 'Sauce',
        selectMode: ModifierSelectMode.multi,
        min: 1,
        max: 2,
        sortOrder: 0,
        options: const [], // bind sauce ingredientIds in editor
      ),
      ModifierGroup(
        id: 'wing_dips',
        label: 'Dipping cups',
        selectMode: ModifierSelectMode.multi,
        min: 0,
        max: 4,
        maxFree: 0,
        sortOrder: 1,
        options: const [],
      ),
    ];
  }

  static List<ModifierGroup> _pizza() {
    return [
      ModifierGroup(
        id: 'crust',
        label: 'Crust',
        selectMode: ModifierSelectMode.single,
        min: 1,
        max: 1,
        sortOrder: 0,
        options: const [
          ModifierOption(id: 'crust_hand_tossed', label: 'Hand tossed'),
          ModifierOption(id: 'crust_thin', label: 'Thin'),
          ModifierOption(id: 'crust_thick', label: 'Thick'),
          ModifierOption(id: 'crust_gluten_free', label: 'Gluten free'),
        ],
      ),
      ModifierGroup(
        id: 'cook',
        label: 'Cook',
        selectMode: ModifierSelectMode.single,
        min: 1,
        max: 1,
        sortOrder: 1,
        options: const [
          ModifierOption(
              id: 'cook_regular', label: 'Regular', defaultSelected: true),
          ModifierOption(id: 'cook_crispy', label: 'Crispy'),
          ModifierOption(id: 'cook_well_done', label: 'Well done'),
        ],
      ),
      ModifierGroup(
        id: 'cut',
        label: 'Cut',
        selectMode: ModifierSelectMode.single,
        min: 1,
        max: 1,
        sortOrder: 2,
        options: const [
          ModifierOption(id: 'cut_pie', label: 'Pie', defaultSelected: true),
          ModifierOption(id: 'cut_square', label: 'Square'),
        ],
      ),
      // Sauce before toppings — ingredient-linked in binder.
      ModifierGroup(
        id: 'sauce',
        label: 'Sauce',
        selectMode: ModifierSelectMode.single,
        min: 0,
        max: 1,
        sortOrder: 5,
        options: const [],
      ),
      ModifierGroup(
        id: 'meats',
        label: 'Meats',
        selectMode: ModifierSelectMode.multi,
        min: 0,
        max: 20,
        maxFree: 0,
        sortOrder: 10,
        allowsPortion: true,
        allowsDouble: true,
        options: const [],
      ),
      ModifierGroup(
        id: 'veggies',
        label: 'Veggies',
        selectMode: ModifierSelectMode.multi,
        min: 0,
        max: 20,
        maxFree: 0,
        sortOrder: 11,
        allowsPortion: true,
        allowsDouble: true,
        options: const [],
      ),
      ModifierGroup(
        id: 'cheeses',
        label: 'Cheeses',
        selectMode: ModifierSelectMode.multi,
        min: 0,
        max: 10,
        maxFree: 0,
        sortOrder: 12,
        allowsPortion: true,
        allowsDouble: true,
        options: const [],
      ),
    ];
  }
}
