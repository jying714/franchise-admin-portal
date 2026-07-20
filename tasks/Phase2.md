# Phase 2: Hybrid Single/Multi-Location + Dashboards

**Status**: Not Started  
**Estimated Duration**: 5–7 days  
**Owner**: Human (with agent support)

## Goals
Implement full hybrid single/multi-location support with automatic UI simplification and improved dashboard navigation.

## Acceptance Criteria
- Automatic UI simplification for single-location franchises.
- Location switching on mobile and web.
- Primary/secondary location rules implemented and enforced.
- Role-based dashboard navigation fully functional.
- All changes respect franchise scoping and dynamic configs.
- Full human review and testing on real devices (Samsung S25 + Chrome).

## Defensive Items
- No breaking changes to existing single-location flows.
- Thorough testing of location switching edge cases.
- Human approval required for any changes to state management or navigation logic.

## Key Tasks
1. Implement location detection and hybrid logic in FranchiseProvider.
2. Add automatic UI simplification for single-location (hide multi-location features).
3. Build location switching UI (web + mobile).
4. Define and enforce primary/secondary location rules.
5. Update dashboards with role-based navigation.
6. Test hybrid behavior with sample multi-location data.
7. Full regression testing on web and mobile.

## Human Involvement Required
- Approve location model and rules.
- Review UI simplification logic and navigation changes.
- Sign off on Phase 2 completion before moving to Phase 3.

## Risks
- State management complexity during location switching.
- UI inconsistencies between single and multi-location views.
- Regression in core ordering flow.

**Approval Required to Exit Phase**: Human sign-off after successful review and device testing.