# STATUS.md — Live Project Snapshot

**Last Updated**: July 23, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 – Agent Hardening → Core Config Scoping & Dynamic Branding**

Phase 0 complete (July 23, 2026).

### A. Agent hardening

- [x] **A1** Soften over-refusal on docstring/comment-only edits
- [x] **A4** Human-merged class docstring on `user.dart`
- [x] **A3** Proposal validator (flags new fields/methods when task forbade them)
- [x] **Approve-to-apply skeleton** — save proposal; `/approve` → `/approve confirm` applies **locally only** (no git push)
- [ ] **A2** Preferred coding-task prompt style documented
- [ ] **A5** (Optional) Model A/B
- [ ] Reduce residual scope drift further (validator helps; prompts still improve)
- [ ] Harden apply: structured patches / unified diffs for more reliable before→after

### B. Product (after A quality is steady)

- [ ] Franchise-scoped config
- [ ] HQ Design & Branding + live preview
- [ ] Hybrid localization (partial)

---

## Target workflow

1. Agent proposes (real source)  
2. Human reviews (CLI; warnings from A3)  
3. `/approve` then `/approve confirm` → **local apply only**  
4. Human commits/pushes (or future second gate)  
5. Never Firestore/production from agents  

Commands: `/approve` `/approve confirm` `/reject` `/proposals`

---

## Hard Rules

- Propose first; apply only after explicit `/approve confirm`
- Apply = local files only — not push
- `shared_core` source of truth; franchise-scoped data paths
- Stay in current phase acceptance criteria

---

**Update this file after significant sessions.**
