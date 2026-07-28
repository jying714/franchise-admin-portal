# STATUS.md — Live Project Snapshot

**Last Updated**: July 28, 2026 (pizza customization UX locked — optionalAddOns pools)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/menu-modifier-system-rebuild-v1`  
**Main**: includes Admin ops fixes merge + onboarding-4step; Hosting deploy OK

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 HQ onboarding + Platform Owner MVP complete.**  
**Admin ops P0/P1 complete** (merged to `main`).  
**Active epic:** Menu modifier system rebuild (Decision 10) — **M1–M4 pizza path + HQ included/optional + mobile optionalAddOns pools landed; M5 cutover open.**

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

### Menu modifier rebuild — progress (July 28 afternoon)

| Stream | Status |
|--------|--------|
| **M1** Schema | **Done** |
| **M2** Read adapter | **Done** |
| **M3 HQ** Profile-first editor + binder + inventory | **Done** |
| **M3 HQ** Included toppings + optional add-ons UI (persist) | **Done** |
| **M3 Admin** Shared editor sheet | **Done** |
| **M4 Web** Modal bridge | **Done** (pizza path) |
| **M4 Mobile** optionalAddOns-driven pizza customization UX | **Done** (CBR smoke PASS) |
| **M5** Cutover / delete dual trees | **Open** |

### Locked pizza customization UX (do not regress / do not “refactor” away)

**Data sources**

| Field | Role |
|-------|------|
| `includedIngredients` | Defaults that start on the item (food toppings for Current; cheeses/sauces pre-select only) |
| `optionalAddOns` | **Available pool** for pizza, split by `typeId`: meats, veggies, cheeses, sauces |
| `modifierGroups` | Crust/Cook/Cut (structural) + min/max/maxFree rules; group **options** are not the primary available list when optionalAddOns is populated |

**Mobile sections (`CustomizationModal`, pizza profile)**

| Section | Behavior |
|---------|----------|
| **Current Toppings** | Food currently on the pie (meats/veggies/etc. from included + user adds). **Never** cheeses or sauces. Structural ids never appear. |
| **Additional Toppings** | Tabs **Meats \| Veggies** from `optionalAddOns` by typeId, minus ids already in Current. Add → Current. |
| **Cheeses** | All optional cheeses (+ included cheese pre-selected). Stays in Cheeses section only (not Current). Click to Add / Remove + left/right/whole + Regular/Double. Max 2. |
| **Sauces** | Same UX as Cheeses (not radio/clear legacy). Pool = optional sauces ∪ included sauces. Included sauce pre-selected. Stays in Sauces only. |
| **Order Details** | Crust / Cook / Cut only |
| Flat **Optional add-ons** block | **Hidden** on pizza/calzone |

**HQ**

- Editor must expose **Included toppings** and **Optional add-ons** and **persist** them (do not hardcode empty arrays on save).
- Modifier binder remains for structural groups + maxFree rules.

### Active focus

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | Full Doughboys re-seed under this contract | slice |
| **2** | Broader M4 QA (wings / standard / Liberty) | slice |
| **3** | **M5** cutover when acceptance green | slice |
| **4** | Developer dashboard | After menu path clear |

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| Cash Flow Forecast / Multi-Brand HQ cards | Post-MVP |
| Alerts producers / full AlertListScreen | Deferred |
| CF Node 22 | Before ~2026-10-30 |
| Inventory SKU ↔ Inventory collection | Phase B |
| Combos / bundles | Deferred |
| HQ size templates locked by profile (price-only) | Discussed; not built |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`.

---

**Update this file after significant sessions.**
