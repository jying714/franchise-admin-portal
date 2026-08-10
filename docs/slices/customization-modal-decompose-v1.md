# Slice: Customization modal decompose v1

**Status:** PLANNED (stubs created; no behavior change yet)  
**Authority for:** Phase B of the god-object containment plan  
**Branch:** `main` (soft-release / manager burn-in)  
**Depends on / pairs with:** `docs/slices/bounded-context-repos-v1.md` (pure helpers may land first or in parallel)  
**Related:** Decision 10 menu-modifier rebuild, M5 dual-tree cutover comments, `STATUS.md`, `HANDOFF.md`

---

## 1. Problem (measured on main)

| Artifact | Size | Reality |
|----------|------|---------|
| `mobile_app/lib/widgets/customization/customization_modal.dart` | 148 299 bytes | Single StatefulWidget + large State class owns selection maps, profile branching, free-count accounting, price calculation, and composition. |
| `packages/shared_core/lib/src/core/models/menu_item.dart` | 45 804 bytes (~1 197 lines) | Still declares both legacy customization fields and canonical Decision-10 fields (`menuProfile`, `modifierGroups`, `inventoryTracked`, `stockCount`). |

**Already extracted sub-widgets (do not re-create):**

```text
mobile_app/lib/widgets/customization/
  header.dart
  bottom_bar.dart
  size_dropdown.dart
  sauce_selector_group.dart
  dressing_selector_group.dart
  checkbox_customization_group.dart
  radio_customization_group.dart
  optional_addons_group.dart
  wings_dip_sauce_selector.dart
  wings_portion_selector.dart
  wings_optional_addons_group.dart
  dinner_included_ingredients.dart
  drinks_flavor_selector.dart
  topping_cost_label.dart
  portion_pill_toggle.dart
  pizza_sauce_selector_tab.dart
  current_ingredients.dart
```

The remaining bulk is `_CustomizationModalState` (selection maps + handlers + the three price getters + a large `build` method starting ~line 1588).

---

## 2. Exact logic that must be preserved (zero behavior change)

### Public constructor surface (must stay identical)

```dart
class CustomizationModal extends StatefulWidget {
  final shared.MenuItem menuItem;
  final int initialQuantity;
  final Map<String, dynamic>? initialCustomizations;
  final void Function(
    Map<String, dynamic> customizations,
    int quantity,
    double totalPrice,
  ) onConfirm;
  final Map<String, shared.IngredientMetadata>? ingredientMetadata;
  // …
}
```

Call sites (item screens, etc.) must require zero or one-line changes.

### State maps currently owned by `_CustomizationModalState`

```text
_quantity
_currentIngredients
_groupSelections
_selectedAddOns
_radioSelections
_selectedSize
_doubleToppings / _ingredientPortions / _doubleAddOns
_selectedSauceCounts / _selectedDressingCounts
_ingredientAmounts
_selectedCheeses / _cheesePortions / _cheeseIsDouble
_selectedDippedSauces / _isAnyDipped / _sideDipCounts
_franchiseWingSauceIds
_drinkFlavorCounts / _drinkTotalCount / _drinkMaxPerFlavor
_pizzaSauceSelections / sauce portion & amount
_toppingTabLabels / _selectedToppingTab / _toppingTabGroups
```

### Price arithmetic (exact getters that must keep producing the same numbers)

```dart
double get _customizationsTotal { /* add-ons, dressings (free+extra), sauces (free+extra),
  wings side dips, then per-ingredient logic that branches on
  _isSalad / _isPizzaOrCalzone / wasIncluded / freeToppings index */ }

double get _basePrice {
  // sizePrices map → sizes list → menuItem.price
}

double get _totalPrice => (_basePrice + _customizationsTotal) * _quantity;
```

Profile helpers already present: `_isPizzaOrCalzone()`, `_isWings()`, `_isSalad()`, `_isDinner()`, `_isSub()`, `_isDrinks()`, `_normalizeSizeKey`, `_wasIncludedIngredient`, free-count helpers that currently call into `MenuItem` utilities (`getFreeSauceCountForSize`, etc.).

### MenuItem side (already on model — do not invent)

```dart
bool get isInventoryBlocked =>
    inventoryTracked && (stockCount == null || stockCount! <= 0);
bool get isSellable =>
    availability && !archived && hideInMenu != true && !isInventoryBlocked;

String get effectiveMenuProfile { /* stored menuProfile or MenuProfile.standard */ }
List<ModifierGroup> get effectiveModifierGroups { /* non-empty modifierGroups or const [] */ }
```

Comments on the effective getters state “M5 dual-tree cutover complete for reads”. Legacy fields remain declared and are still used by serialization, `fromTemplate`, `findSchemaIssues`, and free-count helpers. **Do not delete legacy fields in this slice.**

---

## 3. Goal

1. Extract a `CustomizationController` that owns all mutable selection state and the pure price / free-count / validation calculations.
2. Leave `CustomizationModal` as a thin composition root that listens to the controller and wires the already-existing sub-widgets.
3. Move pure pricing / sellability / free-count policy into `packages/shared_core` so the same numbers can later be reused by customer_web and POS without divergence.
4. Keep the exact public constructor and `onConfirm` signature.

---

## 4. Target layout

```text
packages/shared_core/lib/src/core/domain/
  menu_pricing.dart          # pure functions (base price, customizations total, free counts)
  menu_item_policy.dart      # isSellable / isInventoryBlocked extensions or statics (already partially on model)
  branding_facade.dart       # separate Phase C; listed for completeness

mobile_app/lib/widgets/customization/
  customization_controller.dart   # ChangeNotifier (or equivalent) owning selection maps + calling pure helpers
  customization_modal.dart        # shrinks to composition root + listener
  (existing sub-widgets unchanged)
```

Controller stays in `mobile_app` for now because it owns Flutter-facing selection state. Pure arithmetic lives in `shared_core` so it is unit-testable and shareable.

---

## 5. Extraction order (surgical)

| Step | Work | Notes |
|------|------|-------|
| **B0** | Stubs + this slice | Empty files only |
| **B1** | Extract pure helpers first | Move the arithmetic of `_customizationsTotal`, `_basePrice`, free-count resolution, and size-key normalization into `menu_pricing.dart` / `menu_item_policy.dart`. Unit-test the pure functions against the same inputs the getters currently use. Modal continues to call the old getters until wired. |
| **B2** | Introduce `CustomizationController` | Owns the selection maps listed above. Constructor takes `MenuItem` + `ingredientMetadata` map. Methods: `selectOption`, `toggleTopping`, `setSize`, `setQuantity`, `computeTotal`, `toCartPayload` / validation. `notifyListeners` on every mutation. |
| **B3** | Wire modal as composition root | Modal creates/holds the controller, listens, and passes data + callbacks into the existing sub-widgets. Remove duplicated local calculation once the controller path is proven identical. |
| **B4** | Smoke | Mobile item → customize → add-to-cart → cart → checkout. Compare totals and payload shape to pre-refactor behavior for pizza, wings, salad/dinner, drinks, calzone paths. |

Each step is a separate reviewable PR / agent task.

---

## 6. Controller contract (illustrative shape — implement from real state)

```dart
class CustomizationController extends ChangeNotifier {
  CustomizationController(
    this.item, {
    required this.ingredientMap,
    this.initialQuantity = 1,
    Map<String, dynamic>? initialCustomizations,
  });

  final MenuItem item;
  final Map<String, IngredientMetadata> ingredientMap;

  // selection state mirrors current private fields
  // …

  double get basePrice;          // same rules as _basePrice
  double get customizationsTotal; // same rules as _customizationsTotal
  double get totalPrice;         // (base + customizations) * quantity

  Map<String, dynamic> toCartPayload();
  // validation / error string
}
```

The pure functions in `menu_pricing.dart` receive the `MenuItem` plus the current selection maps and return numbers. The controller only holds state and calls those functions.

---

## 7. MenuItem residual rules

- Keep all existing fields and serialization.
- Prefer `effectiveMenuProfile` and `effectiveModifierGroups` for new logic.
- Legacy fields may still be read by free-count helpers and onboarding repair until a deliberate re-seed window.
- Do **not** remove dual-tree / legacy fields in this slice.
- Do **not** add new fields.

---

## 8. Agent / human workflow constraints

- Quote the exact first 8–12 lines (or the exact getter region) of the real file.
- One natural seam per task (one pure function, or one controller method group, or one sub-widget wiring).
- Full method body when replacing an entire getter or handler; before/after for small surgical edits.
- No new fields on `MenuItem` or `FranchiseProvider`.
- “No change needed” is valid when the region already matches the outcome.
- Soft-release mobile order path must stay green.

---

## 9. Explicit non-goals

- Visual redesign of the modal.
- Changing the `onConfirm` signature or cart payload shape.
- Deleting legacy `MenuItem` fields.
- Porting the full controller to customer_web or POS in this slice (shared pure helpers first; surface controllers later).
- Any pricing or free-count behavior change.
- Touching HQ / Admin menu editors (they use different surfaces).

---

## 10. Smoke checklist (must pass with identical numbers)

1. Pizza / calzone: size change, free toppings, extra toppings, double, sauce split / amount, dough.
2. Wings: portion, dipped sauces, side dip cups (free + upcharge).
3. Salad / dinner / sub: included ingredients, dressings, optional add-ons.
4. Drinks: flavor counts / max.
5. Quantity change multiplies total correctly.
6. Add-to-cart payload shape matches pre-refactor (customizations map + quantity + totalPrice).
7. Inventory-blocked / non-sellable items still blocked by existing gates outside the modal.

---

## 11. Locks

- Human is the merge gate.
- Exact arithmetic of `_customizationsTotal` / `_basePrice` / `_totalPrice` is the source of truth until the pure helpers are proven identical by unit test + smoke.
- Existing sub-widgets stay; the modal only shrinks.
- Soft parallel / manager burn-in continues uninterrupted.

**Last updated:** 2026-08-09  
**Next concrete step:** Phase B1 — extract pure `menu_pricing` helpers that reproduce the current `_basePrice` and `_customizationsTotal` results for the same inputs.
