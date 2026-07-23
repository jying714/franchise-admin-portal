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
- [ ] **A5** (Optional) Model A/B
- [ ] Structured unified-diff proposals (optional; fences now work for docstring/comment applies)
- [ ] Optional: don’t persist empty/junk proposals

### B. Product — Core config scoping & dynamic branding

**Documentation foundation (done this session, no logic changes):**

- [x] `branding_config.dart` — class docstring: static defaults, Phase 1 Workstream B owns scoping
- [x] `app_config.dart` — class docstring + `AppConfig.current` comment points at FranchiseProvider surface
- [x] `design_tokens.dart` — class docstring: static defaults, dynamic theming = Workstream B
- [x] `feature_config.dart` — class docstring: static defaults + apply() path, scoping = Workstream B
- [x] `franchise_provider.dart` — class docstring: runtime owner of franchise-scoped branding/config
- [x] `setBrandingFromFranchiseDoc` — documented keys already read by existing getters

**Still open:**

- [ ] Franchise-scoped config wiring (first real code changes)
- [ ] HQ Design & Branding + live preview
- [ ] Hybrid localization (partial)

**Ground truth (do not regress):**

- Branding model already exists at `packages/shared_core/lib/src/core/config/branding_config.dart`
- `FranchiseProvider` already has branding getters + `setBrandingFromFranchiseDoc`
- Static config classes are defaults/fallbacks; do not invent new fields on them for scoping
- Next work is wiring/loading paths, not new schema on the static classes

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

---

**Update this file after significant sessions.**
