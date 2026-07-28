# Architecture Decision Log (DECISIONS.md)

**Last Updated**: July 28, 2026 (Decision 10 addendum — wings pool + calzone profile)

This file records major architectural and design decisions for the Doughboys Pizzeria Franchise Platform.

## Decision Log

### 1. Hybrid Single/Multi-Location Support
**Date**: July 2026  
**Status**: Approved  
**Decision**: Implement hybrid mode where single-location users see simplified UI but retain full management power. Multi-location users see franchise-level tools. Seamless upgrade path.  
**Rationale**: Matches predominant customer base (single owners) while future-proofing for franchises.  
**Impact**: Affects UI, providers, Firestore queries, and dashboards.

### 2. Unified Config System in shared_core + Firestore
**Date**: July 2026  
**Status**: Approved  
**Decision**: Consolidate all config files into `shared_core` as the single source of truth. Franchise-scoped and dynamic via Firestore (`franchises/{franchiseId}/config/*`).  
**Rationale**: Eliminates duplication between web and mobile. Enables self-service branding and white-labeling.  
**Reference**: `/docs/architecture/firestore-per-franchise-config.md`  
**Impact**: Major refactoring completed in P2.5 / Phase 1.

### 3. Design & Branding Management
**Date**: July 2026  
**Status**: Approved (refined by Decision 8)  
**Decision**: Dedicated page in HQ Owner dashboard with live preview. Franchise-scoped in Firestore.  
**Rationale**: Gives owners control while maintaining safety and preview capability.  
**See also**: Decision 8 for v1 / v1.1 delivery.

### 4. Mobile App Dynamic UI
**Date**: July 2026  
**Status**: Approved (execution via Decision 10 rebuild)  
**Decision**: Config-driven UI based on restaurant type / menu profiles, configs, and FeatureGate. One published binary.  
**Rationale**: Supports multiple restaurant types without multiple apps.  
**Impact**: Phase 3; **menu modifier rebuild** is the concrete path (Decision 10). M4 pizza path landed July 28, 2026 on feature branch.

### 5. Multi-Agent Development Approach
**Date**: July 2026  
**Status**: Approved  
**Decision**: Docker + local LLMs on MINISFORUM AI X1 Pro-470 for specialized agents with strict human review.  
**Rationale**: Accelerates development while maintaining quality and control.  
**Impact**: Phase 0 setup; multi-file propose/apply (July 25).

### 6. Dashboard Roles
**Date**: July 2026  
**Status**: Approved  
**Decision**: Four dashboards (Platform Owner, HQ Owner, Admin/Staff, Developer) with clear separation and role switching.  
**Rationale**: Supports different user needs and assisted onboarding.  
**Impact**: Documented in DASHBOARDS.md.

### 7. Onboarding Home = HQ Owner Dashboard (not Admin)
**Date**: July 24, 2026 (approved); **July 25, 2026 migration complete**  
**Status**: **Implemented**  
**Decision**: Franchise/menu onboarding belongs on the **HQ Owner** dashboard, not Admin/Staff.  

**Implemented state (July 25):**
1. HQ copy at `web-app/lib/admin/hq_owner/onboarding/**`
2. Host: `HqOnboardingShellScreen` (sidebar + IndexedStack; in-shell `switchToSection`)
3. Continue onboarding from HQ progress card → HQ shell
4. Deep links: `resolveRoute` → `/hq/onboarding?section=…`
5. Admin onboarding tree **deleted**; `section_registry` ops-only
6. Progress path: `franchises/{id}/onboarding_progress/progress`

**Progress product keys:** `onboarding_feature_setup`, `onboarding_design_branding`, `onboarding_menu_foundation`, `onboardingMenuItems`, `onboardingReview`

**Rationale**: HQ Owners own franchise setup. Admin is day-to-day operations.  
**Reference**: `STATUS.md`, `docs/DASHBOARDS.md`.

### 8. HQ Design & Branding v1 / v1.1
**Date**: July 24, 2026 (v1 locked); **July 25, 2026 v1.1 persistence**  
**Status**: **v1 complete; v1.1 complete**  
**Decision**: Live Branding Preview + Design & Branding screen; Save merges branding keys to franchise + `config/ui_config`.  
**Reference**: `docs/slices/hq-design-branding-v1.md`.

### 9. Admin Menu vs HQ Menu Items (surface split)
**Date**: July 27, 2026  
**Status**: **Approved + M3 Admin write path implemented** (July 28, 2026 feature branch)  
**Decision**:
1. **HQ onboarding Menu Items** = guided, step-by-step franchise self-onboarding (templates, schema repair, foundation gates, publish).
2. **Admin Menu** (`menuEditor`) = day-2 operations for restaurant managers (search, availability, light edits, bulk ops, inventory counts once shipped).
3. Both surfaces **must share one underlying menu + modifier schema** after Decision 10. No permanent dual Customize formats.
4. Staff/Support Chat may remain honest placeholders until wired; not part of onboarding.

**Rationale**: Onboarding and ops audiences differ; data model must not.  
**Impact**: Editor UX depth differs; write path unified under Decision 10. Admin hosts `MenuItemEditorSheet` for canonical items.  
**Reference**: `docs/DASHBOARDS.md`, `docs/slices/admin-dashboard-ops-fixes-v1.md`, `docs/slices/menu-modifier-system-rebuild-v1.md`.

### 10. Menu Modifier System — Full Rebuild (not patch-only)
**Date**: July 27, 2026 (refined same day: catalog vs groups vs items)  
**Status**: **Approved — implementation in progress** (M1–M4 pizza done; wings + calzone planned; M5 open)  
**Decision**:
1. **Rebuild** menu customization end-to-end. Reject dual trees and mobile category-name heuristics as the long-term path.
2. **Canonical runtime model:** enriched modifier groups; options may use **`ingredientId`** or **label-only** for structural choices.
3. **`menuProfile`** (`standard` | `pizza` | `calzone` | `wings` | `drinks` | …): supplies defaults, seeded groups, and advanced widgets. **Not** `category.contains('pizza')`.
4. **Stop dual-writing** Admin `customizations` as a second source of truth. Migrate → single tree; cut over mobile (M5).
5. **Item inventory:** `inventoryTracked` + `stockCount` (+ optional threshold).
6. Workstreams **M1–M5** in `docs/slices/menu-modifier-system-rebuild-v1.md`; **wings + calzone** in `docs/slices/hq-wings-calzone-v1.md`.

**Catalog rules (locked July 27):**

| Concept | Role | Ingredient type? |
|---------|------|------------------|
| Ingredient type + ingredient | Shared kitchen component | **Yes** |
| Modifier option (non-ingredient) | Structural choice (Cook/Cut/Crust) | **No** |
| Menu item | Sellable product | The item |

- Do **not** model Cook / Cut / Crust as ingredient types.
- Shared sauces (pizza + wings): **one** ingredient under type `sauces`.

**Pizza UI contract (locked July 28):**  
Current toppings = food only; optionalAddOns by typeId = available pools; cheeses/sauces stay in sections; Order Details = crust/cook/cut; structural ids never in Current / cart topping lists.

**Wings + calzone addendum (locked July 28):**

1. **`menuProfile: calzone`** — same customization shape as pizza; **no left/right half** UI; separate reporting from pizza.
2. **Wings** — max **2** flavor portions for all sizes; **Plain** = no toss on that portion (still eligible for free side cups).
3. **Wing sauces** — catalog type **`sauces` only**; **franchise shared pool** (`franchises/{id}/config/menu_profile_wings`) + **item bind** (`dippingSauceOptions` / `sideDipSauceOptions` and/or `wing_sauce` / `wing_dips` groups). Toss list and side-cup list are the **same** ids for Doughboys.
4. **Free cups + extra cup upcharge** — set in **menu item creation** per size via existing `freeDipCupCount` and `sideDipUpcharge` maps (Phase A). Optional later: fields on `SizeData`.
5. **HQ** binds existing sauce ingredients (create ingredients in foundation, not a parallel wing-only creator).
6. **Mobile wings UI** — **Build your wings** (2 portions) + **Dipping sauces** (counts); do not keep a confusing dual empty “dips vs sauces” taxonomy.

**Rationale**: Multi-tenant types need one system; wings rules belong in profile + item data, not hard-coded cup counts; calzone needs pizza UX with distinct analytics.  
**Impact**: shared_core profiles/templates, HQ editor, mobile modal, franchise config, seeds.  
**Reference**: `docs/slices/menu-modifier-system-rebuild-v1.md`, `docs/slices/hq-wings-calzone-v1.md`, `docs/MOBILE_DYNAMIC.md`, `STATUS.md`, `HANDOFF.md`.

---

**How to Use This File**:
- Add new decisions with date, status, rationale, impact, and references.
- Review before major refactors.

**Last Updated**: July 28, 2026
