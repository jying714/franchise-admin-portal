# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (morning — menu items v1 closed; FranchiseProvider listenable)  
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

**Web branding path (logic):**

- [x] `DesignTokens.setFranchiseProvider` at authenticated bootstrap
- [x] Franchise doc → `setBrandingFromFranchiseDoc`; live primary/secondary getters
- [x] Authenticated MaterialApp themes from live DesignTokens
- [x] **FranchiseProvider extends ChangeNotifier** + `notifyListeners` in `_bumpConfig` (July 26)
- [x] Web registers `ChangeNotifierProvider<FranchiseProvider>` (not plain `Provider`)
- [x] Franchise picker reloads branding after `setFranchiseId` (`setBrandingFromFranchiseDoc` / `applyBrandingFromInfo`)

**HQ Design & Branding**

- [x] **v1** (Decision 8): Live Branding card + Open Design & Branding → `design_branding_screen.dart`
- [x] **v1.1** (July 25): Save merges branding keys to `franchises/{id}` + `config/ui_config`; `setBrandingFromFranchiseDoc`
- [ ] Draft section label still may say “Save not wired yet” (copy fix)
- [ ] Draft-hex live swatches polish if still outstanding
- [ ] Color picker UI (downstream)
- [ ] **HQ Owner dashboard shell** still does not fully re-theme on franchise switch (progress card does; chrome often does not) — follow-up

**Onboarding — Decision 7 migration (host move complete)**

| Phase | Status | Notes |
|-------|--------|--------|
| 1–4 Host move + Admin delete | Done | HQ sole host |
| 5 Progress keys + writers | Done | product keys on disk |

**Progress / menu UX:**

- Firestore: `franchises/{id}/onboarding_progress/progress`
- Card watches **Impl**; shell: `ChangeNotifierProvider<OnboardingProgressProviderImpl>` + `ProxyProvider` → abstract
- [x] Continue onboarding → **first incomplete** product step
- [x] Menu dirty Save → `persistChanges()`
- [x] Menu Delete → **`deleteMenuItemAndPersist`** + list refresh
- [x] Foundation Save & Continue → mark + **switchToSection('onboardingMenuItems')**
- [x] Publish → `onboardingReview`; review ready/not-ready copy present
- [x] Review 4/4 chrome; Action column stripped; FAB in-screen editor

**HQ Onboarding Step 3 — Menu Items v1 (July 26): COMPLETE**

- [x] Foundation gate + nav to `onboarding_menu_foundation`
- [x] Schema sidebar contrast + readable issues; `$0` warning; mark-complete gated on zero errors
- [x] List error affordance; template + residual UX; hard delete with confirm
- [x] Shared `MobileMenuPreviewCard` (interactive on Step 3): categories → items, franchise name/colors
- [x] List tile chrome aligned with foundation
- [x] Stay-on-surface franchise switch on Step 3 (list + preview reload) via FranchiseProvider listenable + picker branding
- Deferred: Liberty-only `ingredientId` String/int noise (test franchise; skip); HQ dashboard full design re-theme on switch (separate)

**Still open (product):**

- [ ] Branding draft label + any remaining draft-hex polish
- [ ] HQ Quick Link Onboarding still hardcodes `onboardingMenu` (not first incomplete) — verify if still true
- [ ] Feature Setup save success still `maybePop` (prefer in-shell → foundation)
- [ ] Empty `onboarding_summary_panel.dart` (~3 bytes stub) if still stub
- [ ] HQ Owner dashboard live branding on franchise switch (chrome, not only progress card)
- [ ] Broader franchise-scoped config; hybrid localization; color picker

**Ground truth (do not regress):**

- Never invent `FranchiseProvider()` zero-arg / `FirestoreService.collection` / static `current*`
- No new BrandingConfig / DesignTokens / FeatureConfig fields for scoping
- Onboarding home = HQ only; progress path under franchise
- Menu delete API = **`deleteMenuItem` / `deleteMenuItemAndPersist`**; progress CNP type = **Impl** not abstract
- **FranchiseProvider is ChangeNotifier**; web must use `ChangeNotifierProvider`
- Preview size chrome owned only by `MobileMenuPreviewCard` (340×680)
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
