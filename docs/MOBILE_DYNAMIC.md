# Mobile App — Dynamic UI Architecture
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 20, 2026

## Current State
- Mobile app is currently pizzeria-specific (hardcoded UI elements, categories, customization flows).
- Core ordering flow is stable and device-tested.
- FranchiseProvider and shared_core unification is complete.
- P1/P2.5 cleanup (duplicated widgets, models, configs) is done.

## Target Architecture (Dynamic & Generic)
The mobile app must become **fully dynamic and restaurant-type agnostic** while remaining a **single published binary** that serves unlimited franchises.

### Core Principles
- All UI driven by `shared_core` configs + Firestore (`franchises/{franchiseId}/config/*`)
- `restaurantType` field determines available UI models, components, and flows
- FeatureGate controls visibility of advanced features
- Hybrid single/multi-location support with automatic UI simplification
- Strict agent governance: changes must stay within phase scope and receive human review

## Key Dynamic Mechanisms
1. **Config-Driven UI**
   - `ui_config.dart`, `design_tokens.dart`, `branding_config.dart`, `app_config.dart` in `shared_core`
   - Runtime theming (colors, fonts, logos) applied after franchise resolution (see `FranchiseProvider`)
   - Component registry for show/hide sections, custom fields, layouts
   - Authoritative reference: `/docs/architecture/firestore-per-franchise-config.md`

2. **Restaurant Type Handling**
   - Support for Pizzeria, Mexican, Burger, Cafe, etc.
   - Different default category structures, customization groups, menu flows
   - Extensible via Firestore schemas (`category_schemas`, etc.)

3. **Shared Core Integration**
   - All models, providers, services live in `shared_core`
   - `FranchiseProvider` as central source for branding, configuration, and location
   - Mobile-specific adapters kept minimal in `mobile_app`

4. **Offline Support**
   - Cached menu + category data
   - Order queue with sync on reconnect
   - Meets/exceeds industry standard for ordering apps

## Implementation Approach
- **Phase 1**: Config scoping in shared_core (foundational) — **Completed**
- **Phase 3 (Primary Focus)**: Mobile + Shared Core agents refactor UI to dynamic
- **Agent Guardrails**: All changes must respect existing flows, use task files (`tasks/Phase3.md`), and receive human review on architecture decisions
- **Testing**: Full regression on Samsung S25 + iPhone 15 before any phase is marked complete

## Dashboard Integration
- HQ Owner / Franchise Owner dashboard includes **Design & Branding** page with live mobile preview
- Changes published to Firestore → mobile app reflects them on next load/restart
- Human approval required for any design/config changes affecting mobile

## Success Criteria for MVP
- Single app binary works for multiple restaurant types without pizzeria hardcoding
- UI adapts correctly to configs, `restaurantType`, and location count
- Seamless hybrid single/multi-location behavior on mobile
- Performance and offline experience remain excellent
- No major refactors needed after launch

## Risks & Defensive Notes
- Avoid breaking existing ordering flow during dynamic migration
- Hybrid localization (hardcoded base + DB overrides) to be implemented carefully
- Thorough testing on real devices required before each major phase