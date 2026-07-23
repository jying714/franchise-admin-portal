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
- [x] **A3** Proposal validator (field/method drift warnings)
- [x] **Approve-to-apply skeleton** + `/approve <id>` / `/approve confirm <id>`
- [x] **A2** Preferred coding-task prompt style documented (`AGENT_SYSTEM.md` + `orchestrator/README.md`)
- [x] End-to-end proof: address.dart docstring proposed → reviewed by id → local apply succeeded
- [ ] **A5** (Optional) Model A/B
- [ ] Structured unified-diff proposals (more reliable apply)
- [ ] Optional: don’t persist empty/junk proposals

### B. Product (when A quality feels steady)

- [ ] Franchise-scoped config
- [ ] HQ Design & Branding + live preview
- [ ] Hybrid localization (partial)

---

## Target workflow

1. Agent proposes (real source)  
2. Human reviews (`/approve <id>`, validation warnings)  
3. `/approve confirm <id>` → local apply only  
4. Human commits/pushes  
5. Never Firestore/production from agents  

Prompt style: see **AGENT_SYSTEM.md → Preferred Coding Task Prompt Style**.

---

## Hard Rules

- Propose first; apply only after `/approve confirm`
- Apply = local files only — not push
- `shared_core` source of truth; franchise-scoped data paths
- Stay in current phase acceptance criteria

---

**Update this file after significant sessions.**
