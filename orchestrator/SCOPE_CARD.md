# SCOPE_CARD.md
**Phase 1 Workstream B — agent hard constraints**
Keep this short. Loaded on every coding task (especially minimal mode).

## IN SCOPE
- Phase 1 Workstream B micro-edits only
- Quote real source first (first 10–12 lines + relevant region)
- DesignTokens.setFranchiseProvider / live Color getters
- FranchiseProvider.setBrandingFromFranchiseDoc / currentPrimaryColorHex / currentSecondaryColorHex (hex Strings only)
- Tiny UI additions that consume existing DesignTokens (e.g. live color swatch)
- Docstrings and clarifying comments when the task explicitly asks
- Onboarding progress UI that only reads existing OnboardingProgressProvider API
- HQ Design & Branding v1 **after human shell exists** — surgical UI on named files only (`docs/slices/hq-design-branding-v1.md`)
- Prefer **product slice tasks** over further DesignTokens color-swap training on the same widgets

## OUT OF SCOPE (auto-reject if proposed)
- New fields or getters on BrandingConfig, AppConfig, DesignTokens, FeatureConfig
- FranchiseProvider() zero-arg constructor
- ChangeNotifierProvider(create: (_) => FranchiseProvider(...)) inventing construction
- FirestoreService.collection or any new Firestore query API
- Schema changes, migrations, or any Firestore writes (including branding Save in v1)
- Multi-file "while you're at it" expansions
- Invented DesignTokens members:
  - onPrimary / onSecondary / onSurface / on*
  - **currentPrimaryColor / currentSecondaryColor** (do not invent current*Color)
  - treating currentPrimaryColorHex / currentSecondaryColorHex as Color
- Hard-coded Colors.blue / theme placeholders when the task is about live branding
- Editing any file not explicitly named in the task (path allowlist)
- Identical BEFORE/AFTER (no-op) — if the region already satisfies the request, reply only: **No change needed**
- Registering HQ Design & Branding in `section_registry.dart` (Admin-only)
- Inventing branding write/save APIs or Storage upload in v1

## LIVE PATHS (do not invent alternatives)
- WEB: FranchiseProvider → DesignTokens.setFranchiseProvider → **DesignTokens.primaryColor / secondaryColor** (Color getters)
- MOBILE: FranchiseProvider → UiConfig.setFranchiseProvider → **UiConfig.primaryColor / secondaryColor**
- Hex strings live only on FranchiseProvider: currentPrimaryColorHex / currentSecondaryColorHex — never use those names as Color on DesignTokens/UiConfig

## HQ DESIGN & BRANDING v1 (product)
- Card CTA: **Open Design & Branding** → `Navigator.push` dedicated screen (not section_registry)
- Save = SnackBar **Save not wired yet** only — no Firestore write
- Logo = Image when URL present, fallback when missing
- Shell (new screen file + route push) = human/Grok first; agents fill regions after

## QUOTE DISCIPLINE
- Always quote exact first 10–12 lines of every named file before proposing an edit
- BEFORE/AFTER must be surgical (small region only) and must **differ**
- If the requested token/usage is already present → reply only: **No change needed** (do not emit identical fences)
- If required source cannot be quoted → reply only: FAILED TO LOAD

## PATH ALLOWLIST + AUTO-REJECT
- Only edit files the task explicitly names.
- HARD BAN and path-allowlist hits are auto-rejected (status=rejected; no apply).
- Identical BEFORE/AFTER is a reject candidate (no-op).
