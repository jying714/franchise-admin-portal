# STATUS.md — Live Project Snapshot

**Last Updated**: July 27, 2026 (Admin smoke + menu modifier rebuild direction)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `main` (feat/onboarding-4step merged July 27, 2026)

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 complete for HQ onboarding + Platform Owner MVP.**  
**Active development:** Admin ops reliability + **Menu modifier system rebuild** (not patch-only).

### Completed (locked)

- [x] HQ onboarding sole host (Decision 7); foundation residual (orphan gate, Unassigned)
- [x] HQ Design & Branding v1/v1.1; financial honesty; platform billing card honesty
- [x] Platform Owner dashboard MVP
- [x] Ingredient type sortOrder uniqueness + ingredients group edit (pushed pre-merge)
- [x] `feat/onboarding-4step` → `main` fast-forward; Hosting deploy (intl 0.19.0 pin for Flutter 3.29.2)
- [x] Admin dashboard **exhaustive smoke** (July 27) — results drive ops-fixes slice

### Active focus (human-chosen)

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | **Menu modifier system rebuild** — full rebuild, not MVP band-aids | `docs/slices/menu-modifier-system-rebuild-v1.md`, Decision 10 |
| **2** | **Admin dashboard ops fixes** — P0 broken CRUD / franchise refresh / honesty only | `docs/slices/admin-dashboard-ops-fixes-v1.md` |
| **3** | Developer dashboard inventory | After Admin ops + menu path clear |

**Explicit product rule (July 27):** Menu customization must work for **Doughboys pizza UX** (halves, doubles, sauce split) **and** any other restaurant type. Do **not** ship “barely held together” dual write paths (`customizationGroups` vs `customizations[]` vs category-name heuristics). Prefer a complete robust rebuild over temporary MVP patches that increase post-launch debt.

### Admin smoke — high-signal failures (July 27)

| Area | Result |
|------|--------|
| Categories **add** | Dialog closes; **does not persist** |
| Categories **delete / bulk delete** | Broken / bulk no-op |
| Categories sort name/description | Broken — remove; keep asc toggle if fixed |
| Promos add/edit/delete | **FAIL** |
| Orders ⋮ status/refund | Menu does not function |
| Orders franchise switch | Stale until multi-switch |
| Menu ⋮ Customize | **Endless spinner** |
| Menu delete snackbar | Stuck until Undo |
| Menu dietary/allergens / inventory on item | Missing in editor |
| Staff / Support Chat sidebar | Honest **placeholders** (real screens not registered) |
| Home Active Promotions KPI | Stub `"--"` / loading — **wire** |
| Import CSV (menu) / category bulk upload | Remove for MVP noise |

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| Cash Flow Forecast / Multi-Brand HQ cards | Post-MVP |
| Alerts producers / full AlertListScreen | Deferred |
| CF Node 22 | Before ~2026-10-30 (Node 20 live) |
| Inventory SKU ↔ `Inventory` collection link | Phase B after item-level stock |
| Combos / bundles | Deferred |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`; HQ + Platform financials on AdminFirestoreService.

---

**Update this file after significant sessions.**
