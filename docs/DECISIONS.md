# Architecture Decision Log (DECISIONS.md)

**Last Updated**: July 24, 2026

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
**Decision**: Consolidate all config files (`design_tokens.dart`, `app_config.dart`, `branding_config.dart`, `feature_config.dart`, `ui_config.dart`) into `shared_core` as the single source of truth. Make them fully franchise-scoped and dynamic via Firestore (`franchises/{franchiseId}/config/*`).  
**Rationale**: Eliminates duplication between web and mobile. Enables self-service branding and white-labeling.  
**Reference**: `/docs/architecture/firestore-per-franchise-config.md` (authoritative schema)  
**Impact**: Major refactoring completed in P2.5 / Phase 1.

### 3. Design & Branding Management
**Date**: July 2026  
**Status**: Approved  
**Decision**: Dedicated page in HQ Owner dashboard with live preview simulator. Franchise-scoped in Firestore. Warning for non-developer users.  
**Rationale**: Gives owners control while maintaining safety and preview capability.  
**Impact**: New feature in Phase 1/2.

### 4. Mobile App Dynamic UI
**Date**: July 2026  
**Status**: Approved  
**Decision**: Transition from pizzeria-hardcoded to fully config-driven UI based on `restaurantType`, configs, and FeatureGate. One published binary.  
**Rationale**: Supports multiple restaurant types without multiple apps.  
**Impact**: Phase 3 focus.

### 5. Multi-Agent Development Approach
**Date**: July 2026  
**Status**: Approved  
**Decision**: Use Docker + local LLMs on MINISFORUM AI X1 Pro-470 for parallel specialized agents with strict human review.  
**Rationale**: Accelerates development while maintaining quality and control.  
**Impact**: Phase 0 setup.

### 6. Dashboard Roles
**Date**: July 2026  
**Status**: Approved  
**Decision**: Four dashboards (Platform Owner, HQ Owner, Admin/Staff, Developer) with clear separation of concerns and role switching.  
**Rationale**: Supports different user needs and assisted onboarding.  
**Impact**: Documented in DASHBOARDS.md.

### 7. Onboarding Home = HQ Owner Dashboard (not Admin)
**Date**: July 24, 2026  
**Status**: Approved (migration pending)  
**Decision**: Franchise/menu onboarding steps (categories, ingredients, menu items, feature setup, review/publish) belong on the **HQ Owner** dashboard (`OwnerHQDashboardScreen` / `web-app/lib/admin/hq_owner/`), not the Admin/Staff dashboard.  
**Current state**: Onboarding UI still lives under `web-app/lib/admin/dashboard/onboarding/` and is launched from the Admin dashboard.  
**Target state**:
1. Add a conditional Onboarding progress tile/card on `OwnerHQDashboardScreen` (visible while onboarding incomplete; uses existing `OnboardingProgressProvider`).
2. Tile navigates into the existing onboarding screens (reuse, do not rewrite step UIs).
3. After HQ entry works, demote or remove the Admin primary entry point.
4. Update STATUS.md, DASHBOARDS.md, web-app/README.md when migration lands.  
**Rationale**: HQ Owners own franchise setup (menu foundation, branding, features). Admin/Staff dashboards are for day-to-day operations, not initial franchise configuration.  
**Impact**: Navigation, section registry, dashboard home composition; no new onboarding schema. Small surgical steps preferred.  
**Reference**: `docs/DASHBOARDS.md`, `STATUS.md`, `tasks/Phase1.md`.

---

**How to Use This File**:
- Add new decisions with date, status, rationale, impact, and references.
- Reference this file in ARCHITECTURE.md when appropriate.
- Review before major refactors.

**Last Updated**: July 24, 2026
