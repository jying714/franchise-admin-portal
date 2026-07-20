# Phase 3: Mobile Multi-Tenant Polish & Roles

**Status**: Not Started  
**Estimated Duration**: 4–6 days  
**Owner**: Human (with agent support)

## Goals
Make the mobile app fully dynamic and multi-tenant, with robust staff roles and offline support.

## Acceptance Criteria
- Remove all pizzeria hardcoding → fully config-driven UI based on restaurantType.
- Deep linking and QR support for franchise claiming functional.
- Offline support (menu cache + order queue) implemented.
- Granular staff roles and invitations working.
- iOS testing completed on iPhone 15 (or equivalent).
- Full human review and regression testing on Android + iOS.

## Defensive Items
- No regression in core ordering flow during dynamic migration.
- Thorough testing of offline scenarios.
- Human approval required for any changes affecting mobile UI or shared_core consumption.

## Key Tasks
1. Refactor mobile UI to use shared_core configs and restaurantType.
2. Implement deep linking / QR for franchise claiming.
3. Add offline support (menu cache + order queue).
4. Implement granular staff roles and invitations.
5. Test on real devices (Samsung S25 + iPhone 15).
6. Full regression testing of ordering flow.

## Human Involvement Required
- Review dynamic UI changes and restaurantType handling.
- Approve staff role/permission logic.
- Sign off on Phase 3 completion before moving to Phase 4.

## Risks
- Breaking existing mobile ordering flow.
- Offline sync edge cases.
- Performance impact on lower-end devices.

**Approval Required to Exit Phase**: Human sign-off after successful device testing and regression.