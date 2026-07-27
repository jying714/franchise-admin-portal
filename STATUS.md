# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (night — HQ onboarding foundation residual + Platform Owner MVP)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 – Core Config Scoping & Dynamic Branding + HQ / Platform Owner surfaces**

### Completed (recent)

- [x] Menu Items v1; live HQ branding on franchise switch; branding notify + picker guard
- [x] **Single** web `FranchiseProvider` at app root
- [x] Design & Branding screen v1/v1.1
- [x] **Polish W1–W6 COMPLETE** — `docs/slices/hq-onboarding-hq-polish-v1.md`
- [x] **HQ Financial Honesty v1 COMPLETE** — `docs/slices/hq-financial-honesty-v1.md`
- [x] **HQ Platform Billing v1 COMPLETE** — `docs/slices/hq-platform-billing-v1.md`
- [x] **HQ Alerts card UI honesty (card-only)** — filter, Retry, no dead See all; no producers
- [x] **Platform Owner dashboard MVP COMPLETE** — `docs/slices/platform-owner-dashboard-v1.md`
- [x] **HQ onboarding foundation residual (orphan gate + Unassigned grouping)** — `docs/slices/hq-onboarding-foundation-residual-v1.md`
  - Menu Items **hard block** until orphan count = 0
  - Orphan = empty `typeId` **or** `typeId` not in live franchise ingredient types
  - CTA “Open Core Menu Foundation” → Ingredients tab + orphan filter + first-highlight handoff (`FoundationFocusRequest`)
  - Ingredients list: group by **canonical franchise type name** only; **Unassigned** section at top + tooltip of discrepancies
  - Unique list keys (`id#index`) — fixes Flutter “Duplicate keys found” on Doughboys data
  - Ingredient form: save uses `saveChanges()` (no mid-dialog `load()`); dialog pop via `dialogContext` / nearest navigator; type seed once
  - Shell: `ChangeNotifierProvider` + `ProxyProvider` for ingredient type/metadata Impl so Menu Items readiness rebuilds live

### Active focus (human-chosen next)

1. **Admin dashboard** — inventory / cleanup / real vs stub cards  
2. **Developer dashboard** — same  
3. **HQ residual polish** — ingredient form dismiss reliability if still flaky; Doughboys data cleanup (103→0 orphans); optional bulk type-map

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| **Cash Flow Forecast** (HQ) | **Post-MVP** |
| **Multi-Brand Overview** (HQ) | **Post-MVP** |
| **Payouts** (HQ product card) | In-dev shell |
| **Alerts producers / AlertListScreen** | Deferred |
| **Mobile app restaurant-type agnostic QA** | Deferred discussion — pizzeria-first history |
| **Cloud Functions Node 22** | Node **20** live; 20 decommissions ~2026-10-30 |
| **Franchise-scoped invoice rollup in Platform revenue** | Optional — top-level `platform_invoices` only today |
| **Bulk “map type X → Y” for orphans** | Not in residual v1; hand-edit + filter is the path |

**Product key order (onboarding):**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`; progress is load+write (not a stream); HQ + Platform Owner financial/admin reads on **AdminFirestoreService**; Menu Items foundation readiness watches **Impl** ChangeNotifiers (not inert `Provider.value` alone).

**Known residual (non-blocking):** franchise-switch onboarding progress lag; Liberty `ingredientId` type noise; device re-smoke `mobile_ordering`; Payouts shell; CF Node 22; mobile multi-type layout QA; ingredient form dismiss may still need one more navigator pass on some hosts; Doughboys production data still has many historical orphans until repaired in UI/Console.

---

**Update this file after significant sessions.**
