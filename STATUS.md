# STATUS.md — Live Project Snapshot

**Last Updated**: July 28, 2026 (~18:05 CDT — M5 dual-tree cutover complete; canonical menuProfile/modifierGroups only)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/menu-modifier-system-rebuild-v1`  
**Main**: includes Admin ops fixes merge + onboarding-4step; Hosting deploy OK

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 HQ onboarding + Platform Owner MVP complete.**  
**Admin ops P0/P1 complete** (merged to `main`).  
**Active epic:** Menu modifier system rebuild (Decision 10) — **M1–M5 complete; wings + calzone W0–W7 done; optional W2 open.**

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
- [x] **W0–W7** Wings + calzone v1 (docs, shared_core, HQ, mobile/web, seed, acceptance) — human PASS
- [x] Pizza Order Details: template Crust/Cook/Cut fallback when stored groups omit structural options
- [x] Pizza/calzone: hide non-cheese checkbox “Add-ons”; flat optional add-ons hidden
- [x] Mobile salad/dinner: no Order Details; optional ingredients only when `optionalAddOns` set
- [x] Salad optional ↔ Current Toppings (Click to Add pool; included not double-listed; banner parity)
- [x] Pricing: included ingredients never add to base (only doubles / true extras charge)
- [x] **M5 dual-tree cutover** — canonical-only write/read; legacy adapter removed; dual Admin Customize UI deleted; data reseeded; smoke green

### Menu modifier rebuild — progress

| Stream | Status |
|--------|--------|
| **M1** Schema | **Done** |
| **M2** Read adapter | **Done** |
| **M3 HQ** Profile-first editor + binder + inventory + included/optional | **Done** |
| **M3 Admin** Shared editor sheet | **Done** |
| **M4 Web** Modal bridge | **Done** (pizza path) |
| **M4 Mobile** optionalAddOns-driven pizza customization UX | **Done** (CBR smoke PASS) |
| **W1** MenuProfile.calzone + templates | **Done** |
| **W2** Franchise sauce pool | **Open** (optional; item bind + save projection works without it) |
| **W3** HQ wings panel (free cups / upcharge / sauce bind / layout) | **Done** |
| **W4** Mobile wings UX (2 portions + Plain + single Dipping sauces) | **Done** |
| **W5** Mobile/web calzone = pizza path, no left/right | **Done** |
| **W6** Seed wings + calzone items | **Done** |
| **W7** Full acceptance smoke | **Done** (human PASS July 28) |
| **M5** Cutover / delete dual trees | **Done** (July 28 — canonical write/read; legacy adapter + dual Admin Customize paths removed; data reseeded) |

### Locked pizza customization UX (do not regress)

| Field | Role |
|-------|------|
| `includedIngredients` | Defaults (food → Current; cheeses/sauces → section pre-select only); **in base price — never auto-upcharge** |
| `optionalAddOns` | Available pool by `typeId`: meats, veggies, cheeses, sauces |
| `modifierGroups` | Crust/Cook/Cut + min/max/maxFree; not primary available list when optionalAddOns set |

| Section | Behavior |
|---------|----------|
| Current Toppings | Food only; never cheeses/sauces/structural |
| Additional | Meats \| Veggies from optionalAddOns minus Current |
| Cheeses / Sauces | Section-only Add/Remove + portion + double |
| Order Details | Crust / Cook / Cut (template fallback if stored groups omit them) |
| Flat Optional add-ons | Hidden on pizza/calzone |

### Locked wings + calzone (do not regress)

**Wings:** max 2 flavor portions; Plain = no toss; free cups still apply; sauces from type `sauces`; item bind via `modifierGroups` (`wing_sauce` / `wing_dips`) projected to `dippingSauceOptions` / `sideDipSauceOptions` on save; toss list = side-cup list; free cups + extra upcharge set per size on **menu item** (`freeDipCupCount` / `sideDipUpcharge`); UI = Build your wings + Dipping sauces only (no included/optional toppings on wings profile; no Order Details).

**Calzone:** `menuProfile: calzone`; pizza-equivalent data/UX (Current / Additional / Cheeses / Sauces); **no left/right half** UI; no Order Details required for calzone product path.

### Locked standard / salad / dinner mobile (July 28)

| Profile / category | Behavior |
|--------------------|----------|
| **Salad** | No Order Details; no left/right on Current; no checkbox Add-ons group; optional pool = optionalAddOns ∪ removed included; Click to Add → Current; pricing via ingredient/item upcharge |
| **Dinner** | No Order Details; optional ingredients only if HQ set `optionalAddOns` |
| **HQ** | Use `menuProfile: standard` + Optional add-ons editor — **no new salad/dinner profile required** |

Authority: `docs/slices/hq-wings-calzone-v1.md`, `docs/MOBILE_DYNAMIC.md`.

### Active focus

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | Optional **W2** franchise shared sauce pool | `docs/slices/hq-wings-calzone-v1.md` |
| **2** | Developer dashboard | Menu path clear on feature branch |
| **3** | Merge `feat/menu-modifier-system-rebuild-v1` → `main` when ready for Hosting | Human gate |

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| Cash Flow Forecast / Multi-Brand HQ cards | Post-MVP |
| Alerts producers / full AlertListScreen | Deferred |
| CF Node 22 | Before ~2026-10-30 |
| Inventory SKU ↔ Inventory collection | Phase B |
| Combos / bundles | Deferred |
| SizeData.freeSideDips migration (Phase B) | Optional after wings Phase A |
| Salad/dinner dedicated MenuProfile | Not required; standard + optionalAddOns sufficient |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`.

---

**Update this file after significant sessions.**
