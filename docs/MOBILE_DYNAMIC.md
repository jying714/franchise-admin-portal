# Mobile App — Dynamic UI Architecture
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 28, 2026 (pizza optionalAddOns UX locked)

## Current State
- Mobile ordering flow stable on device (Samsung S25).  
- **M4 pizza path** on `feat/menu-modifier-system-rebuild-v1`:
  - Card gate: `modifierGroups` / `sizes` count as customizable.  
  - Profile-first + `_groupsForUi()` for structural crust/cook/cut.  
  - **Available toppings/cheeses/sauces** for pizza come from **`optionalAddOns` filtered by `typeId`**, not sparse modifier group options alone.  
  - **Current Toppings** = food on the pie only (included food + user-added meats/veggies). Cheeses and sauces stay in their sections.  
  - **Cheeses / Sauces** = ExpansionTile + Click to Add/Remove + portion (left/right/whole) + Regular/Double; included pre-selected.  
  - Flat Optional add-ons list **hidden** on pizza/calzone.  
  - Order Details owns structural radios; cart payload excludes crust/cook/cut ids from topping lists.

## Locked contract (do not regress)

See `docs/slices/menu-modifier-system-rebuild-v1.md` § "Locked mobile pizza contract". Agents must not:

- Drive pizza available meats/veggies only from empty modifier group options when `optionalAddOns` exists  
- Put cheeses/sauces into Current Toppings  
- Restore SauceSelectorGroup as the primary pizza sauces UI  
- Show the bottom Optional add-ons block on pizza

## Target Architecture
- Single binary; restaurant-type agnostic via `menuProfile` + shared models  
- Decision 10 rebuild; M5 cutover still required for dual-tree removal  

## Implementation Approach
- M1–M4 pizza + optionalAddOns UX — landed  
- Full seed + non-pizza QA — next  
- M5 cutover — after acceptance  

## Success Criteria
- Pizza UX preserved via profile + optionalAddOns/included contract  
- No dual runtime trees after M5  
