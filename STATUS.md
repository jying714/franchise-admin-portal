# STATUS.md — Live Project Snapshot

**Last Updated**: July 23, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent (full for status/planning; short excerpt in minimal coding mode).

---

## Current Phase

**Phase 1 – Agent Hardening → Core Config Scoping & Dynamic Branding**

Phase 0 complete (July 23, 2026).

### A. Agent hardening

- [x] **A1** Soften over-refusal on docstring/comment-only edits
- [x] **A4** Human-merged class docstring on `user.dart`
- [x] **A3** Proposal validator (field/method drift warnings)
- [x] **Approve-to-apply skeleton** + `/approve <id>` / `/approve confirm <id>`
- [x] **A2** Preferred coding-task prompt style documented (`AGENT_SYSTEM.md` + `orchestrator/README.md`)
- [x] End-to-end proof: address.dart docstring proposed → reviewed by id → local apply succeeded
- [x] **Multi-line task input** — paste full task, finish with `END` on its own line (`orchestrator/main.py`)
- [x] **Ollama client timeout** raised to 600s + fallback to 7b on ReadTimeout/HTTP 500
- [x] **Minimal context mode** for source-file tasks — short STATUS excerpt + hard rules only (`context_loader.py`)
- [x] **Strict `## BEFORE` / `## AFTER` fenced blocks** required in coding prompts (`agent_router.py`)
- [x] **Proposal parser hardened** for BEFORE/AFTER extraction (`proposal_store.py`)
- [x] **Apply-path verified end-to-end** — propose → parse → `/approve confirm` → local file write succeeded
- [x] **Fuzzy BEFORE match** for local apply when model reformats whitespace/line breaks (`proposal_store.py`)
- [ ] **A5** (Optional) Model A/B
- [ ] Structured unified-diff proposals (optional; fences + fuzzy match cover many small edits)
- [ ] Optional: don’t persist empty/junk proposals

### B. Product — Core config scoping & dynamic branding

**Documentation foundation:**

- [x] `branding_config.dart` — static defaults; Phase 1 Workstream B owns scoping
- [x] `app_config.dart` — class docstring + `AppConfig.current` points at FranchiseProvider surface
- [x] `design_tokens.dart` (shared_core) — static defaults; dynamic theming = Workstream B
- [x] `feature_config.dart` — static defaults + apply() path
- [x] `franchise_provider.dart` — runtime owner of franchise-scoped branding/config
- [x] `setBrandingFromFranchiseDoc` — documented keys already read by getters
- [x] Mobile `main.dart` — live path comment: FranchiseProvider → UiConfig
- [x] Web `design_tokens.dart` — live path comment: FranchiseProvider → DesignTokens

**Web branding path (logic — landed this session):**

- [x] `DesignTokens.setFranchiseProvider(franchiseProvider)` at authenticated bootstrap (`web-app/lib/main.dart`)
- [x] After `initializeWithUser` / `forceRefreshFranchiseId`, best-effort `FirebaseFirestore` fetch of `franchises/{id}` → `setBrandingFromFranchiseDoc`
- [x] `if (mounted) setState(() {})` after branding load so tree can rebuild
- [x] Authenticated **light** `MaterialApp.theme` built at runtime from web `DesignTokens` (not frozen `_lightTheme`)
- [ ] Authenticated **dark** `MaterialApp.darkTheme` built at runtime from web `DesignTokens` (still uses frozen `_darkTheme`)
- [ ] Unauth `MaterialApp` themes still use top-level `_lightTheme` / `_darkTheme` (acceptable for landing/sign-in)
- [ ] Optional: remove unused top-level theme constants once both auth themes are inlined

**Mobile branding path (already present; documented):**

- [x] `FranchiseProvider(AppLocalStorage())` + `UiConfig.setFranchiseProvider(fp)`
- [x] `setBrandingFromFranchiseDoc` from franchise doc / deep links
- [x] Theme shell reacts via `Selector` + `UiConfig` colors

**Still open (product):**

- [ ] Finish web dark theme runtime wiring (next micro-task)
- [ ] HQ Design & Branding dashboard + live preview
- [ ] Broader franchise-scoped config beyond branding colors (features, app config loaders)
- [ ] Hybrid localization (partial)

**Ground truth (do not regress):**

- Branding model exists at `packages/shared_core/lib/src/core/config/branding_config.dart`
- `FranchiseProvider` owns runtime branding; static config classes are defaults/fallbacks
- Never invent `FranchiseProvider()` zero-arg or `FirestoreService.collection(...)`
- Web live colors: `FranchiseProvider` → `DesignTokens.setFranchiseProvider` → `DesignTokens.*` getters
- Mobile live colors: `FranchiseProvider` → `UiConfig.setFranchiseProvider` → `UiConfig.*`
- Do not invent new fields on BrandingConfig / AppConfig / DesignTokens / FeatureConfig for scoping

---

## Target workflow

1. Agent proposes (real source, strict `## BEFORE` / `## AFTER` fences)  
2. Human reviews (`/approve <id>`, validation warnings)  
3. `/approve confirm <id>` → local apply only  
4. Human commits/pushes  
5. Never Firestore/production from agents  

Prompt style: see **AGENT_SYSTEM.md → Preferred Coding Task Prompt Style**.  
Interactive CLI: paste multi-line task, type `END` on its own line.

---

## Hard Rules

- Propose first; apply only after `/approve confirm`
- Apply = local files only — not push
- `shared_core` source of truth; franchise-scoped data paths
- Stay in current phase acceptance criteria
- Never invent fields on BrandingConfig / AppConfig / DesignTokens / FeatureConfig for scoping work
- Never invent FirestoreService.collection or zero-arg FranchiseProvider()

---

**Update this file after significant sessions.**
