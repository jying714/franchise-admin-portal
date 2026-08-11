# Slice: Customization modal decompose v1

**Status:** B1–B2.2.3 COMPLETE on main (2026-08-10/11); **B3–B4 composition-root still open**  
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

## 3. Done (through 2026-08-11)

| Step | Result |
|------|--------|
| **B1** | `MenuPricing` + `MenuCustomizationSelection` |
| **B2.1** | Controller pricing getters |
| **B2.2.1–B2.2.2** | Toppings, sauces, dressings, add-ons, doubles, cheeses |
| **B2.2.3** | Pizza sauce select/portion/amount/reset via controller; summary string-portion fix |
| **Smoke** | Pizza / calzone / salad / dinner / wings green |

**Deferred / remaining for full Phase B finish:**

- Drop dual lockstep maps (controller sole source of truth)
- Modal file size → composition root only
- Optional: drinks/wings ownership on controller
- Optional: move `PizzaSauceSelection` off modal file
- customer_web / POS shared controller (Phase D)

**Suggested branch:** `feat/customization-modal-composition-root`

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

**Last updated:** 2026-08-11
