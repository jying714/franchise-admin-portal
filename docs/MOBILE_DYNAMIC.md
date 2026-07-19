# Mobile App — Dynamic UI Architecture
**Doughboys Pizzeria Franchise Platform**  
**Last Updated**: July 19, 2026

## Current State (as of attachments)
- Mobile app is currently pizzeria-specific (hardcoded UI elements, categories, customization flows).
- Core ordering flow is stable and device-tested.
- FranchiseProvider and shared_core unification is complete.
- P1 cleanup (duplicated widgets, models) is in progress.

## Target Architecture (Dynamic & Generic)
The mobile app must become **fully dynamic and restaurant-type agnostic** while remaining a single published binary that serves unlimited franchises.

### Core Principles
- All UI is driven by `shared_core` configs + Firestore (`franchises/{franchiseId}/config/...`)
- `restaurantType` field determines available UI models and components
- FeatureGate controls visibility of advanced features
- Hybrid single/multi-location support with automatic UI simplification

## Key Dynamic Mechanisms

1. **Config-Driven UI**
   - `ui_config.dart` and `design_tokens.dart` in shared_core
   - Runtime theming (colors, fonts, logos) applied after franchise resolution
   - Component registry: show/hide sections, custom fields, layouts based on config

2. **Restaurant Type Handling**
   - Pizzeria, Mexican, Burger, etc.
   - Different default category structures, customization groups, menu flows
   - Extensible via Firestore schemas (`category_schemas`)

3. **Shared Core Integration**
   - All models, providers, services from `shared_core`
   - `FranchiseProvider` as central source for branding and configuration
   - Mobile-specific adapters only in `mobile_app`

4. **Offline Support**
   - Cached menu + category data
   - Order queue with sync on reconnect
   - Meets/exceeds industry standard for ordering apps

## Implementation Phases (in Roadmap)
- **Phase 1**: Config scoping in shared_core
- **Phase 3 (Lead)**: Mobile + Shared Core agent refactors UI to dynamic
- **Testing**: Full regression on Samsung S25 + iPhone 15

## Dashboard Integration
- HQ Owner / Franchise Owner dashboard includes "Design & Branding" page with live mobile preview
- Changes published to Firestore → mobile app reflects them on next load/restart

## Success Criteria for MVP
- Single app binary works for multiple restaurant types
- No pizzeria-hardcoded assumptions remain
- UI adapts correctly to configs and restaurantType
- Performance and offline experience remain excellent

---