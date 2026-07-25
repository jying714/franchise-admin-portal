# SCOPE_CARD.md
**Phase 1 Workstream B — agent hard constraints**
Keep this short. Loaded on every coding task (especially minimal/smart mode).

## Operating mode (July 25 evening)
- **Primary engine: `backend: xai`** (grok-4.5) — product **outcome** tasks
- **Ollama**: optional verify-only / tiny hygiene — not the main queue
- Both remain **proposal only** (human `/approve confirm`)

## IN SCOPE
- Phase 1 product work under HQ onboarding + Design & Branding + related HQ surfaces
- Quote real source first (first 10–12 lines + relevant region)
- DesignTokens.setFranchiseProvider / live Color getters
- FranchiseProvider instance hex getters only (never static)
- UI that consumes existing DesignTokens / OnboardingProgressProvider API
- HQ onboarding under `web-app/lib/admin/hq_owner/onboarding/**`
- Progress keys (product): `onboarding_feature_setup`, `onboarding_menu_foundation`, `onboardingMenuItems`, `onboardingReview`
- Foundation sub-keys only for detail %: `ingredientTypes`, `ingredients`, `categories`
- **xAI**: one **product outcome** per task (may span 2–3 related regions in one file)
- Prefer product outcomes over color-swap / print-cleanup / import-only chores (those are secondary)

## OUT OF SCOPE (auto-reject if proposed)
- New fields/getters on BrandingConfig, AppConfig, DesignTokens, FeatureConfig
- FranchiseProvider() zero-arg / invented ChangeNotifierProvider FranchiseProvider
- **Static** FranchiseProvider.current* access
- FirestoreService.collection or **new** Firestore query APIs not in the region
- Schema changes / new collections
- Multi-file "while you're at it" expansions beyond files the task names
- Invented DesignTokens on* / current*Color
- Hard-coded Colors.blue on live-branding tasks
- Editing any file not named in the task
- Identical BEFORE/AFTER — reply only: **No change needed**
- Partial completion / "Next steps for human" when the required wiring was the goal
- Registering onboarding or Design & Branding in `section_registry.dart`
- Reintroducing Admin onboarding host (`admin/dashboard/onboarding/**` is **deleted**)
- Top-level `onboarding_progress/{id}` path — use `franchises/{id}/onboarding_progress/progress` only
- Using AdminDashboardScreen.switchToSection for HQ onboarding navigation (use HqOnboardingShellScreenState)
- **Invented** `import '.../onboarding_progress_provider.dart'` — progress type is **`shared.OnboardingProgressProvider`** (from shared_core / existing alias)
- **Invented** `removeMenuItem` — MenuItemProvider API is **`deleteMenuItem(String id)`**
- **`ChangeNotifierProvider<shared.OnboardingProgressProvider>`** — abstract is pure Dart (not ChangeNotifier)

## HARD BAN SCOPE
- HARD BAN applies to **net-new proposed code**, not quoting existing source.
- If live file already satisfies task → **only**: **No change needed**
- Verify-only tasks: never rewrite bootstrap branding or DesignTokens bridge.
- Empty BEFORE fence when file is empty/BOM-only → will HARD BAN (see TASK DESIGN).

## APPLY SAFETY (mandatory — all backends)
- **xAI default**: up to **2** BEFORE/AFTER regions per file; task may set `max_regions: 3` for one coherent outcome
- **Prefer max_regions: 1** when wiring a single stub/callback
- **Ollama default**: prefer **1** region; max 2 only when task says so
- **One FILE path once** per proposal (do not emit two FILE headers for the same path — allowlist HARD BAN)
- Respond with FILE/BEFORE/AFTER fences only when editing — **no prose about truncation**
- Prefer **multi-line** BEFORE windows (parent widget context), not isolated single lines (whitespace match fails)
- **Never remove an import** unless every symbol from that import is unused **after** your change.
- `OnboardingSections` lives in `onboarding_navigation_utils.dart` — if `_sectionOrder` / UI still references it, **keep** that import.
- Method delete: BEFORE = full method body; AFTER must be **empty** (no lines). **Forbidden**: AFTER that is only `}` or `);`.
- Do not “clean up” imports as a side quest unless the task requires it and they are truly unused.
- Same path appearing as 5+ FILE blocks is a failure mode — consolidate.
- `after parsed: no` → treat as reject (do not apply)

## LIVE PATHS (do not invent alternatives)
- WEB: FranchiseProvider → DesignTokens.setFranchiseProvider → DesignTokens.primaryColor / secondaryColor
- MOBILE: FranchiseProvider → UiConfig.setFranchiseProvider → UiConfig.*
- Hex: franchiseProvider instance only
- Onboarding host: HqOnboardingShellScreen + in-shell switchToSection
- Progress Firestore: franchises/{franchiseId}/onboarding_progress/progress
- Progress provider in UI: `Provider.of<shared.OnboardingProgressProvider>(context, listen: false)` — **not** a new web-app progress_provider import
- HQ shell listenable progress:
  - `ChangeNotifierProvider<OnboardingProgressProviderImpl>.value(...)`
  - `ProxyProvider<OnboardingProgressProviderImpl, shared.OnboardingProgressProvider>(update: (_, impl, __) => impl)`
  - **Never** `ChangeNotifierProvider<shared.OnboardingProgressProvider>` (abstract does not extend ChangeNotifier)
- MenuItemProvider delete: **`deleteMenuItem(String id)`** then usually `await persistChanges()`

## HQ DESIGN & BRANDING
- v1 UI landed; v1.1 Save may write existing franchise branding keys when task explicitly says so
- No section_registry for HQ entry
- No new BrandingConfig/DesignTokens fields

## ONBOARDING PROGRESS (product rules)
- Tab marks (types/ingredients/categories) → sub-keys only — do **not** mark `onboarding_menu_foundation` from tab-only complete
- Step 2 product key only via foundation Save & Continue / explicit foundation complete
- `onboardingReview` only on successful Publish (not summary-table validation)
- Menu complete/incomplete must use key **`onboardingMenuItems`** (not `menu_items`)
- markStepComplete / markStepIncomplete / isStepComplete via **shared.OnboardingProgressProvider** only

## QUOTE DISCIPLINE
- Quote exact first 10–12 lines of every named file before edit
- BEFORE/AFTER surgical and must **differ**
- Already correct → **No change needed** only
- Cannot load source → FAILED TO LOAD
- Multi-file only when task lists each path; separate BEFORE/AFTER per file

## PATH ALLOWLIST + AUTO-REJECT
- Only edit files the task explicitly names.
- HARD BAN / path-allowlist → auto-rejected.

## TASK DESIGN

### xAI (primary) — outcome tasks
- **Unit of work**: one **product outcome** in one sentence.
- **Shape**: `backend: xai` + optional `max_regions: 1|2` + one primary file.
- **Win pattern**: paste **exact on-disk BEFORE** + clear AFTER using only real APIs (`deleteMenuItem`, progress keys, etc.).
- Prefer **real fix** when goal is unmet; **No change needed** only when already on disk.
- Batch size: **4–8 outcome tasks** per AFK run (not 20 micro-chores).
- Secondary polish is fine as low-priority fillers — not the main load.

### Ollama (secondary) — surgical / verify
- Prefer 1 region, one tiny change, escape-hatch no_change when ambiguous.
- Use for verify-only smoke after xAI applies, or when xAI key is unavailable.

### All backends
- **Empty / near-empty files**: empty BEFORE cannot match → HARD BAN. Prefer human full-file write, or: “file may be empty; emit full-file AFTER only; do not invent empty BEFORE.”
- **STATUS.md / markdown**: contiguous checklist lines only; prefer human edit.
- Never invent progress import path; always `shared.OnboardingProgressProvider`.
