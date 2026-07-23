# STATUS.md — Live Project Snapshot

**Last Updated**: July 23, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent.  
> Keep it short, factual, and current. Update it at the end of every significant session.

---

## Current Phase

**Phase 1 – Agent Hardening → Core Config Scoping & Dynamic Branding**

Phase 0 is **complete** (exited July 23, 2026).

### Phase 0 — Done

- [x] Docker + Ollama + Orchestrator operational
- [x] Models: `qwen2.5-coder:7b` + `qwen2.5-coder:14b`
- [x] Mandatory docs, routing, human-approval gates
- [x] Proposal-only safety
- [x] Real source-file loading + minimal-context edit mode
- [x] Human Phase 0 exit sign-off

---

## Phase 1 — Active workstreams

### A. Agent hardening

- [x] **A1** Soften over-refusal on safe docstring/comment-only edits
- [x] **A4** One clean docstring on real `shared_core` source — human merged  
  (`packages/shared_core/lib/src/core/models/user.dart` class-level docstring)
- [ ] **A2** Preferred coding-task prompt style documented
- [ ] **A3** Optional post-check: flag proposals that add fields when task forbade them
- [ ] **A5** (Optional) Model A/B for edit quality
- [ ] Reduce residual scope drift (agent still sometimes adds extra comments beyond “ONLY class docstring”)
- [ ] Design gated **approve-to-apply** flow (proposal → human review → explicit approve → apply patch locally; push still human or second gate)

### B. Product (after remaining A items that block quality)

- [ ] Franchise-scoped config per `firestore-per-franchise-config.md`
- [ ] HQ Owner Design & Branding + live preview
- [ ] Hybrid localization (partial)

See `tasks/Phase1.md`.

---

## Target agent workflow (goal)

1. Agent produces a **proposal** (exact before/after or unified diff) from real source  
2. Human **reviews** (CLI / PR)  
3. Human **approves apply** explicitly  
4. Orchestrator applies the approved patch **locally** (and optionally commits)  
5. **Push / remote PR** remains human-controlled or a separate explicit gate  

Agents still never write Firestore or production systems.

---

## Higher-Level Project State

- P1 / P2 / P2.5 — COMPLETE
- `shared_core` single source of truth
- Franchise-scoped Firestore config is the law
- Hybrid location + dynamic branding direction locked

---

## Hard Rules

- Propose first; apply only after explicit human approval (once apply-gate exists)
- No Firestore / production writes from agents
- `shared_core` is source of truth; data under `franchises/{franchiseId}/...`
- Stay inside current phase acceptance criteria

---

**How to update**: edit checkboxes + Last Updated after each significant session. Keep under ~100 lines.
