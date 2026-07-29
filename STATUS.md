# STATUS.md — Live Project Snapshot

**Last Updated**: July 28, 2026 (~22:40 CDT — developer-dashboard-v1 COMPLETE on feature branch)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/developer-dashboard-v1`  
**Main**: includes menu-modifier M1–M5, wings/calzone W0–W7+W2, Hosting deploy on push

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 HQ onboarding + Platform Owner MVP complete.**  
**Admin ops P0/P1 complete** (on `main`).  
**Menu modifier system rebuild (Decision 10)** — **M1–M5 complete; wings + calzone W0–W7 + W2 complete on `main`.**  
**Developer Dashboard v1** — **COMPLETE** on `feat/developer-dashboard-v1` (merge to `main` is human gate).

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
- [x] **W2** franchise `config/menu_profile_wings` (HQ save/apply + mobile fallback)
- [x] Deferred **order-experience** feedback prompt (`pending_order_experience_feedback` → MainMenu when due)
- [x] `feat/menu-modifier-system-rebuild-v1` → `main`
- [x] **Developer Dashboard v1** — Error Logs Franchise\|Global; Impersonation Phase A; feature toggles franchise write / global read; Schema Browser; Audit Trail; Plugin stub; Dangerous label

### Developer Dashboard v1 — progress

| Stream | Status |
|--------|--------|
| **D0** Docs lock | **Done** |
| **D1** Inventory sections | **Done** |
| **D2** FranchiseId hygiene | **Done** |
| **D3** Error Logs unified + Franchise\|Global | **Done** |
| **D4** Impersonation Phase A (UI preview + banner) | **Done** |
| **D5** Feature toggles franchise write / global read | **Done** |
| **D6** Schema Browser functional | **Done** |
| **D7** Audit Trail functional | **Done** |
| **D8** Plugin Registry stub | **Done** |
| **D9** Relabel Dev Tools → Dangerous | **Done** |
| **D10** Acceptance + docs close | **Done** |

Authority: **`docs/slices/developer-dashboard-v1.md`**.

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

**Wings:** max 2 flavor portions; Plain = no toss; free cups still apply; sauces from type `sauces`; item bind via `modifierGroups` (`wing_sauce` / `wing_dips`) projected to `dippingSauceOptions` / `sideDipSauceOptions` on save; toss list = side-cup list; free cups + extra upcharge set per size on **menu item** (`freeDipCupCount` / `sideDipUpcharge`); UI = Build your wings + Dipping sauces only (no included/optional toppings on wings profile; no Order Details). **W2:** franchise pool at `franchises/{id}/config/menu_profile_wings`; mobile read order item lists → groups → franchise pool → empty.

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
| **1** | Merge `feat/developer-dashboard-v1` → `main` after final human smoke | Human gate |
| **2** | Admin residual / Developer optional residuals (shared franchise helper, fold dual error screens, Overview honesty) | Explicit human task |
| **3** | Next product epic (TBD with human) | STATUS / HANDOFF |

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
| Order-experience prompt trigger post-delivery | Post-MVP (storage + MainMenu due check already landed) |
| Impersonation real claim/token (Phase B) | Future slice after Developer v1 |
| Global feature toggle writes / killswitches | Out of Developer v1 |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`.

---

**Update this file after significant sessions.**
