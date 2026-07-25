# Architecture Decision Log (DECISIONS.md)

**Last Updated**: July 25, 2026 (Decision 7 migration complete; Decision 8 v1.1 persistence)

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
**Status**: Approved  
**Decision**: Config-driven UI based on `restaurantType`, configs, and FeatureGate. One published binary.  
**Rationale**: Supports multiple restaurant types without multiple apps.  
**Impact**: Phase 3 focus.

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
3. Continue onboarding from HQ progress card → HQ shell (`initialSectionKey: onboardingMenu`)
4. Deep links: `resolveRoute` → `/hq/onboarding?section=…`; main.dart registers HQ shell before generic `hq` match
5. Admin onboarding tree **deleted**; `section_registry` has **no** onboarding sections; Admin sidebar ops-only
6. Progress card: four product steps; path `franchises/{id}/onboarding_progress/progress`

**Progress key rules (locked July 25):**
- Product keys: `onboarding_feature_setup`, `onboarding_menu_foundation`, `onboardingMenuItems`, `onboardingReview`
- Foundation sub-keys (`ingredientTypes` / `ingredients` / `categories`) → detail % only; step 2 only via foundation continue / explicit foundation complete
- Summary table “Complete” = validation (zero critical issues); `onboardingReview` only on successful Publish
- Review UX direction: remove summary Action/Fix Now; expansion Fix = section-only in-shell navigation

**Rationale**: HQ Owners own franchise setup. Admin is day-to-day operations.  
**Impact**: Navigation, registry, dashboard composition; no new onboarding schema.  
**Reference**: `STATUS.md`, `docs/DASHBOARDS.md`, `web-app/README.md`.

### 8. HQ Design & Branding v1 / v1.1
**Date**: July 24, 2026 (v1 locked); **July 25, 2026 v1.1 persistence**  
**Status**: **v1 complete; v1.1 complete**  
**Decision**:
1. Live Branding Preview card on Owner HQ + **Open Design & Branding** → dedicated screen
2. v1: local draft; Save snackbar only; logo Image + fallback
3. v1.1: Save merges primary/secondary hex, appName, logoUrl to `franchises/{id}` + `config/ui_config`; then `setBrandingFromFranchiseDoc`
4. Screen-owned Firestore writes for now; port to Admin/FirestoreService when the editor expands
5. No section_registry for HQ entry; no new BrandingConfig/DesignTokens fields for this slice

**Rationale**: Delivers Decision 3 without inventing schema. Persistence uses existing franchise branding keys.  
**Reference**: `docs/slices/hq-design-branding-v1.md`, `STATUS.md`.

---

**How to Use This File**:
- Add new decisions with date, status, rationale, impact, and references.
- Reference this file in ARCHITECTURE.md when appropriate.
- Review before major refactors.

**Last Updated**: July 25, 2026
