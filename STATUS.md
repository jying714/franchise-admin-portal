# STATUS.md — Live Project Snapshot

**Last Updated**: July 22, 2026 (evening)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent.  
> Keep it short, factual, and current. Update it at the end of every significant session.

---

## Current Phase

**Phase 0 – Infrastructure & Documentation** (in progress)

### What is already done (as of July 22, 2026)

- [x] Docker Compose + Ollama running 24/7 on the MINISFORUM
- [x] Multi-agent Orchestrator container operational (`franchise-orchestrator`)
- [x] Models pulled and verified: `qwen2.5-coder:7b` + `qwen2.5-coder:14b`
- [x] Orchestrator loads all mandatory governance documents on every task
- [x] Agent routing + human-approval gates implemented
- [x] Interactive CLI working (`docker exec -it franchise-orchestrator python main.py`)
- [x] Proposal-only safety (agents never write files or Firestore)
- [x] Core documentation already present and substantial:
  - `AGENT_SYSTEM.md`
  - `ARCHITECTURE.md`
  - `ROADMAP.md`
  - `HANDOFF.md`
  - `docs/architecture/firestore-per-franchise-config.md`
  - `docs/DASHBOARDS.md`, `docs/MOBILE_DYNAMIC.md`, `docs/CONTRIBUTING.md`, etc.
  - `tasks/Phase0.md` + `tasks/README.md`
  - All package/app READMEs

### What is still open in Phase 0

- [ ] Improve agent context quality (this STATUS.md is the first step)
- [ ] Expand `ARCHITECTURE.md` with any remaining Risk Register / localization details if needed
- [ ] Create simple weekly + PR review templates (if not already present)
- [ ] Run one tiny, safe, fully human-reviewed test task in `shared_core` (e.g. comment or docstring cleanup)
- [ ] Human sign-off that Phase 0 exit criteria are met

---

## Higher-Level Project State

- **P1** (Core Ordering Flow) — COMPLETE
- **P2** (White-Label & Scalability) — COMPLETE
- **P2.5** (Web-App Cleanup) — COMPLETE
- Config unification complete (`shared_core` is single source of truth)
- Franchise-scoped Firestore config architecture is the law (`firestore-per-franchise-config.md`)
- Hybrid single/multi-location foundations in place
- Dynamic branding / FeatureGate direction is locked

---

## Active Priorities (in order)

1. Finish remaining Phase 0 items above (documentation polish + one safe test task)
2. Human Phase 0 exit approval
3. Begin Phase 1 – full dynamic config rollout + Design & Branding live preview

---

## Hard Rules Agents Must Never Forget

- `shared_core` is the single source of truth
- Everything customer-related lives under `franchises/{franchiseId}/...`
- Hybrid single/multi-location logic is mandatory
- Dynamic config / branding / UI is mandatory
- Agents produce **proposals only** — never apply changes themselves
- Human review is required for architecture, config, schema, payments, security, branding
- Stay strictly inside the current phase acceptance criteria

---

**How to update this file**  
At the end of any session that changes the real state of the project, edit the checkboxes and the “Last Updated” line. Keep it under ~80 lines.
