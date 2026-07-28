# Slice: Menu modifier system rebuild v1

**Status**: In progress — M1–M4 pizza path + optionalAddOns UX locked; M5 open  
**Branch**: `feat/menu-modifier-system-rebuild-v1`  
**Date locked**: July 27, 2026  
**Progress note**: July 28, 2026 afternoon — HQ included/optional editor; mobile pizza pools from optionalAddOns; cheeses/sauces section parity; CBR smoke PASS; M5 remains  
**Do not** deliver as a thin Admin Customize patch.

## Problem

Three parallel customization stories historically:

1. `includedIngredients` / `customizationGroups` / `optionalAddOns`  
2. `customizations: List<Customization>` (Admin)  
3. Mobile category/name heuristics

## Goals

1. One canonical modifier model (web + mobile).  
2. Doughboys pizza via `menuProfile: pizza`.  
3. HQ guided + Admin day-2 same schema (Decision 9).  
4. Label-only structural options (Cook/Cut/Crust).  
5. Item inventory fields.  
6. Clear available vs included vs structural UX on mobile.

## Catalog rules

| Concept | Role |
|---------|------|
| Ingredient type + ingredient | Shared kitchen component |
| Modifier option (non-ingredient) | Structural choice |
| Menu item | What the customer buys |

- Cook/Cut/Crust never as ingredient types.  
- Optional extras: groups with `min: 0` + max/maxFree **and/or** `optionalAddOns` typed pools (see mobile contract below).

## Locked mobile pizza contract (July 28 — do not regress)

| Field | Role |
|-------|------|
| `includedIngredients` | Defaults: food → Current Toppings; cheeses/sauces → pre-select in typed sections only |
| `optionalAddOns` | **Primary available pool** by `typeId` (meats, veggies, cheeses, sauces) |
| `modifierGroups` | Crust/Cook/Cut + min/max/maxFree; not the primary available list when optionalAddOns is set |

| UI section | Behavior |
|------------|----------|
| Current Toppings | Food on pie only; **no** cheeses/sauces; no structural ids |
| Additional Toppings | Meats \| Veggies from optionalAddOns minus Current |
| Cheeses | ExpansionTile Add/Remove + portion + Regular/Double; not Current |
| Sauces | **Same UI as cheeses** (not radio/clear SauceSelectorGroup); optional ∪ included sauces |
| Order Details | Crust / Cook / Cut |
| Flat Optional add-ons | Hidden on pizza/calzone |

**HQ:** Included toppings + Optional add-ons must remain editable and **persisted** on save.

## Non-goals

- Full Inventory collection sync  
- Combos/bundles  
- Reintroducing dual production write paths after M5  
- Refactoring cheeses/sauces back into Current Toppings or SauceSelectorGroup primary UI

## Workstreams

| ID | Status |
|----|--------|
| M1 Schema | Done |
| M2 Adapter | Done |
| M3 HQ (+ included/optional UI) | Done |
| M3 Admin | Done |
| M4 Mobile/web pizza | Done (CBR PASS) |
| M5 Cutover | **Open** |

## Acceptance (epic)

- [ ] Full Doughboys re-seed under locked contract  
- [x] Pizza path Customize + Order Details + Current food-only + cheeses/sauces sections (CBR)  
- [ ] Non-pizza regression matrix  
- [x] Cook/Cut/Crust as groups  
- [x] HQ + Admin same write structure  
- [ ] STATUS complete only after **M5**

## Agent / human rules

- No new production `category.contains('pizza')` for behavior.  
- Do not strip HQ included/optional fields or save as empty constants.  
- Do not collapse pizza cheeses/sauces into Current Toppings.  
- Do not mark epic complete until M5.
