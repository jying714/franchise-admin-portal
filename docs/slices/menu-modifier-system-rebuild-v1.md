# Slice: Menu modifier system rebuild v1

**Status**: **Complete** (M1–M5 + wings/calzone W0–W7) — W2 optional residual only  
**Branch**: `feat/menu-modifier-system-rebuild-v1`  
**Date locked**: July 27, 2026  
**Progress note**: July 28, 2026 evening — M5 dual-tree cutover complete; canonical menuProfile/modifierGroups only; wings/calzone/pizza/salad smoke green  
**Do not** deliver as a thin Admin Customize patch.

## Problem

Three parallel customization stories historically:

1. `customizationGroups` / `includedIngredients` / `optionalAddOns`  
2. `customizations: List<Customization>` (Admin)  
3. Mobile category/name heuristics

## Goals

1. One canonical modifier model (web + mobile).  
2. Doughboys pizza via `menuProfile: pizza`.  
3. HQ guided + Admin day-2 same schema (Decision 9).  
4. Label-only structural options (Cook/Cut/Crust).  
5. Item inventory fields.  
6. Clear available vs included vs structural UX on mobile.  
7. Wings + calzone profiles under the same decision (sibling slice **complete**).

## Catalog rules

| Concept | Role |
|---------|------|
| Ingredient type + ingredient | Shared kitchen component |
| Modifier option (non-ingredient) | Structural choice |
| Menu item | What the customer buys |

- Cook/Cut/Crust never as ingredient types.  
- Optional extras: groups with `min: 0` + max/maxFree **and/or** `optionalAddOns` typed pools for pizza / standard optional lists for salad-dinner.

## Locked mobile pizza contract (July 28 — do not regress)

| Field | Role |
|-------|------|
| `includedIngredients` | Defaults: food → Current; cheeses/sauces → section pre-select only; **included in base price** |
| `optionalAddOns` | **Primary available pool** by `typeId` |
| `modifierGroups` | Crust/Cook/Cut + min/max/maxFree |

| UI section | Behavior |
|------------|----------|
| Current Toppings | Food on pie only |
| Additional Toppings | Meats \| Veggies from optionalAddOns minus Current |
| Cheeses / Sauces | Section Add/Remove + portion + double |
| Order Details | Crust / Cook / Cut (template merge if stored groups omit) |
| Flat Optional add-ons | Hidden on pizza/calzone |

**HQ:** Included toppings + Optional add-ons must remain editable and **persisted** on save (not on wings profile).

## Related: Wings + Calzone

Full product + workstreams: **`docs/slices/hq-wings-calzone-v1.md`** — **W0–W7 complete**.

- `menuProfile: calzone` — pizza twin, no left/right.  
- `menuProfile: wings` — 2 portions, Plain, item sauce bind + free cups on item maps.

## M5 — Dual-tree cutover (**Done** July 28)

Stop supporting **legacy + canonical** production paths in parallel — completed:

1. Writers: `MenuItem.toFirestore` always emits `menuProfile` + `modifierGroups`; skips empty dual lists (`customizations` / `customizationGroups`). HQ/Admin editor + form paths preserve canonical fields.  
2. Readers: `effectiveMenuProfile` / `effectiveModifierGroups` are stored-only (legacy heuristics + `_legacyToModifierGroups` deleted).  
3. Data: full reseed under new schema; legacy dual-tree documents deleted (no backfill job required).  
4. Dead paths removed: Admin `MenuItemCustomizationsDialog` + `customization_types.dart`; day-2 form dual Customize entry; offline cache carries profile/groups (DB v3). Dynamic form Save preserves canonical fields.  
5. Full smoke green (pizza / wings / calzone / salad-standard).

**Do not** reintroduce dual production write paths after M5.

## Non-goals

- Full Inventory collection sync  
- Combos/bundles  
- Reintroducing dual production write paths after M5  
- Refactoring cheeses/sauces back into Current Toppings or SauceSelectorGroup primary UI  
- Hard-coded wing free-cup counts in Dart  
- New salad/dinner MenuProfile (standard + optionalAddOns is enough)

## Workstreams

| ID | Status |
|----|--------|
| M1 Schema | Done |
| M2 Adapter | Done |
| M3 HQ (+ included/optional UI) | Done |
| M3 Admin | Done |
| M4 Mobile/web pizza | Done (CBR PASS) |
| Wings + calzone W0–W7 | **Done** |
| W2 franchise sauce pool | Open (optional) |
| M5 Cutover | **Done** (July 28) |

## Acceptance (epic)

- [x] Pizza path Customize + Order Details + Current food-only + cheeses/sauces (CBR)  
- [x] Wings acceptance (hq-wings-calzone-v1 W7)  
- [x] Calzone acceptance (hq-wings-calzone-v1 W7)  
- [x] Cook/Cut/Crust as groups  
- [x] HQ + Admin same write structure  
- [x] M5 dual-tree cutover (canonical-only write/read; legacy adapter removed; dual Admin Customize UI deleted; Dynamic form preserves profile/groups)  
- [x] STATUS complete only after **M5**

## Agent / human rules

- No new production `category.contains('pizza')` for behavior.  
- Do not strip HQ included/optional fields or save as empty constants (except clear on wings profile switch).  
- Do not collapse pizza cheeses/sauces into Current Toppings.  
- Do not invent `wing_sauces` ingredient type.  
- Do not reintroduce dual production write paths after M5.
