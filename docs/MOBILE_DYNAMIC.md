# Mobile App — Dynamic UI Architecture
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 27, 2026

## Current State
- Mobile ordering flow is stable and device-tested for **pizzeria-shaped** data.
- `CustomizationModal` still uses **category/name heuristics** (`_isPizza`, wings, drinks, hard-coded group labels such as Meats/Veggies/Cheeses).
- Menu data is overloaded: `customizationGroups` / `optionalAddOns` / `includedIngredients` plus parallel `customizations[]` and pizza/wings first-class fields.
- FranchiseProvider and shared_core unification is complete for branding/config.
- This state is **insufficient** for multi-type restaurants and for clean live MVP testing long-term.

## Target Architecture (Dynamic & Generic)
The mobile app must become **fully dynamic and restaurant-type agnostic** while remaining a **single published binary**.

### Locked execution path (July 27, 2026)

**Decision 10 — Menu modifier system full rebuild** (`docs/slices/menu-modifier-system-rebuild-v1.md`):

- One **canonical modifier group** schema (shared with web HQ + Admin).
- **`menuProfile`** (`standard` | `pizza` | `wings` | `drinks` | …) drives advanced UX (half toppings, doubles cap, sauce split, wings dips)—**not** `category.contains('pizza')`.
- Doughboys remains the **pizza profile** acceptance franchise for parity before cutover.
- Ingredient-linked options by default; free-text ad-hoc allowed as escape hatch.
- Item-level inventory flags/counts are part of the shared menu contract.

Do **not** add more production heuristic branches “for MVP.” Prefer completing rebuild workstreams M1–M5.

### Core Principles
- UI driven by `shared_core` models + Firestore per franchise
- FeatureGate for advanced features
- Hybrid single/multi-location support
- Human review on schema and cutover

## Key Dynamic Mechanisms
1. **Config-Driven branding/theme** — `ui_config`, DesignTokens, FranchiseProvider (Phase 1 largely done)
2. **Modifier groups + menuProfile** — primary path for item customization (Decision 10)
3. **Shared Core** — single domain models for web and mobile
4. **Offline** — cached menu + order queue (existing direction)

## Implementation Approach
- Phase 1 config scoping — largely complete
- **Menu modifier rebuild M1–M5** — active epic (shared_core → editors → mobile → cutover)
- Phase 3 remainder — deep linking, roles, offline polish after modifier cutover as needed
- Device regression: Samsung S25 + iPhone 15; Doughboys order parity required

## Dashboard Integration
- HQ onboarding builds the same modifier schema managers edit later in Admin Menu (Decision 9)
- Design & Branding remains HQ-owned for theme/logo

## Success Criteria
- Single binary serves pizza and non-pizza franchises without pizzeria hardcoding in the production path
- Doughboys pizza UX preserved via profile, not forks
- No dual runtime customization trees after M5 cutover

## Risks
- Migration of existing Doughboys documents must be lossless for ordering
- Temporary feature flag may be required during M4/M5; do not leave two permanent paths
