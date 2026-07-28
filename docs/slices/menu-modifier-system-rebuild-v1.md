# Slice: Menu modifier system rebuild v1

**Status**: In progress — M1–M4 + wings/calzone W0–W7 done; **M5 cutover open** (next gate); W2 optional  
**Branch**: `feat/menu-modifier-system-rebuild-v1`  
**Date locked**: July 27, 2026  
**Progress note**: July 28, 2026 evening — wings/calzone acceptance PASS; pizza Order Details fallback; salad/dinner optional UX; included-ingredient pricing honesty; **M5 is next**  
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

## M5 — Dual-tree cutover (next)

Stop supporting **legacy + canonical** production paths in parallel:

1. Writers: HQ/Admin persist canonical `menuProfile` + `modifierGroups` (+ intentional product fields: pizza optionalAddOns, wings dip maps, sizes).  
2. Readers: mobile/web prefer profile + groups; shrink legacy-only branches.  
3. Data: backfill live items missing profile/groups.  
4. Delete dead legacy UI/adapters once unused.  
5. Full smoke after cutover.

Do **not** start M5 mid-feature without human scope expansion. Wings/calzone acceptance is green — cutover is now the epic gate.

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
| M5 Cutover | **Open** (next) |

## Acceptance (epic)

- [x] Pizza path Customize + Order Details + Current food-only + cheeses/sauces (CBR)  
- [x] Wings acceptance (hq-wings-calzone-v1 W7)  
- [x] Calzone acceptance (hq-wings-calzone-v1 W7)  
- [x] Cook/Cut/Crust as groups  
- [x] HQ + Admin same write structure  
- [ ] STATUS complete only after **M5**

## Agent / human rules

- No new production `category.contains('pizza')` for behavior.  
- Do not strip HQ included/optional fields or save as empty constants (except clear on wings profile switch).  
- Do not collapse pizza cheeses/sauces into Current Toppings.  
- Do not invent `wing_sauces` ingredient type.  
- Do not mark epic complete until M5.
