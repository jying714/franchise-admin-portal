# STATUS.md — Live Project Snapshot

**Last Updated**: July 25, 2026 (xAI-first mode; progress writers + HQ polish applied)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent (full for status/planning; short excerpt in minimal coding mode).

---

## Current Phase

**Phase 1 – Agent Hardening → Core Config Scoping & Dynamic Branding**

Phase 0 complete (July 23, 2026).

### A. Agent hardening

- [x] Soften over-refusal, validator, SCOPE_CARD, hard bans, path allowlist, auto-reject, `no_change`, `/metrics`
- [x] 2-file surgical reliable; dual-edit on dirty pairs improved
- [x] **Multi-file parse/apply** in `proposal_store.py` + main.py messaging (July 25) — FILE: path + BEFORE/AFTER pairs; apply smoke proven
- [x] Validator: net-new checks AFTER bans; skip HARD BAN on pure no_change; Role: line routing
- [x] **xAI task lessons (July 25)**: quote-first + exact on-disk BEFORE succeeds; empty-file BEFORE fails HARD BAN; STATUS/markdown prose breaks AFTER parse; verify-only tasks burn queue
- [x] **xAI-first operating mode (July 25 evening)**: primary engine = `backend: xai` outcome tasks (≤2–3 regions); Ollama optional verify-only; SCOPE_CARD + orchestrator README updated
- [ ] Optional model A/B; structured unified-diff; 3-file volume training (optional only)
- [ ] Empty-file / full-file replace apply path (optional)
- [ ] Auto-reject when `after parsed: no` (same class as HARD BAN)
- [ ] Validator honor `max_regions` from task header for xAI

### B. Product — Core config scoping & dynamic branding

**Web branding path (logic):**

- [x] `DesignTokens.setFranchiseProvider` at authenticated bootstrap
- [x] Franchise doc → `setBrandingFromFranchiseDoc`; live primary/secondary getters
- [x] Authenticated MaterialApp themes from live DesignTokens

**HQ Design & Branding**

- [x] **v1** (Decision 8): Live Branding card + Open Design & Branding → `design_branding_screen.dart`; draft fields; Save snackbar; Cancel reset
- [x] **v1.1** (July 25): Save merges `primaryColorHex` / `secondaryColorHex` / `appName` / `logoUrl` to `franchises/{id}` + `config/ui_config`; then `setBrandingFromFranchiseDoc`. Screen-owned Firestore for now; extract to Admin/FirestoreService when editor expands
- [ ] Color picker UI (downstream)
- [ ] Broader design tokens / more HQ-editable fields (later)

**Platform Owner Provider wiring (July 24–25):**

- [x] FranchiseeInvitation abstract alias; `FranchiseSubscriptionService` in MultiProvider; PlatformFinancials uses AdminFirestoreService

**Onboarding — Decision 7 migration (July 25 complete for host move)**

Copy-first then Admin removal. HQ is the **sole product host** for franchise/menu onboarding.

| Phase | Status | Notes |
|-------|--------|--------|
| 1 Copy tree + rewrite imports | Done | `web-app/lib/admin/hq_owner/onboarding/**` |
| 2 HQ shell + Continue | Done | `HqOnboardingShellScreen`; overview/foundation in-shell `switchToSection`; smoke 1–17 pass |
| 3 Deep links + review Fix | Done | `resolveRoute` → `/hq/onboarding?section=…`; main.dart HQ route before generic `hq`; review Fix prefers shell |
| 4 Admin removal | Done | Admin onboarding tree **deleted**; `section_registry` ops-only; Admin sidebar no Franchise Onboarding group |
| 5 Progress keys + tracking | Done (writers) | Card shows 4 product steps; Feature Setup / foundation / menu / publish keys on disk |

**Progress tracking ground truth (July 25):**

- Firestore path: `franchises/{franchiseId}/onboarding_progress/progress` (not top-level `onboarding_progress/{id}`)
- Rules: franchise subcollection + explicit `onboarding_progress/{docId}` under franchise
- `OnboardingProgressProviderImpl`: mutable franchiseId via `updateFranchiseId`; ProxyProvider must sync when `FranchiseProvider.franchiseId` loads
- HQ progress **card must** `Consumer`/`watch` **`OnboardingProgressProviderImpl`** (abstract `ProxyProvider` alias is not listenable)
- Product step keys: `onboarding_feature_setup`, `onboarding_menu_foundation`, `onboardingMenuItems`, `onboardingReview`
- Foundation **detail** % uses sub-keys only: `ingredientTypes`, `ingredients`, `categories` via `getFoundationProgress()`
- Step 2 product key **only** via foundation Save & Continue / explicit foundation complete — **not** tab-level marks
- `onboardingReview` progress key **only** on successful Publish (summary table “Complete” = validation only)
- Menu complete/incomplete must use **`onboardingMenuItems`** (not `menu_items`)
- [x] Feature Setup mark complete → HQ card step 1 + overall % **verified**
- [x] Menu Items unmark incomplete (same key) — toggle via `isStepComplete` / `markStepIncomplete` / `markStepComplete`
- [x] Foundation Save & Continue → `await markStepComplete('onboarding_menu_foundation')`
- [x] Publish → `markStepComplete('onboardingReview')` → card step 4
- [x] Review UX: summary **Action / Fix Now** column removed; expansion section-only Fix remains
- [x] Review chrome is 4/4 (not Step 6 of 6)
- [x] Menu FAB no longer navigates Admin `/dashboard?section=menuItemEditor` — uses in-screen `openEditor`
- [x] Menu status bar uses live provider counts (not hard-coded 18/6/17)
- [x] Foundation template snackbar is MVP-clear (not “Phase 3 wiring”)
- [x] HQ shell exposes progress via **ChangeNotifierProvider** value (listenable to children)
- [x] Overview: no “More steps coming soon”; HQ Quick Link → Onboarding

**Still open (product):**

- [ ] Broader franchise-scoped config beyond branding
- [ ] Hybrid localization (partial)
- [ ] Color picker UI (Design & Branding downstream)
- [ ] Menu dirty-row `persistChanges` + delete dialog (if still stubs on disk)
- [ ] Branding draft-hex live swatches + stale “Save not wired” copy (if still present)
- [ ] Empty `onboarding_summary_panel.dart` stub (full-file replace or delete)
- [ ] Continue onboarding → first incomplete step (smart initial section)

**Ground truth (do not regress):**

- Branding model exists at `packages/shared_core/.../branding_config.dart`
- Never invent `FranchiseProvider()` zero-arg or `FirestoreService.collection(...)`
- Never static `FranchiseProvider.current*` — instance only
- Web live colors: FranchiseProvider → DesignTokens.setFranchiseProvider → getters
- Mobile live colors: FranchiseProvider → UiConfig.setFranchiseProvider → UiConfig.*
- Do not invent new fields on BrandingConfig / AppConfig / DesignTokens / FeatureConfig for scoping
- **Onboarding home = HQ Owner only** (Decision 7). Admin onboarding tree removed; do not re-add Admin onboarding host
- HQ entry: `HqOnboardingShellScreen` under `web-app/lib/admin/hq_owner/onboarding/`
- `section_registry.dart` is Admin **ops** only — no onboarding sections
- Design & Branding v1.1 may write franchise branding keys; expand via service when editor grows
- Onboarding progress path: `franchises/{id}/onboarding_progress/progress`
- Card watches **Impl**, not abstract-only ProxyProvider
- Authenticated MaterialApp must not rebuild on every AdminUserProvider notify (identity/roles Selector)
- See `orchestrator/SCOPE_CARD.md` for short always-on constraints
- **Agent mode**: xAI primary (outcome tasks); Ollama secondary

---

## Target workflow

1. Agent proposes (real source, strict BEFORE/AFTER; multi-file FILE: headers supported)  
2. Human reviews (`/approve <id>`, HARD BAN hits)  
3. `/approve confirm <id>` → local apply only  
4. Human commits/pushes  
5. Never Firestore/production from agents  
6. `/reject` → feedback JSONL; HARD BAN → auto-reject  
7. "No change needed" → `status=no_change`  
8. `/metrics` → training rates over last 50

Prompt style: **AGENT_SYSTEM.md** + **SCOPE_CARD** (xAI outcome / Ollama surgical). Interactive: paste task, `END`. Queue: `orchestrator/queue/inbox/`.

---

## Hard Rules

- Propose first; apply only after `/approve confirm`
- Apply = local files only — not push
- Queue never auto-applies
- `shared_core` source of truth; franchise-scoped data paths
- Stay in current phase acceptance criteria
- Never invent fields on BrandingConfig / AppConfig / DesignTokens / FeatureConfig for scoping work
- Never invent FirestoreService.collection or zero-arg FranchiseProvider()
- Never static `FranchiseProvider.current*` access
- Treat validator HARD BAN hits as reject candidates (auto-rejected)
- Edit only files named in the task (path allowlist)
- If region already satisfies the request → **No change needed**
- Do not reintroduce Admin onboarding host or top-level `onboarding_progress/{id}` path

---

**Update this file after significant sessions.**
