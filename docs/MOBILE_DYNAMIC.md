# Mobile App — Dynamic UI Architecture
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 28, 2026 (wings + calzone plan locked)

## Current State
- Mobile ordering flow stable on device (Samsung S25).  
- **M4 pizza path** on `feat/menu-modifier-system-rebuild-v1`:
  - Card gate: `modifierGroups` / `sizes` count as customizable.  
  - Profile-first + `_groupsForUi()` for structural crust/cook/cut.  
  - **Available toppings/cheeses/sauces** for pizza from **`optionalAddOns` by `typeId`**.  
  - **Current Toppings** = food only. Cheeses and sauces stay in their sections.  
  - **Cheeses / Sauces** = ExpansionTile + Add/Remove + portion + Regular/Double.  
  - Flat Optional add-ons **hidden** on pizza/calzone.  
  - Order Details owns structural radios; cart payload excludes crust/cook/cut ids from topping lists.
- Doughboys foundation data seeded (categories, types, ingredients, menu items).
- **Wings + calzone**: product locked; implementation planned (`docs/slices/hq-wings-calzone-v1.md`). Current wings UI may still show empty lists until W4.

## Locked contracts (do not regress)

### Pizza / calzone (calzone = pizza path minus halves)

See menu-modifier slice + STATUS. Agents must not:

- Drive pizza available meats/veggies only from empty modifier options when `optionalAddOns` exists  
- Put cheeses/sauces into Current Toppings  
- Restore SauceSelectorGroup as the primary pizza sauces UI  
- Show bottom Optional add-ons on pizza/calzone  

**Calzone (`menuProfile: calzone`):** same data/UX as pizza; **hide left/right portion** controls.

### Wings (target after W4)

| UI | Behavior |
|----|----------|
| Size | From `sizes`; drives free cups + upcharge |
| Build your wings | Always **2** portions; each **Plain** or sauce from item bind |
| Plain | No toss on that portion; free cups still allowed |
| Dipping sauces | Cup **counts** for same sauce ids; free = `freeDipCupCount[size]`; extras = `sideDipUpcharge[size]` |

**Data:** `dippingSauceOptions` / `sideDipSauceOptions` (same ids); franchise pool under `config/menu_profile_wings`; catalog type `sauces` only.  
**Do not** hard-code free cup numbers in Dart.  
**Do not** invent ingredient type `wing_sauces`.

## Target Architecture
- Single binary; restaurant-type agnostic via `menuProfile` + shared models  
- Decision 10 rebuild; M5 cutover still required for dual-tree removal  

## Implementation Approach
- M1–M4 pizza + optionalAddOns UX — landed  
- Wings + calzone v1 — W0 docs done; W1–W7 open  
- M5 cutover — after profile acceptance  

## Success Criteria
- Pizza UX preserved via profile + optionalAddOns/included contract  
- Wings UX matches locked portion/cup rules without hard-coded counts  
- Calzone reports separately, customizes like pizza without halves  
- No dual runtime trees after M5  

## Risks
- Incomplete wing sauce bind makes UI look broken — seed lists + franchise pool  
- Changing pizza path while implementing wings — keep pizza gates isolated  
