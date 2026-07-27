# STATUS.md — Live Project Snapshot

**Last Updated**: July 27, 2026 (menu-modifier M1–M3 HQ progress)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/menu-modifier-system-rebuild-v1`  
**Main**: includes Admin ops fixes merge + onboarding-4step; Hosting deploy OK (intl 0.19.0)

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 HQ onboarding + Platform Owner MVP complete.**  
**Admin ops P0/P1 complete** (merged to `main`).  
**Active epic:** Menu modifier system rebuild (Decision 10) — **M1–M3 HQ path in progress / largely landed; Admin + mobile open.**

### Completed (locked)

- [x] HQ onboarding sole host (Decision 7); foundation residual
- [x] HQ Design & Branding v1/v1.1; financial honesty; platform billing honesty
- [x] Platform Owner dashboard MVP
- [x] Ingredient type sortOrder uniqueness + ingredients group edit
- [x] `feat/onboarding-4step` → `main`; Hosting (intl 0.19.0)
- [x] Admin exhaustive smoke (July 27)
- [x] **Admin dashboard ops fixes v1** — categories CRUD, promos, orders refund/status, Active Promotions KPI, menu snackbar + remove Import CSV/Columns; merged `main`

### Menu modifier rebuild — progress (July 27 evening)

| Stream | Status |
|--------|--------|
| **M1** Schema (`ModifierGroup` / `ModifierOption` / `MenuProfile` / templates / MenuItem fields + inventory) | **Done** |
| **M2** Read adapter `effectiveMenuProfile` / `effectiveModifierGroups` | **Done** (legacy map in memory) |
| **M3 HQ** Profile-first editor, seed groups, binder, min/max/maxFree, pizza hide base price, inventory save, legacy UI removed | **Done** (HQ write path) |
| **M3 Admin** Same write model; kill Customize spinner | **Open** |
| **M4** Mobile schema renderer | **Open** (needs emulator) |
| **M5** Cutover / delete dual trees | **Open** |

**Data note:** Doughboys `menu_items` collection **wiped** by human for clean re-seed under canonical schema (no forced legacy migrate required).

**Explicit product rule:** One canonical model for pizza **and** other restaurant types. No production `category.contains('pizza')`. Cook/Cut/Crust = label-only modifier options, not ingredient types. Optional customer extras = groups with `min: 0` + pricing rules (not legacy `optionalAddOns` UI).

### Active focus

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | Finish **web** menu rebuild: Admin Menu parity; HQ polish if needed | `docs/slices/menu-modifier-system-rebuild-v1.md` |
| **2** | **M4** mobile after Android Studio/emulator ready | same slice |
| **3** | Developer dashboard inventory | After menu path clear |

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
