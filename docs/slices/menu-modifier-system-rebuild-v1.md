# Slice: Menu modifier system rebuild v1

**Status**: In progress — M1–M3 HQ + M3 Admin + M4 pizza path landed; M5 open  
**Branch**: `feat/menu-modifier-system-rebuild-v1`  
**Date locked**: July 27, 2026  
**Progress note**: July 28, 2026 — Admin parity, mobile Customize gate, web+mobile modal groups bridge, pricing, cart payload, optionLabels polish; Doughboys partial re-seed; full seed + M5 remain  
**Do not** deliver as a thin Admin Customize patch.

## Problem

Three parallel customization stories:

1. `includedIngredients` / `customizationGroups` / `optionalAddOns` (mobile primary)  
2. `customizations: List<Customization>` (Admin ⋮ Customize)  
3. Mobile **category/name heuristics** (`_isPizza`, wings, drinks, hard-coded Meats/Veggies/…)

Plus: Cook/Cut/Crust forced into **ingredient types**; whole products treated like ingredients; sauce duplication per channel; dual availability flags; Admin Customize spinner; no item-level inventory.

## Goals

1. **One canonical modifier model** for runtime (web + mobile).  
2. **Doughboys pizza UX** via **`menuProfile: pizza`** + group flags — not string matching.  
3. **Any restaurant type** via profiles + arbitrary group labels.  
4. **HQ** = guided setup; **Admin Menu** = day-2 ops; **same schema** (Decision 9).  
5. Options: **ingredient-linked when food is shared/tracked**; **label-only** for structural choices (Cook/Cut/Crust).  
6. **Item inventory**: `inventoryTracked` + `stockCount` (+ optional threshold).  
7. **Clear catalog boundaries**—no fake ingredient types for structure.

## Catalog rules (must implement)

| Concept | Role | Examples |
|---------|------|----------|
| **Ingredient type + ingredient** | Shared kitchen component | Meats, Sauces; BBQ, ranch, pepperoni |
| **Modifier option (non-ingredient)** | Structural / choice without catalog SKU | Cook Regular/Crispy; Cut; Crust Hand-tossed/Thin |
| **Menu item** | What the customer buys | Pizza, Garlic Bread, Cheesecake, soft drink |

**Rules:**

- Ingredient types **must not** include Cook, Cut, Crust.
- Those are **`modifierGroups`** with **label-only options**.
- Whole products = menu items; groups only for real add-ons.
- Shared BBQ = **one** sauce ingredient, many group refs.
- Optional customer extras = groups with **`min: 0`** + max/maxFree + size topping upcharge (web sets rules; mobile enforces).
- **`menuProfile` templates** seed groups (pizza includes Sauce + Meats/Veggies/Cheeses).
- **UI split:** Current toppings = food on the pie; Order Details = crust/cook/cut only; structural option ids must not appear in Current toppings or cart `currentIngredients`.

## Non-goals

- Full SKU ↔ Inventory collection sync (later)  
- Combos/bundles  
- Rewriting entire Admin shell / Platform Owner  
- Keeping dual production code paths after cutover  
- Forcing every drink/flavor into the ingredient catalog  
- Separate legacy `optionalAddOns` editor (removed on HQ path)

## Target shape

```
MenuItem
  menuProfile: standard | pizza | wings | drinks | …
  inventoryTracked, stockCount, lowStockThreshold?
  modifierGroups[]:
    id, label, selectMode, min, max, maxFree?
    allowsPortion?, allowsDouble?
    options[]: ingredientId? | label, upcharge?, upchargeBySize?, defaultSelected?
  sizes[]: SizeData { label, basePrice, toppingPrice }
```

## Workstreams

| ID | Name | Status | Done means |
|----|------|--------|------------|
| **M1** | Schema & contract in `shared_core` | **Done** | Types; inventory; menuProfile; option = ingredient or label |
| **M2** | Read adapter / migration posture | **Done** (adapter); backfill optional | `effective*` getters; human chose wipe + re-seed over mass migrate |
| **M3 HQ** | HQ write path | **Done** | Profile seed, binder, min/max/maxFree, pizza pricing UX, inventory, no legacy UI |
| **M3 Admin** | Admin write path | **Done** | Shared `MenuItemEditorSheet`; list/sort/save; UUID; no dual Customize write for canonical items |
| **M4** | Mobile (+ web modal) renderer | **Done (pizza path)** | Schema-driven groups; profile widgets; Customize gate; maxFree/min/max; size pricing; payload cleanup |
| **M5** | Cutover | **Open** | Flag off legacy; delete dual tree + remaining heuristics; STATUS complete |

### Key files (landed)

**Shared**

- `packages/shared_core/lib/src/core/models/modifier_group.dart`
- `packages/shared_core/lib/src/core/models/menu_profile_templates.dart`
- `packages/shared_core/lib/src/core/models/menu_item.dart` (fields + adapter)
- `packages/shared_core/lib/src/core/models/size_template.dart` (`SizeData`)
- `packages/shared_core/lib/src/core/services/firestore_service_impl.dart` (client-side sort fallback)

**HQ / Admin web**

- `web-app/.../menu_item_editor_sheet.dart`
- `web-app/.../modifier_groups_ingredient_binder.dart`
- `web-app/.../menu_item_utility.dart`
- `web-app/lib/admin/menu/menu_item_editor_panel.dart`
- `web-app/lib/admin/menu/menu_editor_screen.dart`
- `web-app/lib/widgets/customization/customization_modal.dart`
- `web-app/lib/widgets/customization/radio_customization_group.dart`

**Mobile**

- `mobile_app/lib/widgets/menu_item_card.dart` (`modifierGroups` / `sizes` gate)
- `mobile_app/lib/widgets/customization/customization_modal.dart`
- `mobile_app/lib/widgets/customization/radio_customization_group.dart`

## Acceptance (epic)

- [ ] Doughboys pizza/calzone/wings/salad parity on **new** path (full seed + QA)  
- [x] Pizza path: Customize opens; Order Details structural; Current toppings food-only; cart payload clean (S25 smoke)  
- [ ] Non-pizza seed/franchise without pizza heuristics (regression matrix)  
- [x] Cook/Cut/Crust are **groups**, not ingredient types (HQ seed + filter + DB cleanup)  
- [ ] Shared sauce ingredient usable on pizza + wings groups (data + mobile)  
- [x] Dessert/appetizer whole-items without mandatory ingredient self-reference (schema + HQ/Admin save)  
- [x] Admin + HQ same write structure for canonical items  
- [x] Item inventory on HQ edit path  
- [ ] STATUS.md complete only after **M5**  

## Agent / human rules

- No new `if (category.contains('pizza'))` in production paths.  
- No inventing BrandingConfig/DesignTokens fields.  
- Do not reintroduce Cook/Cut/Crust as ingredient types.  
- Human review on schema migration and cutover.  
- Admin ops-fixes slice must **not** absorb M1–M5 (ops slice is closed).
- Do not mark epic complete until M5.
