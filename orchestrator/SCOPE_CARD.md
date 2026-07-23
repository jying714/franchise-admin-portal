# SCOPE_CARD.md
**Phase 1 Workstream B — agent hard constraints**
Keep this short. Loaded on every coding task (especially minimal mode).

## IN SCOPE
- Phase 1 Workstream B micro-edits only
- Quote real source first (first 10–12 lines + relevant region)
- DesignTokens.setFranchiseProvider / current*Color getters
- FranchiseProvider.setBrandingFromFranchiseDoc / currentPrimaryColorHex / currentSecondaryColorHex
- Tiny UI additions that consume existing DesignTokens (e.g. live color swatch)
- Docstrings and clarifying comments when the task explicitly asks

## OUT OF SCOPE (auto-reject if proposed)
- New fields or getters on BrandingConfig, AppConfig, DesignTokens, FeatureConfig
- FranchiseProvider() zero-arg constructor
- ChangeNotifierProvider(create: (_) => FranchiseProvider(...)) inventing construction
- FirestoreService.collection or any new Firestore query API
- Schema changes, migrations, or any Firestore writes
- Multi-file "while you're at it" expansions
- Invented DesignTokens members (onPrimary, invented color getters, etc.)
- Hard-coded Colors.blue / theme placeholders when the task is about live branding

## LIVE PATHS (do not invent alternatives)
- WEB: FranchiseProvider → DesignTokens.setFranchiseProvider → DesignTokens.primaryColor / secondaryColor
- MOBILE: FranchiseProvider → UiConfig.setFranchiseProvider → UiConfig.*

## QUOTE DISCIPLINE
- Always quote exact first 10–12 lines of every named file before proposing an edit
- BEFORE/AFTER must be surgical (small region only)
- If required source cannot be quoted → reply only: FAILED TO LOAD
