// lib/admin/menu_editor/customization_types.dart

import '../../../../packages/shared_core/lib/src/core/models/customization.dart';

/// Editable group of customizations for use in admin dialogs/screens.
/// Fully supports multi/group/option types for franchise/SaaS, upcharges, portion, etc.
class CustomizationGroup {
  final String groupName;
  final String type; // 'single', 'multi', 'quantity'
  final int minSelect;
  final int maxSelect;
  final int? maxFree; // For "first N free" toppings (optional)
  final List<CustomizationOption> options;
  final bool allowExtra;
  final bool allowSide;
  final bool required;
  final double? groupUpcharge; // Upcharge for picking from this group
  final String? groupTag; // For grouping UI in admin

  CustomizationGroup({
    required this.groupName,
    required this.type,
    required this.minSelect,
    required this.maxSelect,
    this.maxFree,
    required this.options,
    this.allowExtra = false,
    this.allowSide = false,
    this.required = false,
    this.groupUpcharge,
    this.groupTag,
  });
}

/// Editable single option inside a customization group.
class CustomizationOption {
  final String name;
  final double price; // Base price/upcharge for this option
  final Map<String, double>? upcharges; // Per-size upcharge (if any)
  final bool isDefault;
  final bool outOfStock;
  final bool allowExtra;
  final bool allowSide;
  final int quantity;
  final Portion portion;
  final String? tag; // e.g., "vegan", "spicy"

  CustomizationOption({
    required this.name,
    required this.price,
    this.upcharges,
    this.isDefault = false,
    this.outOfStock = false,
    this.allowExtra = false,
    this.allowSide = false,
    this.quantity = 1,
    this.portion = Portion.whole,
    this.tag,
  });
}

/// Convert a [Customization] model (from DB) to [CustomizationGroup] for dialog editing.
CustomizationGroup customizationToGroup(Customization c) {
  return CustomizationGroup(
    groupName: c.name,
    type: (c.maxChoices ?? 1) > 1 ? 'multi' : 'single',
    minSelect: c.minChoices ?? 1,
    maxSelect: c.maxChoices ?? 1,
    maxFree: c.maxFree,
    allowExtra: c.allowExtra,
    allowSide: c.allowSide,
    required: c.required,
    groupUpcharge: c.price > 0.0 ? c.price : null,
    groupTag: c.group,
    options: (c.options ?? [])
        .map((o) => CustomizationOption(
              name: o.name,
              price: o.price,
              upcharges: o.upcharges,
              isDefault: o.isDefault,
              outOfStock: o.outOfStock,
              allowExtra: o.allowExtra,
              allowSide: o.allowSide,
              quantity: o.quantity,
              portion: o.portion,
              tag: o.group,
            ))
        .toList(),
  );
}

/// Convert a [CustomizationGroup] (from admin dialog) back to [Customization] for saving to DB.
Customization groupToCustomization(CustomizationGroup g) {
  return Customization(
    name: g.groupName,
    isGroup: true,
    price: g.groupUpcharge ?? 0.0,
    required: g.required,
    minChoices: g.minSelect,
    maxChoices: g.maxSelect,
    maxFree: g.maxFree,
    group: g.groupTag,
    allowExtra: g.allowExtra,
    allowSide: g.allowSide,
    options: g.options
        .map((o) => Customization(
              name: o.name,
              isGroup: false,
              price: o.price,
              upcharges: o.upcharges,
              isDefault: o.isDefault,
              outOfStock: o.outOfStock,
              allowExtra: o.allowExtra,
              allowSide: o.allowSide,
              quantity: o.quantity,
              portion: o.portion,
              group: o.tag,
            ))
        .toList(),
  );
}
