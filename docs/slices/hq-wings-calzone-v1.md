# Slice: HQ Wings + Calzone v1

**Status**: In progress — W1–W6 done (code + seed); W7 acceptance open; W2 optional  
**Branch**: `feat/menu-modifier-system-rebuild-v1`  
**Authority**: Decision 10 addendum; STATUS / HANDOFF / MOBILE_DYNAMIC  
**Depends on**: Pizza optionalAddOns contract (locked, CBR PASS)

## Problem

- Wings mobile UI shows empty sauce lists / only "plain"; dual "Dips & sauces" vs "Build your wings" is confusing.
- Free cup counts and extra-cup prices are not owned cleanly by HQ on the item.
- Calzones need pizza-equivalent customization with **no left/right half** and **separate reporting** (`menuProfile: calzone`).

## Locked product rules (do not reopen)

### Wings

| Topic | Decision |
|--------|----------|
| Flavor portions | **Max 2** for every size |
| Size role | Piece count + price + free cups + extra-cup price |
| Plain | No toss sauce on that portion |
| Plain still gets free cups | **Yes** |
| Sauce catalog | Ingredient type **`sauces`** only (no `wing_sauces` type) |
| Sauce pool | **One shared franchise pool**; items **bind** existing ingredients |
| Toss + side cups | **Same** sauce ingredient ids |
| Free cups / extra upcharge | Set in **menu item creation**, per size |
| UI | **Build your wings** (2 portions) + **Dipping sauces** (cup counts only) |
| HQ profile | No included toppings / optional add-ons editors on wings |

### Calzone

| Topic | Decision |
|--------|----------|
| Profile | **`menuProfile: calzone`** (not reuse `pizza` for reporting) |
| Data / UX | Same as pizza (included, optionalAddOns, sizes, crust/cook/cut, cheeses/sauces sections) |
| Difference | **No left/right portion UI** |

## Architecture

### Shared wing sauce pool (franchise + item)

| Layer | Store | Role |
|--------|--------|------|
| Franchise default | `franchises/{id}/config/menu_profile_wings` | `{ sauceIngredientIds: string[], maxFlavorPortions: 2 }` (W2 optional) |
| Item bind | `dippingSauceOptions` + `sideDipSauceOptions` (same list) and/or `modifierGroups` `wing_sauce` / `wing_dips` | Mobile runtime; **HQ save projects group binds → option lists** |
| Catalog | `ingredient_metadata` + type `sauces` | SKUs |

Mobile read order: item option lists → modifier groups → empty (Plain only).

### Free cups + extra cup $ (Phase A)

Use existing `MenuItem` fields (no `SizeData` change required this slice):

- `freeDipCupCount: Map<String, int>` — size label → free cups  
- `sideDipUpcharge: Map<String, double>` — size label → $ per extra cup  
- `dippingSplits: Map<String, int>` — size label → **2**  

Phase B (optional later): `SizeData.freeSideDips` / upcharge fields.

### Existing model support

`MenuItem` already has wings accessors (`getDippingSauceOptions`, `getFreeDipCupCountForSize`, `getSideDipUpchargeForSize`, `getDippingSplitsForSize`).  
`MenuProfileTemplates._wings()` seeds `wing_sauce` + `wing_dips` groups; `MenuProfile.calzone` seeds pizza groups.

## Workstreams

| ID | Name | Status |
|----|------|--------|
| **W0** | Docs lock (this slice + STATUS/HANDOFF/DECISIONS/MOBILE) | **Done** |
| **W1** | shared_core: `MenuProfile.calzone` + template = pizza clone; wings template notes | **Done** |
| **W2** | Franchise `config/menu_profile_wings` read/write + Apply pool | Open (optional; item bind works) |
| **W3** | HQ editor: wings panel (sizes, free cups, upcharge, sauce bind) + calzone profile | **Done** |
| **W4** | Mobile wings UX: 2 portions + Plain + Dipping sauces counts | **Done** |
| **W5** | Mobile calzone = pizza path, hide left/right | **Done** |
| **W6** | Seed sauces + wings item + calzone item | **Done** |
| **W7** | Smoke acceptance | **Open** |

### Suggested build order (executed)

W0 → W1 → W5/W4 → W3 → W6 → **W7** → optional W2 → then **M5** of menu-modifier epic.

## Acceptance

**Wings**
- [ ] Sizes drive free cups + extra upcharge from item maps  
- [ ] Always 2 flavor portions; Plain = no toss  
- [ ] Sauces from item bind; toss list = side-cup list  
- [ ] One **Dipping sauces** section (counts); no dual empty dips taxonomy  
- [ ] Cart/total correct; empty pool does not crash  
- [x] HQ free-cups panel + save projection of bound sauces  
- [x] Mobile sauces list smoke PASS (human)  

**Calzone**
- [ ] `menuProfile: calzone` end-to-end acceptance  
- [x] Profile + pizza path helpers (mobile/web)  
- [x] No left/right half UI (helpers + existing `_isCalzone` gates)  

**Regression**
- [ ] Pizza CBR optionalAddOns contract unchanged  
- [ ] Standard items unchanged  

## Non-goals

- New ingredient type `wing_sauces`  
- More than 2 flavor portions  
- Hard-coded free cup numbers in Dart  
- Merging calzone into `menuProfile: pizza`  
- M5 dual-tree deletion (separate)  
- SizeData schema migration unless explicitly expanded  

## Key files

- `packages/shared_core/lib/src/core/models/menu_item.dart` (existing wings fields)  
- `packages/shared_core/lib/src/core/models/menu_profile_templates.dart`  
- `packages/shared_core/lib/src/core/models/modifier_group.dart` (`MenuProfile.calzone`)  
- `web-app/.../menu_item_editor_sheet.dart`  
- `web-app/.../modifier_groups_ingredient_binder.dart`  
- `mobile_app/lib/widgets/customization/customization_modal.dart`  
- `mobile_app/.../wings_portion_selector.dart` / `wings_dip_sauce_selector.dart`  
- `web-app/lib/widgets/customization/` (web parity)  
