# Phase 1: Core Config Scoping & Dynamic Branding

**Status**: Not Started  
**Estimated Duration**: 3–5 days  
**Owner**: Human (with agent support)

## Goals
Make shared_core configs fully franchise-scoped and dynamic, with runtime theming/branding support.

## Acceptance Criteria
- All config files (`design_tokens`, `app_config`, `branding_config`, `feature_config`, `ui_config`) updated to be franchise-scoped in Firestore.
- All config files moved to shared_core and consumed by both web and mobile.
- Runtime theming/branding system implemented with live preview in owner_hq dashboard.
- Design & Branding page with live preview functional.
- Hybrid localization strategy (hardcoded base + DB overrides) documented and partially implemented.
- Full human review on architecture decisions and testing on real devices.

## Defensive Items
- Schema migration plan for existing data documented.
- No breaking changes to mobile app without thorough testing.
- Human approval required for all config schema and Firestore structure decisions.

## Key Tasks
1. Audit current config files in shared_core.
2. Design and implement franchise-scoped config structure in Firestore.
3. Update providers and services to load configs dynamically.
4. Implement runtime theming/branding system.
5. Build Design & Branding page in HQ Owner dashboard with live preview.
6. Document and begin hybrid localization strategy.
7. Run integration tests on web and mobile.
8. Full human review and approval before phase completion.

## Human Involvement Required
- Approve final config schema and Firestore structure.
- Review Design & Branding page UI/UX.
- Sign off on Phase 1 completion before moving to Phase 2.

## Risks
- Firestore migration complexity for existing data.
- Theming inconsistencies between web and mobile.
- Scope creep into Phase 2 (hybrid location logic).

**Approval Required to Exit Phase**: Human sign-off after successful review and testing.