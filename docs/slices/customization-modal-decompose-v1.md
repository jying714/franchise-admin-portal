# Slice: Customization modal decompose v1

**Status:** B1 + B2.1 + B2.2.1 COMPLETE on `feat/bounded-context-repos-v1` (smoke pass 2026-08-10)  
**Authority for:** Phase B of the god-object containment plan  
**Branch:** `feat/bounded-context-repos-v1` (merge to `main` when ready)  
**Depends on / pairs with:** `docs/slices/bounded-context-repos-v1.md`  
**Related:** Decision 10 menu-modifier rebuild, M5 dual-tree cutover comments, `STATUS.md`, `HANDOFF.md`

---

## 1. Problem (measured on main)

| Artifact | Size | Reality |
|----------|------|---------|
| `mobile_app/lib/widgets/customization/customization_modal.dart` | ~148 KB | StatefulWidget + large State owns selection maps, profile branching, free-count accounting, price calculation, and composition. |
| `packages/shared_core/lib/src/core/models/menu_item.dart` | ~45 KB | Legacy + canonical Decision-10 fields (`menuProfile`, `modifierGroups`, `inventoryTracked`, `stockCount`). |

**Already extracted sub-widgets (do not re-create):** header, bottom_bar, size_dropdown, sauce/dressing/checkbox/radio groups, optional_addons, wings_*, dinner_included, drinks_flavor, topping_cost_label, portion_pill_toggle, pizza_sauce_selector_tab, current_ingredients.

---

## 2. Goal

1. Pure pricing in `packages/shared_core` (`MenuPricing` + `MenuCustomizationSelection`).
2. `CustomizationController` owns pricing + core selection mutations.
3. Modal remains composition root; public `onConfirm` signature unchanged.
4. Zero behavior change vs pre-extract totals.

---

## 3. Done on branch (2026-08-10)

| Step | Result |
|------|--------|
| **B1** | `MenuPricing`: normalizeSizeKey, basePrice, lineTotal, free sauce/dressing, upcharges, profile flags, wasIncluded, full `customizationsTotal` (incl. ingredient loop) |
| **B1** | `MenuCustomizationSelection` snapshot |
| **B2.1** | `CustomizationController`: size/quantity, pricing getters via MenuPricing |
| **B2.2.1** | Controller mutations: toggleIngredient, setDoubleTopping, toggleAddOn, setSauceCount, setDressingCount, setSideDipCount; end-of-init `syncSelection` hydrate; always-init `_sideDipCounts` (fix LateInitializationError on non-wings) |
| **Smoke** | Pizza / calzone / salad / dinner / wings path green |

**Deferred (not required for burn-in):** B2.2.2 cheeses / pizza-sauce state on controller; B2.2.3 drinks/wings UI ownership; delete modal lockstep copies.

---

## 4. Key paths

```text
packages/shared_core/lib/src/core/domain/menu_pricing.dart
packages/shared_core/lib/src/core/domain/menu_customization_selection.dart
mobile_app/lib/widgets/customization/customization_controller.dart
mobile_app/lib/widgets/customization/customization_modal.dart
```

Export via `shared_core` barrel.

---

## 5. Smoke checklist

1. Pizza / calzone: size, free toppings, extras, double, sauce, dough  
2. Wings: portion, side dip free vs extra  
3. Salad / dinner / sub: dressings, optional add-ons  
4. Quantity multiplies line total  
5. Add-to-cart payload shape + totalPrice  
6. Non-wings items open without LateInitializationError on side-dip maps  

---

## 6. Locks

- Human is the merge gate.
- Soft parallel / manager burn-in continues uninterrupted.
- No change to cart payload or `onConfirm` signature.
- Legacy `MenuItem` fields remain until deliberate re-seed.

**Last updated:** 2026-08-10  
**Last smoke:** 2026-08-10 — pizza / calzone / salad / dinner / wings green after `_sideDipCounts` always-init fix.
