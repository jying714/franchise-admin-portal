# STATUS.md — Live Project Snapshot

**Last Updated**: July 24, 2026 (afternoon — post inbox-batch cleanup)  
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
- [x] **SCOPE_CARD.md** — short always-on IN/OUT constraints for Phase 1 Workstream B (`orchestrator/SCOPE_CARD.md`)
- [x] **SCOPE_CARD injected** in minimal + full context (`context_loader.py`)
- [x] **Hard ban list** in proposal validator — FranchiseProvider() zero-arg, FirestoreService.collection, invented DesignTokens getters (incl. onPrimary/onSecondary/onSurface*), hard-coded blue placeholders (`proposal_validator.py`)
- [x] **2-file Stage-C** quote discipline + **product edits** proven on Owner HQ path (onboarding card + live branding polish stack, July 24)
- [x] **agent_router fix** — source files always injected when paths load; bare "progress" no longer forces status-only prompt (July 24)
- [x] **Overnight queue skeleton** — `queue/inbox|running|done`, `queue_runner.py`, `/queue status|run`, feedback JSONL on reject/apply (July 24)
- [x] **Path allowlist** — proposals may only target files named in the task; violations are HARD BAN (`proposal_validator.py`, July 24)
- [x] **Auto-reject** — when validator `ok=False` (HARD BAN / path allowlist), proposal saved as `rejected`, feedback `auto_reject`, `/approve confirm` refused (`main.py`, July 24)
- [x] **Stage A volume** — ~8–10 clean 2-file product applies + 2 useful rejects in one session (July 24); diminishing returns on further micro-polish of the same cards
- [x] **`/proposals pending|rejected|applied|full`** — status filter + full dump of pending (July 24)
- [x] **July 24 inbox batch (10 tasks)** — mostly no-ops / invents / type errors on already-polished HQ DesignTokens consumers; **0 product applies**. Confirmed failure modes: identical BEFORE/AFTER, inventing `currentPrimaryColorHex` as Color, inventing constructor args, 3-file format collapse. SCOPE_CARD updated with **No change needed** escape hatch + prefer new surfaces (July 24 afternoon).
- [ ] **A5** (Optional) Model A/B
- [ ] Structured unified-diff proposals (optional; fences + fuzzy match cover many small edits)
- [ ] Optional: don’t persist empty/junk proposals
- [ ] 3-file Stage-C still unreliable (timeouts / format collapse under full source injection) — next training frontier
- [ ] Feedback → SCOPE_CARD refresh checklist (human-gated; no auto fine-tune)
- [ ] Quote-first still inconsistently shown in human-facing proposals (process soft fail; product edits can still be correct)

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

**Web branding path (logic):**

- [x] `DesignTokens.setFranchiseProvider(franchiseProvider)` at authenticated bootstrap (`web-app/lib/main.dart`)
- [x] After `initializeWithUser` / `forceRefreshFranchiseId`, best-effort `FirebaseFirestore` fetch of `franchises/{id}` → `setBrandingFromFranchiseDoc`
- [x] `if (mounted) setState(() {})` after branding load so tree can rebuild
- [x] Authenticated **light** `MaterialApp.theme` built at runtime from web `DesignTokens`
- [x] Authenticated **dark** `MaterialApp.darkTheme` uses live `DesignTokens.primaryColor` / `secondaryColor` (verified July 24, 2026 against real `main.dart`)
- [ ] Unauth `MaterialApp` themes still use top-level `_lightTheme` / `_darkTheme` (acceptable for landing/sign-in)
- [ ] Optional: remove unused top-level theme constants once both auth themes are inlined

**Mobile branding path (already present; documented):**

- [x] `FranchiseProvider(AppLocalStorage())` + `UiConfig.setFranchiseProvider(fp)`
- [x] `setBrandingFromFranchiseDoc` from franchise doc / deep links
- [x] Theme shell reacts via `Selector` + `UiConfig` colors

**HQ live preview (partial → polished card):**

- [x] First live branding color-swatch card on `OwnerHQDashboardScreen` (primary + secondary from `DesignTokens`, labels)
- [x] Live app name on the same card via `DesignTokens.currentAppName` (accented with primaryColor, July 24)
- [x] Conditional logo via `DesignTokens.currentLogoUrl` when non-null (ClipRRect + adminCardRadius, July 24)
- [x] Swatch borders via `cardBorderColor` + caption labels via `secondaryTextColor` (July 24)
- [x] Palette icon on card title (July 24)
- [ ] Full HQ Design & Branding page (not just the preview card)

**Onboarding placement (Decision 7 — July 24, 2026):**

- [x] **Target documented**: Franchise/menu onboarding lives on **HQ Owner** dashboard, not Admin
- [x] **B-ONB-2** Onboarding progress card on `OwnerHQDashboardScreen` using real API only (`loading`, `getFoundationProgress()`, `isStepComplete` for ingredientTypes / ingredients / categories) — no invented `isOnboardingComplete` (July 24)
- [x] Loading state polished (Card + centered indicator + text; real DesignTokens only)
- [x] Foundation percent label from `getFoundationProgress()`
- [x] Completed vs Pending step line styles (primaryColor / secondaryTextColor)
- [x] LinearProgressIndicator colored with live `DesignTokens.primaryColor`
- [ ] Wire card → existing onboarding route/section (navigation CTA; Admin onboarding is sidebar-index based — no clean named route yet)
- [ ] Demote Admin primary onboarding entry after HQ entry works
- [ ] Reflect completed migration in DASHBOARDS.md / web-app README
- See `docs/DECISIONS.md` Decision 7 for full rationale and sequence

**Still open (product):**

- [ ] Full HQ Design & Branding dashboard + richer live preview
- [ ] Broader franchise-scoped config beyond branding colors (features, app config loaders)
- [ ] Onboarding navigation CTA from HQ card + Admin demotion
- [ ] Hybrid localization (partial)
- [ ] Next agent training frontier: **new surfaces** (not more HQ card micro-polish); controlled 3-file quote+comment only; train **No change needed** escape hatch

**Ground truth (do not regress):**

- Branding model exists at `packages/shared_core/lib/src/core/config/branding_config.dart`
- `FranchiseProvider` owns runtime branding; static config classes are defaults/fallbacks
- Never invent `FranchiseProvider()` zero-arg or `FirestoreService.collection(...)`
- Web live colors: `FranchiseProvider` → `DesignTokens.setFranchiseProvider` → `DesignTokens.*` getters
- Mobile live colors: `FranchiseProvider` → `UiConfig.setFranchiseProvider` → `UiConfig.*`
- Do not invent new fields on BrandingConfig / AppConfig / DesignTokens / FeatureConfig for scoping
- Onboarding home = HQ Owner (Decision 7); Admin is not the long-term home
- See also `orchestrator/SCOPE_CARD.md` for the short always-on constraint list

---

## Target workflow

1. Agent proposes (real source, strict `## BEFORE` / `## AFTER` fences) — interactive **or** `queue/inbox` drain  
2. Human reviews (`/approve <id>`, validation warnings / HARD BAN hits)  
3. `/approve confirm <id>` → local apply only  
4. Human commits/pushes  
5. Never Firestore/production from agents  
6. `/reject <id> reason=...` → `orchestrator/feedback/rejects.jsonl` (governance learning only)
7. HARD BAN / path-allowlist → auto-reject (`status=rejected`, no apply)

Prompt style: see **AGENT_SYSTEM.md → Preferred Coding Task Prompt Style**.  
Interactive CLI: paste multi-line task, type `END` on its own line.  
Overnight: drop tasks in `orchestrator/queue/inbox/` → `python queue_runner.py --drain`.

---

## Hard Rules

- Propose first; apply only after `/approve confirm`
- Apply = local files only — not push
- Queue never auto-applies
- `shared_core` source of truth; franchise-scoped data paths
- Stay in current phase acceptance criteria
- Never invent fields on BrandingConfig / AppConfig / DesignTokens / FeatureConfig for scoping work
- Never invent FirestoreService.collection or zero-arg FranchiseProvider()
- Treat validator HARD BAN hits as reject candidates (now auto-rejected)
- Edit only files named in the task (path allowlist)
- If region already satisfies the request → **No change needed** (do not emit identical BEFORE/AFTER)

---

**Update this file after significant sessions.**
