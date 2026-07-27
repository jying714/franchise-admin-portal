# Slice: Menu modifier system rebuild v1

**Status**: Approved — implement as full rebuild (Decision 10)  
**Branch (suggested)**: `feat/menu-modifier-system-rebuild-v1` off `main`  
**Date locked**: July 27, 2026  
**Do not** deliver as a thin Admin Customize patch.

## Problem

Three parallel customization stories:

1. `includedIngredients` / `customizationGroups` / `optionalAddOns` (mobile primary)  
2. `customizations: List<Customization>` (Admin ⋮ Customize)  
3. Mobile **category/name heuristics** (`_isPizza`, wings, drinks, hard-coded Meats/Veggies/…)

Plus duplicate flags (`available`/`availability`), pizza/wings fields bolted on `MenuItem`, Admin Customize spinner, no item-level inventory, dietary not editable in Admin panel.

Patching for MVP would leave live testing clunky and multi-type onboarding blocked.

## Goals

1. **One canonical modifier model** for runtime (web + mobile).  
2. **Doughboys pizza UX** (half toppings, doubles cap, sauce split) via **`menuProfile: pizza`** + group flags — not string matching.  
3. **Any restaurant type** via `standard` (or other) profiles and arbitrary group labels.  
4. **HQ onboarding** = guided setup; **Admin Menu** = day-2 ops; **same schema** (Decision 9).  
5. **Ingredient-linked options by default**; free-text ad-hoc allowed as escape hatch.  
6. **Item inventory**: `inventoryTracked` + `stockCount` (+ optional threshold).

## Non-goals

- Full SKU ↔ Inventory collection sync (later)  
- Combos/bundles  
- Rewriting entire Admin shell / Platform Owner  
- Keeping dual production code paths after cutover

## Target shape (contract sketch)

```
MenuItem
  core catalog + sizes/prices
  menuProfile: standard | pizza | wings | drinks | …
  inventoryTracked, stockCount, lowStockThreshold?
  dietaryTags, allergens
  modifierGroups[]:   // evolve customizationGroups
    id, label
    selectMode: single | multi | quantity
    min, max, maxFree?
    allowsPortion?, allowsDouble?
    options[]: ingredientId? | label, upchargeBySize?, defaultSelected?, …
```

Deprecate dual-write of structured `customizations[]` as a second runtime tree after migration.

## Workstreams

| ID | Name | Done means |
|----|------|------------|
| **M1** | Schema & contract in `shared_core` | Types, validation, docs; inventory fields; menuProfile |
| **M2** | Migration | Doughboys (+ seeds) readable under canonical groups; pizza profile set |
| **M3** | Write path | HQ + Admin editors share module; legacy Admin Customize tree removed or disabled |
| **M4** | Mobile renderer | Schema-driven modal; pizza/wings profile widgets; parity vs current Doughboys orders |
| **M5** | Cutover | Flag off legacy path; delete dead DTOs/heuristic branches from production path |

## Acceptance (epic)

- [ ] Doughboys: order flow parity on representative pizza/calzone/wings/salad items under **new** path  
- [ ] Non-pizza seed or franchise: modifiers work **without** pizza category heuristics  
- [ ] Admin + HQ save the same group structure; no endless Customize spinner  
- [ ] Dietary/allergens editable where managers edit items  
- [ ] Inventory flag + count on tracked items affects availability  
- [ ] STATUS.md marks epic complete only after M5  

## Related docs

- `docs/DECISIONS.md` Decisions 9–10  
- `docs/MOBILE_DYNAMIC.md`  
- `packages/shared_core/lib/src/core/models/menu_item.dart` (current overload)  
- `mobile_app/lib/widgets/customization/customization_modal.dart` (current heuristics)  

## Agent / human rules

- No new `if (category.contains('pizza'))` in production paths.  
- No inventing BrandingConfig/DesignTokens fields.  
- Human review required on schema migration and cutover.  
- Admin ops-fixes slice must **not** absorb M1–M5 scope creep.
