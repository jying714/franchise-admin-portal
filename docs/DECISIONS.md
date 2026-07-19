# Architecture Decision Log (DECISIONS.md)

**Last Updated**: July 19, 2026

This file records major architectural and design decisions for the Doughboys Pizzeria Franchise Platform.

## Decision Log

### 1. Hybrid Single/Multi-Location Support
**Date**: July 2026  
**Status**: Approved  
**Decision**: Implement hybrid mode where single-location users see simplified UI but retain full management power. Multi-location users see franchise-level tools. Seamless upgrade path.  
**Rationale**: Matches predominant customer base (single owners) while future-proofing for franchises.  
**Impact**: Affects UI, providers, Firestore queries, and dashboards.

### 2. Dynamic Config System in shared_core
**Date**: July 2026  
**Status**: Approved  
**Decision**: Consolidate all config files (`design_tokens.dart`, `app_config.dart`, `branding_config.dart`, `feature_config.dart`, `ui_config.dart`) into `shared_core` as the single source of truth. Runtime dynamic theming and UI.  
**Rationale**: Eliminates duplication between web and mobile. Enables self-service branding.  
**Impact**: Major refactoring in Phase 1.

### 3. Design & Branding Management
**Date**: July 2026  
**Status**: Approved  
**Decision**: Dedicated page in HQ Owner dashboard with live preview simulator. Franchise-scoped in Firestore. Warning for non-developer users.  
**Rationale**: Gives owners control while maintaining safety and preview capability.  
**Impact**: New feature in Phase 2.

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

---

**How to Use This File**:
- Add new decisions with date, status, rationale, and impact.
- Reference this file in ARCHITECTURE.md when appropriate.
- Review before major refactors.

**Last Updated**: July 19, 2026