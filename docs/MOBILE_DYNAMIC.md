# Mobile App — Dynamic UI Architecture
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 28, 2026

## Current State
- Mobile ordering flow is stable on device (Samsung S25 tested for list + customize entry).
- **M4 pizza path landed** on `feat/menu-modifier-system-rebuild-v1`:
  - `menu_item_card.dart` treats `modifierGroups` / `sizes` as customizable (not only legacy `customizationGroups`).
  - `CustomizationModal` prefers `effectiveMenuProfile` + `_groupsForUi()` from `modifierGroups` (label-only structural options supported).
  - maxFree / min / max enforced; SizeData `basePrice` / `toppingPrice` used when maps absent.
  - Current toppings excludes crust/cook/cut; Order Details owns structural radios; cart payload cleaned.
  - optionLabels used when ingredient metadata missing.
- Soft category/name fallbacks remain as **compatibility**, not the preferred production path — profile-first is required for new items.
- Legacy `customizationGroups` / `optionalAddOns` / `includedIngredients` still supported via adapter for older franchises (e.g. Liberty Diner).
- FranchiseProvider and shared_core unification remain complete for branding/config.

## Target Architecture (Dynamic & Generic)
The mobile app must become **fully dynamic and restaurant-type agnostic** while remaining a **single published binary**.

### Locked execution path (July 27–28, 2026)

**Decision 10 — Menu modifier system full rebuild** (`docs/slices/menu-modifier-system-rebuild-v1.md`):

- One **canonical modifier group** schema (shared with web HQ + Admin).
- **`menuProfile`** (`standard` | `pizza` | `wings` | `drinks` | …) drives advanced UX (half toppings, doubles cap, sauce split, wings dips)—**not** `category.contains('pizza')`.
- Doughboys remains the **pizza profile** acceptance franchise for parity before cutover.
- Ingredient-linked options by default; label-only for structural options.
- Item-level inventory flags/counts are part of the shared menu contract.
- **M4 pizza path done**; broader profile QA + **M5 cutover** remain.

Do **not** add more production heuristic branches “for MVP.” Prefer completing rebuild workstream **M5** and data seed completeness.

### Core Principles
- UI driven by `shared_core` models + Firestore per franchise
- FeatureGate for advanced features
- Hybrid single/multi-location support
- Human review on schema and cutover

## Key Dynamic Mechanisms
1. **Config-Driven branding/theme** — `ui_config`, DesignTokens, FranchiseProvider (Phase 1 largely done)
2. **Modifier groups + menuProfile** — primary path for item customization (Decision 10; M4 pizza path live)
3. **Shared Core** — single domain models for web and mobile
4. **Offline** — cached menu + order queue (existing direction)

## Implementation Approach
- Phase 1 config scoping — largely complete
- **Menu modifier rebuild M1–M4 pizza** — landed on feature branch; **M5 cutover** next
- Phase 3 remainder — deep linking, roles, offline polish after modifier cutover as needed
- Device regression: Samsung S25 + iPhone 15; Doughboys order parity required before merge

## Dashboard Integration
- HQ onboarding builds the same modifier schema managers edit later in Admin Menu (Decision 9)
- Design & Branding remains HQ-owned for theme/logo

## Success Criteria
- Single binary serves pizza and non-pizza franchises without pizzeria hardcoding in the production path
- Doughboys pizza UX preserved via profile, not forks
- No dual runtime customization trees after M5 cutover

## Risks
- Incomplete re-seed after wipe makes empty UI look like code bugs — prefer data fixes first
- Temporary dual-read adapter may remain until M5; do not leave two permanent write paths
