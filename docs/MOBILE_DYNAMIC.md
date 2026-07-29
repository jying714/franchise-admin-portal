# Mobile App — Dynamic UI Architecture
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 28, 2026 (W7 PASS; salad/dinner optional UX; pricing honesty)

## Current State
- Mobile ordering flow stable on device (Samsung S25).  
- **M4 pizza path** on `feat/menu-modifier-system-rebuild-v1`:
  - Card gate: `modifierGroups` / `sizes` count as customizable.  
  - Profile-first + `_groupsForUi()` for structural crust/cook/cut (template fallback for pizza Order Details).  
  - **Available toppings/cheeses/sauces** for pizza from **`optionalAddOns` by `typeId`**.  
  - **Current Toppings** = food only. Cheeses and sauces stay in their sections.  
  - **Cheeses / Sauces** = ExpansionTile + Add/Remove + portion + Regular/Double.  
  - Flat Optional add-ons **hidden** on pizza/calzone.  
  - Order Details owns structural radios; cart payload excludes crust/cook/cut ids from topping lists.
- Doughboys foundation data seeded (categories, types, ingredients, menu items).
- **Wings + calzone**: implemented and human-accepted (W0–W7). See `docs/slices/hq-wings-calzone-v1.md`.
- **Salad / dinner**: no Order Details; optional Click-to-Add pool when `optionalAddOns` (and removed included) apply; included never double-listed on optional while on Current.
- **Pricing**: included ingredients are in the menu base price — do not auto-add topping upcharges for non-doubled included items.

## Locked contracts (do not regress)

### Pizza / calzone (calzone = pizza path minus halves)

See menu-modifier slice + STATUS. Agents must not:

- Drive pizza available meats/veggies only from empty modifier options when `optionalAddOns` exists  
- Put cheeses/sauces into Current Toppings  
- Restore SauceSelectorGroup as the primary pizza sauces UI  
- Show bottom Optional add-ons on pizza/calzone  
- Charge included toppings as extras on open (only doubles / true extras)

**Calzone (`menuProfile: calzone`):** same data/UX as pizza for Current/Additional/Cheeses/Sauces; **hide left/right portion** controls; no Order Details required.

### Wings (locked after W4–W7)

| UI | Behavior |
|----|----------|
| Size | From `sizes`; drives free cups + upcharge |
| Build your wings | Always **2** portions; each **Plain** or sauce from item bind |
| Plain | No toss on that portion; free cups still allowed |
| Dipping sauces | Cup **counts** for same sauce ids; free = `freeDipCupCount[size]`; extras = `sideDipUpcharge[size]` |

**Data:** `dippingSauceOptions` / `sideDipSauceOptions` (same ids); catalog type `sauces` only.  
**Do not** hard-code free cup numbers in Dart.  
**Do not** invent ingredient type `wing_sauces`.

### Standard / salad / dinner

| UI | Behavior |
|----|----------|
| Order Details | **Hidden** |
| Current Toppings | No left/right on salad; Remove + double where applicable |
| Optional | Only if HQ set add-ons; Click to Add cards; move to Current; included not shown on both |
| HQ profile | `standard` + optionalAddOns — no dedicated salad/dinner profile required |

## Target Architecture
- Single binary; restaurant-type agnostic via `menuProfile` + shared models  
- Decision 10 rebuild; **M5 cutover** still required for dual-tree removal  

## Implementation Approach
- M1–M4 pizza + optionalAddOns UX — landed  
- Wings + calzone v1 — **complete** (W0–W7)  
- Salad/dinner optional UX — landed  
- M5 cutover — **next**  

## Success Criteria
- Pizza UX preserved via profile + optionalAddOns/included contract  
- Wings UX matches locked portion/cup rules without hard-coded counts  
- Calzone reports separately, customizes like pizza without halves  
- Salad/dinner optional path honest on price and dual-list  
- No dual runtime trees after M5  

## Risks
- Incomplete wing sauce bind makes UI look broken — seed lists on item  
- Changing pizza path while implementing other profiles — keep pizza gates isolated  
- M5 cutover without backfill — items missing `menuProfile`/groups break customize  
