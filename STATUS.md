# STATUS.md — Live Project Snapshot

**Last Updated**: July 28, 2026 (wings + calzone plan locked — W0 docs)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/menu-modifier-system-rebuild-v1`  
**Main**: includes Admin ops fixes merge + onboarding-4step; Hosting deploy OK

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 HQ onboarding + Platform Owner MVP complete.**  
**Admin ops P0/P1 complete** (merged to `main`).  
**Active epic:** Menu modifier system rebuild (Decision 10) — **M1–M4 pizza path done; wings + calzone v1 planned (W0); M5 cutover still open.**

### Completed (locked)

- [x] HQ onboarding sole host (Decision 7); foundation residual
- [x] HQ Design & Branding v1/v1.1; financial honesty; platform billing honesty
- [x] Platform Owner dashboard MVP
- [x] Ingredient type sortOrder uniqueness + ingredients group edit
- [x] `feat/onboarding-4step` → `main`; Hosting
- [x] Admin exhaustive smoke (July 27)
- [x] **Admin dashboard ops fixes v1** — merged `main`
- [x] **M1–M3 HQ + M3 Admin + M4 pizza path** (modifier groups, Customize gate, structural Order Details)
- [x] **HQ included toppings + optional add-ons editor** (`menu_item_editor_sheet` + persist on save)
- [x] **Mobile pizza pools from `optionalAddOns` by typeId** (meats/veggies/cheeses/sauces); cheeses/sauces section UX parity; human-verified PASS
- [x] Doughboys foundation seed (categories, ingredient_types, ingredient_metadata, menu_items) — human verified complete
- [x] **W0** Wings + calzone product/plan locked in docs

### Menu modifier rebuild — progress

| Stream | Status |
|--------|--------|
| **M1** Schema | **Done** |
| **M2** Read adapter | **Done** |
| **M3 HQ** Profile-first editor + binder + inventory + included/optional | **Done** |
| **M3 Admin** Shared editor sheet | **Done** |
| **M4 Web** Modal bridge | **Done** (pizza path) |
| **M4 Mobile** optionalAddOns-driven pizza customization UX | **Done** (CBR smoke PASS) |
| **Wings + Calzone v1** | **Planned** — see `docs/slices/hq-wings-calzone-v1.md` |
| **M5** Cutover / delete dual trees | **Open** (after wings/calzone acceptance preferred) |

### Locked pizza customization UX (do not regress)

| Field | Role |
|-------|------|
| `includedIngredients` | Defaults (food → Current; cheeses/sauces → section pre-select only) |
| `optionalAddOns` | Available pool by `typeId`: meats, veggies, cheeses, sauces |
| `modifierGroups` | Crust/Cook/Cut + min/max/maxFree; not primary available list when optionalAddOns set |

| Section | Behavior |
|---------|----------|
| Current Toppings | Food only; never cheeses/sauces/structural |
| Additional | Meats \| Veggies from optionalAddOns minus Current |
| Cheeses / Sauces | Section-only Add/Remove + portion + double |
| Order Details | Crust / Cook / Cut |
| Flat Optional add-ons | Hidden on pizza/calzone |

### Locked wings + calzone (do not regress once implemented)

**Wings:** max 2 flavor portions; Plain = no toss; free cups still apply; sauces from type `sauces`; franchise shared pool + item bind; toss list = side-cup list; free cups + extra upcharge set per size on **menu item** (`freeDipCupCount` / `sideDipUpcharge`); UI = Build your wings + Dipping sauces only.

**Calzone:** `menuProfile: calzone`; pizza-equivalent data/UX; **no left/right half** UI.

Authority: `docs/slices/hq-wings-calzone-v1.md`.

### Active focus

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | Wings + calzone v1 (W1–W7) | `docs/slices/hq-wings-calzone-v1.md` |
| **2** | Pizza regression smoke while wings lands | pizza contract above |
| **3** | **M5** cutover when menu profiles acceptance green | menu-modifier slice |
| **4** | Developer dashboard | After menu path clear |

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| Cash Flow Forecast / Multi-Brand HQ cards | Post-MVP |
| Alerts producers / full AlertListScreen | Deferred |
| CF Node 22 | Before ~2026-10-30 |
| Inventory SKU ↔ Inventory collection | Phase B |
| Combos / bundles | Deferred |
| SizeData.freeSideDips migration (Phase B) | Optional after wings Phase A |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`.

---

**Update this file after significant sessions.**
