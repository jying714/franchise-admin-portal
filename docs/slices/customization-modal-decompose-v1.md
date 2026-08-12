# Slice: Customization modal decompose v1

**Status:** B1–B2.2.3 COMPLETE on main; **B3 dual-write removal COMPLETE** on `feat/customization-modal-composition-root` (2026-08-12); B4 thin file / dead-field delete still open  
**Authority for:** Phase B of the god-object containment plan  
**Related:** `docs/slices/bounded-context-repos-v1.md`, `docs/architecture/containment-progress-2026-08-11.md`, `STATUS.md`, `HANDOFF.md`

---

## 1. Problem (measured at plan baseline)

| Artifact | Size | Reality |
|----------|------|---------|
| `customization_modal.dart` | ~148 KB | State owned selection, pricing, profile branching |
| `menu_item.dart` | ~45 KB | Legacy + Decision-10 fields |

**Already extracted sub-widgets:** header, bottom_bar, size_dropdown, sauce/dressing/checkbox/radio groups, optional_addons, wings_*, dinner_included, drinks_flavor, topping_cost_label, portion_pill_toggle, etc.

---

## 2. Goal

1. Pure pricing in `shared_core` (`MenuPricing` + `MenuCustomizationSelection`).
2. `CustomizationController` owns pricing + core selection mutations.
3. Modal becomes thin composition root (~20–30 KB wiring).
4. Zero behavior change vs pre-extract totals; `onConfirm` signature unchanged.

---

## 3. Done (through 2026-08-12)

| Step | Result |
|------|--------|
| **B1** | `MenuPricing` + `MenuCustomizationSelection` |
| **B2.1** | Controller pricing getters |
| **B2.2.1–B2.2.2** | Toppings, sauces, dressings, add-ons, doubles, cheeses |
| **B2.2.3** | Pizza sauce select/portion/amount/reset via controller; summary string-portion fix |
| **B3** | Runtime dual-write removed for cheeses, toppings, pizza sauces, dressings, add-ons, sauce counts; UI + submit + validation read controller; dead legacy sauce scalars removed |
| **Smoke** | Re-run pizza / calzone / salad / dinner on branch before merge |

**Residual (acceptable until B4):**

- Locals still seeded in `initState` + one `syncSelection` hydrate (cheeses, toppings maps, `_pizzaSauceSelections`, etc.)
- `_ingredientPortions` still modal-local (no controller API yet)
- Radio crust/cook/cut still modal-local via `_radioSelections` / `_currentIngredients`
- Wings / drinks still modal-local
- `PizzaSauceSelection` class still on modal file for init hydrate
- File still large — not yet “thin composition root (~20–30 KB)”

**Still open for full Phase B finish:**

- B4: delete init-only dual maps / `PizzaSauceSelection`; further thin the modal
- Optional: drinks/wings ownership on controller
- customer_web / POS shared controller (Phase D)

**Branch:** `feat/customization-modal-composition-root`

---

## 4. Key paths

```text
packages/shared_core/lib/src/core/domain/menu_pricing.dart
packages/shared_core/lib/src/core/domain/menu_customization_selection.dart
mobile_app/lib/widgets/customization/customization_controller.dart
mobile_app/lib/widgets/customization/customization_modal.dart
```

---

## 5. Locks

- Human is the merge gate.
- Soft parallel continues uninterrupted.
- No change to cart payload or `onConfirm` signature.
- Legacy MenuItem dual-tree fields remain until deliberate re-seed.

**Last updated:** 2026-08-12
