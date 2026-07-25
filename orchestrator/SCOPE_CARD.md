# SCOPE_CARD.md
**Phase 1 Workstream B — agent hard constraints**
Keep this short. Loaded on every coding task (especially minimal mode).

## IN SCOPE
- Phase 1 Workstream B micro-edits only
- Quote real source first (first 10–12 lines + relevant region)
- DesignTokens.setFranchiseProvider / live Color getters
- FranchiseProvider instance hex getters only (never static)
- Tiny UI that consumes existing DesignTokens / OnboardingProgressProvider API
- HQ onboarding under `web-app/lib/admin/hq_owner/onboarding/**` only
- Progress keys (product): `onboarding_feature_setup`, `onboarding_menu_foundation`, `onboardingMenuItems`, `onboardingReview`
- Foundation sub-keys only for detail %: `ingredientTypes`, `ingredients`, `categories`
- Prefer **product slice tasks** over color-swap drills

## OUT OF SCOPE (auto-reject if proposed)
- New fields/getters on BrandingConfig, AppConfig, DesignTokens, FeatureConfig
- FranchiseProvider() zero-arg / invented ChangeNotifierProvider FranchiseProvider
- **Static** FranchiseProvider.current* access
- FirestoreService.collection or **new** Firestore query APIs not in the region
- Schema changes / new collections
- Multi-file "while you're at it" expansions
- Invented DesignTokens on* / current*Color
- Hard-coded Colors.blue on live-branding tasks
- Editing any file not named in the task
- Identical BEFORE/AFTER — reply only: **No change needed**
- Partial completion / "Next steps for human" on required wiring
- Registering onboarding or Design & Branding in `section_registry.dart`
- Reintroducing Admin onboarding host (`admin/dashboard/onboarding/**` is **deleted**)
- Top-level `onboarding_progress/{id}` path — use `franchises/{id}/onboarding_progress/progress` only
- Using AdminDashboardScreen.switchToSection for HQ onboarding navigation (use HqOnboardingShellScreenState)

## HARD BAN SCOPE
- HARD BAN applies to **net-new proposed code**, not quoting existing source.
- If live file already satisfies task → **only**: **No change needed**
- Verify-only tasks: never rewrite bootstrap branding or DesignTokens bridge.

## LIVE PATHS (do not invent alternatives)
- WEB: FranchiseProvider → DesignTokens.setFranchiseProvider → DesignTokens.primaryColor / secondaryColor
- MOBILE: FranchiseProvider → UiConfig.setFranchiseProvider → UiConfig.*
- Hex: franchiseProvider instance only
- Onboarding host: HqOnboardingShellScreen + in-shell switchToSection
- Progress Firestore: franchises/{franchiseId}/onboarding_progress/progress

## HQ DESIGN & BRANDING
- v1 UI landed; v1.1 Save may write existing franchise branding keys when task explicitly says so
- No section_registry for HQ entry
- No new BrandingConfig/DesignTokens fields

## ONBOARDING PROGRESS (product rules)
- Tab marks (types/ingredients/categories) → sub-keys only — do **not** mark `onboarding_menu_foundation` from tab-only complete
- Step 2 product key only via foundation Save & Continue / explicit foundation complete
- `onboardingReview` only on successful Publish (not summary-table validation)
- Menu complete/incomplete must use key **`onboardingMenuItems`** (not `menu_items`)

## QUOTE DISCIPLINE
- Quote exact first 10–12 lines of every named file before edit
- BEFORE/AFTER surgical and must **differ**
- Already correct → **No change needed** only
- Cannot load source → FAILED TO LOAD
- 2-file: separate BEFORE/AFTER per file; No change needed OK on clean file

## PATH ALLOWLIST + AUTO-REJECT
- Only edit files the task explicitly names.
- HARD BAN / path-allowlist → auto-rejected.
