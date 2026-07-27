# Architecture Decision Log (DECISIONS.md)

**Last Updated**: July 27, 2026 (Decisions 9–10 — Admin Menu surfaces + menu modifier rebuild)

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
**Impact**: Phase 3; **menu modifier rebuild** is the concrete path (Decision 10).

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
**Status**: **Approved**  
**Decision**:
1. **HQ onboarding Menu Items** = guided, step-by-step franchise self-onboarding (templates, schema repair, foundation gates, publish).
2. **Admin Menu** (`menuEditor`) = day-2 operations for restaurant managers (search, availability, light edits, bulk ops, inventory counts once shipped).
3. Both surfaces **must share one underlying menu + modifier schema** after Decision 10. No permanent dual Customize formats.
4. Staff/Support Chat may remain honest placeholders until wired; not part of onboarding.

**Rationale**: Onboarding and ops audiences differ; data model must not.  
**Impact**: Editor UX depth differs; write path unified under Decision 10.  
**Reference**: `docs/DASHBOARDS.md`, `docs/slices/admin-dashboard-ops-fixes-v1.md`.

### 10. Menu Modifier System — Full Rebuild (not patch-only)
**Date**: July 27, 2026  
**Status**: **Approved — implementation pending**  
**Decision**:
1. **Rebuild** menu customization end-to-end. Reject “barely held together” MVP patches that leave dual trees and mobile category-name heuristics.
2. **Canonical runtime model:** enriched modifier groups (evolve `customizationGroups`) with `selectMode`, min/max/maxFree, portion/double flags, options preferring `ingredientId`; optional free-text ad-hoc options as escape hatch.
3. **`menuProfile`** (`standard` | `pizza` | `wings` | `drinks` | …): supplies defaults and advanced widgets. Doughboys requires **pizza** UX (half toppings, doubles cap, sauce split) as profile behavior—not `category.contains('pizza')` in mobile.
4. **Stop dual-writing** Admin `customizations: List<Customization>` as a second source of truth vs groups. Migrate → single tree; cut over mobile to schema-driven renderer.
5. **Item inventory:** `inventoryTracked` + `stockCount` (+ optional threshold) on menu items for count-tracked products (wings, breadsticks, etc.). Ingredient OOS remains for toppings. SKU ↔ Inventory collection = later phase.
6. Workstreams **M1–M5** in `docs/slices/menu-modifier-system-rebuild-v1.md`. Acceptance includes Doughboys order parity before removing legacy path.

**Rationale**: Multi-tenant restaurant types + live Doughboys MVP testing require one robust system; patching increases long-term debt and live clunkiness.  
**Impact**: shared_core models, HQ + Admin editors, mobile `CustomizationModal`, Firestore menu docs, seeds.  
**Reference**: `docs/slices/menu-modifier-system-rebuild-v1.md`, `docs/MOBILE_DYNAMIC.md`.

---

**How to Use This File**:
- Add new decisions with date, status, rationale, impact, and references.
- Review before major refactors.

**Last Updated**: July 27, 2026
