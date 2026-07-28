# STATUS.md — Live Project Snapshot

**Last Updated**: July 28, 2026 (menu-modifier M3 Admin + M4 pizza path)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/menu-modifier-system-rebuild-v1`  
**Main**: includes Admin ops fixes merge + onboarding-4step; Hosting deploy OK (intl 0.19.0)

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 HQ onboarding + Platform Owner MVP complete.**  
**Admin ops P0/P1 complete** (merged to `main`).  
**Active epic:** Menu modifier system rebuild (Decision 10) — **M1–M3 HQ + M3 Admin + M4 pizza path landed on feature branch; M5 cutover open.**

### Completed (locked)

- [x] HQ onboarding sole host (Decision 7); foundation residual
- [x] HQ Design & Branding v1/v1.1; financial honesty; platform billing honesty
- [x] Platform Owner dashboard MVP
- [x] Ingredient type sortOrder uniqueness + ingredients group edit
- [x] `feat/onboarding-4step` → `main`; Hosting (intl 0.19.0)
- [x] Admin exhaustive smoke (July 27)
- [x] **Admin dashboard ops fixes v1** — categories CRUD, promos, orders refund/status, Active Promotions KPI, menu snackbar + remove Import CSV/Columns; merged `main`

### Menu modifier rebuild — progress (July 28 ~00:50 CDT)

| Stream | Status |
|--------|--------|
| **M1** Schema (`modifierGroup` / `modifierOption` / `MenuProfile` / templates / MenuItem fields + inventory) | **Done** |
| **M2** Read adapter `effectiveMenuProfile` / `effectiveModifierGroups` | **Done** (legacy map in memory) |
| **M3 HQ** Profile-first editor, seed groups, binder, min/max/maxFree, pizza hide base price, inventory save, legacy UI removed | **Done** |
| **M3 Admin** Same write model via `MenuItemEditorSheet`; list loads canonical items; save/sort/id; no dual Customize path for write | **Done** |
| **M4 Web** Customization modal bridge (`_groupsForUi`, profile, maxFree, min/max, size label keys, optionLabels) | **Done** (pizza path) |
| **M4 Mobile** Card gate + modal groups bridge + pricing + cart payload cleanup + UX polish | **Done** (pizza path; S25 smoke green for Customize → Order Details → cart) |
| **M5** Cutover / delete dual production trees + STATUS complete flag | **Open** |

**Data note:** Doughboys `menu_items` were **wiped** for clean re-seed. Partial HQ re-seed exists (e.g. Chicken Bacon Ranch with `menuProfile: pizza` + crust/cook/cut/meats/cheeses). Catalog cleared of Cook/Cut/Crust ingredient types. Full parity seed (included toppings, sauces group, veggie options, shared BBQ) still recommended before M5.

**Explicit product rules (do not regress):**

- One canonical model for pizza **and** other restaurant types.
- No production `category.contains('pizza')` for behavior (profile-first; category only as soft fallback).
- Cook/Cut/Crust = **label-only** modifier options, not ingredient types.
- Optional customer extras = groups with `min: 0` + max/maxFree + size topping upcharge (web sets rules; mobile enforces).
- **Current toppings** = included/food toppings only; **Order Details** = structural radios; structural ids must not appear in Current toppings UI or cart `currentIngredients`.

### Active focus

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | Richer Doughboys re-seed (included toppings, sauces, veggies) + acceptance matrix | `docs/slices/menu-modifier-system-rebuild-v1.md` |
| **2** | Broader M4 QA (wings / standard / salad / drinks regression) | same slice |
| **3** | **M5** cutover when acceptance green; then merge | same slice |
| **4** | Developer dashboard inventory | After menu path clear |

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| Cash Flow Forecast / Multi-Brand HQ cards | Post-MVP |
| Alerts producers / full AlertListScreen | Deferred |
| CF Node 22 | Before ~2026-10-30 (Node 20 live) |
| Inventory SKU ↔ `Inventory` collection | Phase B after item-level stock |
| Combos / bundles | Deferred |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`.

---

**Update this file after significant sessions.**
