# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (afternoon — single FranchiseProvider; live HQ branding; menu items v1 closed)  
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
- [x] **Multi-file parse/apply** in `proposal_store.py` + main.py messaging (July 25)
- [x] Validator: net-new checks AFTER bans; skip HARD BAN on pure no_change; Role: line routing
- [x] **xAI task lessons (July 25)**: quote-first + exact on-disk BEFORE succeeds; empty-file BEFORE fails HARD BAN; STATUS/markdown prose breaks AFTER parse; verify-only burns queue; **same-path dual FILE headers** → allowlist HARD BAN; single-line BEFORE whitespace fail; inventing `removeMenuItem` / `ChangeNotifierProvider<shared.OnboardingProgressProvider>` fails analyzer
- [x] **xAI-first operating mode**: primary = `backend: xai` outcome tasks; Ollama optional verify-only
- [ ] Optional model A/B; structured unified-diff; empty-file full-file apply path; auto-reject `after parsed: no`; validator honor `max_regions`

### B. Product — Core config scoping & dynamic branding

**Web branding path (logic) — COMPLETE for live switch (July 26):**

- [x] `DesignTokens.setFranchiseProvider` at authenticated bootstrap
- [x] Franchise doc → `setBrandingFromFranchiseDoc`; live primary/secondary getters
- [x] Authenticated MaterialApp themes from live DesignTokens + `appBarTheme.backgroundColor: DesignTokens.primaryColor`
- [x] **FranchiseProvider extends ChangeNotifier**; `_bumpConfig` → `notifyListeners`
- [x] **`setBrandingFromFranchiseDoc` / `applyBrandingFromInfo` call `_bumpConfig()`** (must notify — silent branding was the lag root cause)
- [x] Web: **single** `ChangeNotifierProvider<FranchiseProvider>` at app root; authenticated MultiProvider must **not** create a second instance (Phase 0–2 proven July 26)
- [x] Franchise picker: `setFranchiseId` → Firestore doc → `setBrandingFromFranchiseDoc` with **stale-response guard** (`franchiseId == requestedId`)
- [x] `setFranchiseId` clears `_brandingData` so previous franchise hex cannot paint after switch
- [x] HQ dashboard AppBar explicit `backgroundColor: DesignTokens.primaryColor`; Live Branding keys on franchiseId/configVersion

**HQ Design & Branding screen**

- [x] **v1** (Decision 8): Live Branding card + Open Design & Branding → `design_branding_screen.dart`
- [x] **v1.1** Save merges branding keys to `franchises/{id}` + `config/ui_config`
- [x] Draft resync on franchise change (`didChangeDependencies` + `_syncedFranchiseId`)
- [x] Context line shows `DesignTokens.currentAppName (id)`
- [ ] Color picker UI (downstream)
- [ ] Optional: branding as **onboarding step or Review gate** — see active slice `docs/slices/hq-onboarding-hq-polish-v1.md`

**Onboarding — Decision 7 migration (host move complete)**

| Phase | Status | Notes |
|-------|--------|--------|
| 1–4 Host move + Admin delete | Done | HQ sole host |
| 5 Progress keys + writers | Done | product keys on disk |

**Progress / menu UX:**

- Firestore: `franchises/{id}/onboarding_progress/progress`
- Card watches **Impl**; shell: `ChangeNotifierProvider<OnboardingProgressProviderImpl>` + `ProxyProvider` → abstract
- [x] Continue onboarding → **first incomplete** product step
- [x] Quick Link Onboarding → first incomplete cascade (on disk)
- [x] Menu dirty Save → `persistChanges()`
- [x] Menu Delete → **`deleteMenuItemAndPersist`** + list refresh
- [x] Foundation Save & Continue → mark + **switchToSection('onboardingMenuItems')**
- [x] Feature Setup save → shell `switchToSection('onboarding_menu_foundation')` when in shell
- [x] Publish → `onboardingReview`; review ready/not-ready copy present
- [x] Review 4/4 chrome; Action column stripped
- [x] Onboarding summary panel shows live `N/4` product keys

**HQ Onboarding Step 3 — Menu Items v1: COMPLETE** — `docs/slices/hq-onboarding-menu-items-v1.md`

**Active product slice:** `docs/slices/hq-onboarding-hq-polish-v1.md`  
Authority for remaining onboarding chrome honesty, Review false positives, Feature Setup in-dev flags, HQ dashboard MVP card audit, preview/FAB parity, foundation JSON/back-arrow cleanup, optional branding-in-onboarding.

**Still open (product) — tracked in polish slice, not free-form:**

- [ ] Foundation: remove in-shell back arrows (types/categories); remove JSON import/export entry points
- [ ] Foundation tab “Mark complete” — remove or sub-key only (must not fake product step)
- [ ] Step 3 FAB position = Step 2 list-pane bottom-end (not under preview)
- [ ] Preview call-site constraint parity Step 2 vs Step 3
- [ ] Review false positive: “enable menu management” when features already on — tracer + key fix
- [ ] Feature Setup: non-GA features visible, disabled, “In development”
- [ ] HQ dashboard: dead routes (payouts/invoices); Quick Links; Billing vs Invoices; card sizing; non-MVP → In development
- [ ] Optional: Design & Branding in onboarding (step or Review gate)

**Ground truth (do not regress):**

- Never invent `FranchiseProvider()` zero-arg / `FirestoreService.collection` / static `current*`
- **One** web `FranchiseProvider` at app root only
- No new BrandingConfig / DesignTokens / FeatureConfig fields for scoping
- Onboarding home = HQ only; progress path under franchise
- Menu delete API = **`deleteMenuItem` / `deleteMenuItemAndPersist`**; progress CNP type = **Impl** not abstract
- Branding writes must `_bumpConfig()` / `notifyListeners`
- Preview chrome owned by `MobileMenuPreviewCard` (340×680)
- **Agent mode**: xAI primary; Ollama secondary

---

## Target workflow

1. Agent proposes → human `/approve` → `/approve confirm` → human git  
2. Never Firestore/production from agents  
3. HARD BAN / `after parsed: no` → reject  
4. "No change needed" → success  

Prompt style: **AGENT_SYSTEM.md** + **SCOPE_CARD**. Queue: `orchestrator/queue/inbox/`.

---

**Update this file after significant sessions.**
