# Slice: Menu modifier system rebuild v1

**Status**: Approved — implement as full rebuild (Decision 10)  
**Branch**: `feat/menu-modifier-system-rebuild-v1` off `main`  
**Date locked**: July 27, 2026 (catalog rules refined same day)  
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
7. **Clear catalog boundaries** (below)—no fake ingredient types for structure.

## Catalog rules (must implement)

| Concept | Role | Examples |
|---------|------|----------|
| **Ingredient type + ingredient** | Shared kitchen component | Meats, Sauces; BBQ, ranch, pepperoni |
| **Modifier option (non-ingredient)** | Structural / choice without catalog SKU | Cook Regular/Crispy; Cut Regular/Square; Crust Hand-tossed/Thin |
| **Menu item** | What the customer buys | Pizza, Garlic Bread, Cheesecake, soft drink |

**Rules:**

- Ingredient types **must not** include Cook, Cut, Crust (or equivalent structure).
- Those are **`modifierGroups`** with **label-only options** (unless the franchise truly inventories dough as an ingredient).
- **Cheesecake / garlic bread / many drinks** = menu items. Groups only for real add-ons (e.g. dipping cups on garlic bread).
- **Shared BBQ** (pizza + wings) = **one** sauce ingredient + many group references—not two types.
- **`menuProfile` templates** seed groups (pizza → Crust, Cook, Cut; wings → sauce/heat; standard → none or simple add-ons).

## Non-goals

- Full SKU ↔ Inventory collection sync (later)  
- Combos/bundles  
- Rewriting entire Admin shell / Platform Owner  
- Keeping dual production code paths after cutover  
- Forcing every drink/flavor into the ingredient catalog

## Target shape (contract sketch)

```
MenuItem
  core catalog + sizes/prices
  menuProfile: standard | pizza | wings | drinks | …
  inventoryTracked, stockCount, lowStockThreshold?
  dietaryTags, allergens
  modifierGroups[]:
    id, label
    selectMode: single | multi | quantity
    min, max, maxFree?
    allowsPortion?, allowsDouble?
    options[]:
      ingredientId?     // preferred when shared food / OOS / allergens
      label             // required if no ingredientId (Cook/Cut/Crust)
      upchargeBySize?, defaultSelected?, …
```

Deprecate dual-write of structured `customizations[]` after migration.

## Workstreams

| ID | Name | Done means |
|----|------|------------|
| **M1** | Schema & contract in `shared_core` | Types; inventory; menuProfile; option = ingredient **or** label; validation |
| **M2** | Migration | Doughboys readable as groups + profiles; structural choices not fake ingredient types |
| **M3** | Write path | HQ + Admin shared module; templates seed profile groups; legacy Customize disabled/removed |
| **M4** | Mobile renderer | Schema-driven; profile widgets; Doughboys parity |
| **M5** | Cutover | Flag off legacy; delete dual tree + category heuristics |

## Acceptance (epic)

- [ ] Doughboys pizza/calzone/wings/salad parity on **new** path  
- [ ] Non-pizza seed/franchise without pizza heuristics  
- [ ] Cook/Cut/Crust (or equivalent) are **groups**, not ingredient types  
- [ ] Shared sauce ingredient usable on pizza + wings groups  
- [ ] Dessert/appetizer whole-items without mandatory ingredient self-reference  
- [ ] Admin + HQ same structure; no Customize spinner  
- [ ] Dietary/allergens + item inventory on managers’ edit path  
- [ ] STATUS.md complete only after M5  

## Related docs

- `docs/DECISIONS.md` Decisions 9–10  
- `docs/MOBILE_DYNAMIC.md`  
- `packages/shared_core/lib/src/core/models/menu_item.dart`  
- `mobile_app/lib/widgets/customization/customization_modal.dart`  

## Agent / human rules

- No new `if (category.contains('pizza'))` in production paths.  
- No inventing BrandingConfig/DesignTokens fields.  
- Do not reintroduce Cook/Cut/Crust as ingredient types.  
- Human review on schema migration and cutover.  
- Admin ops-fixes slice must **not** absorb M1–M5.
