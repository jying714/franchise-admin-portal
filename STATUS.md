# STATUS.md — Live Project Snapshot

**Last Updated**: July 23, 2026 (early morning)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent.  
> Keep it short, factual, and current. Update it at the end of every significant session.

---

## Current Phase

**Phase 1 – Agent Hardening → Core Config Scoping & Dynamic Branding**

Phase 0 (Infrastructure & Documentation) is **complete** as of July 23, 2026.

### Phase 0 — Done

- [x] Docker Compose + Ollama running 24/7 on the MINISFORUM
- [x] Multi-agent Orchestrator container operational (`franchise-orchestrator`)
- [x] Models pulled and verified: `qwen2.5-coder:7b` + `qwen2.5-coder:14b`
- [x] Orchestrator loads mandatory governance documents on every task
- [x] Agent routing + human-approval gates implemented
- [x] Interactive CLI working
- [x] Proposal-only safety (agents never write files or Firestore)
- [x] `STATUS.md` live snapshot used by agents
- [x] Real source-file loading (`file_reader.py`) — agents can quote real Dart code
- [x] Minimal-context mode for source-file edits + 14b→7b OOM fallback
- [x] Core documentation present (AGENT_SYSTEM, ARCHITECTURE, ROADMAP, HANDOFF, firestore-per-franchise-config, etc.)
- [x] `tasks/Phase0.md` + `tasks/README.md`
- [x] Human Phase 0 exit sign-off (July 23, 2026)

---

## Phase 1 — Active workstreams (in order)

### A. Agent hardening (must complete before product coding tickets)

- [x] **A1** Soften over-refusal on safe docstring/comment-only edits *(pushed July 23 — retest pending)*
- [ ] Prefer natural constrained tasks over ultra-rigid copy-paste prompts
- [ ] Optional post-generation check: reject proposals that add fields when the task forbade them
- [ ] **Prove**: one clean, human-approved docstring or comment improvement on real `shared_core` source
- [ ] (Optional) Evaluate `deepseek-coder-v2` or other local models for edit tasks

### B. Product (after A)

- [ ] Franchise-scoped config rollout per `firestore-per-franchise-config.md`
- [ ] HQ Owner Design & Branding dashboard with live preview
- [ ] Hybrid localization (hardcoded base + DB overrides) — partial

See `tasks/Phase1.md` for full acceptance criteria and tickets.

---

## Higher-Level Project State

- **P1** (Core Ordering Flow) — COMPLETE
- **P2** (White-Label & Scalability) — COMPLETE
- **P2.5** (Web-App Cleanup) — COMPLETE
- Config unification complete (`shared_core` is single source of truth)
- Franchise-scoped Firestore config architecture is the law
- Hybrid single/multi-location foundations in place
- Dynamic branding / FeatureGate direction is locked

---

## Hard Rules Agents Must Never Forget

- `shared_core` is the single source of truth
- Everything customer-related lives under `franchises/{franchiseId}/...`
- Hybrid single/multi-location logic is mandatory
- Dynamic config / branding / UI is mandatory
- Agents produce **proposals only** — never apply changes themselves
- Human review is required for architecture, config, schema, payments, security, branding
- Stay strictly inside the current phase acceptance criteria
- Docstring/comment-only edits are SAFE when requested — do not refuse them

---

**How to update this file**  
At the end of any session that changes the real state of the project, edit the checkboxes and the “Last Updated” line. Keep it under ~100 lines.
