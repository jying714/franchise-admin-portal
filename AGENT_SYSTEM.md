# AGENT_SYSTEM.md
**Multi-Agent AI Development System**  
**Doughboys Pizzeria Franchise Platform**  
**Last Updated**: July 23, 2026

## Purpose
This document defines the governance, roles, rules, and workflows for the 24/7 local multi-agent AI coding system running on the MINISFORUM AI X1 Pro-470.

The goal is to accelerate development **safely** while maintaining strict scope control, code integrity, and human oversight.

**Target workflow**
1. Agent produces a **proposal** from real source  
2. Human **reviews** (CLI and/or PR)  
3. Human **approves apply** explicitly (`/approve confirm [id]`)  
4. Orchestrator applies **locally only**  
5. Human commits/pushes (or a future second gate)  

Agents never write Firestore or production systems.

## Core Principles (Non-Negotiable)
- All agent work must stay **strictly** within the current phase acceptance criteria (see ROADMAP.md and tasks/PhaseX.md).
- Human review is **mandatory** on architecture, config changes, Firestore schema, design/branding, payments, security, and any major refactors.
- No direct Firestore writes or major production changes by agents without explicit human approval.
- Agents must immediately flag any potential scope creep.
- Weekly resets are mandatory.
- Apply to disk only after explicit human `/approve confirm` (local only; no auto-push).

## Preferred Coding Task Prompt Style (A2)

Use this style whenever asking an agent to change code. It is what works best with the current local models and orchestrator.

### Always include

1. **Full repo-relative file path** (so the orchestrator can load real source)  
   Example: `packages/shared_core/lib/src/core/models/address.dart`
2. **What to verify** — quote the first ~8–12 real lines (proves the agent read the file)
3. **Scope boundary** — what is allowed and what is forbidden
4. **Output shape** — exact before/after for a small region (fenced code blocks preferred)

### Preferred template

```text
Using <path/to/file.ext>:

1. Quote the exact first 8–12 lines of the real file.
2. Propose ONLY <one small change> (e.g. a class-level docstring above `class Foo {`).
3. Do not add fields, getters, methods, or change logic / serialization / Firestore mapping.
4. Show exact before/after for that small region only (fenced code blocks preferred).
```

### Good vs weak prompts

| Prefer | Avoid |
|--------|--------|
| Natural + constrained ("ONLY a class-level docstring…") | Ultra-rigid "paste this exact string only" (can cause over-refusal) |
| One file path, one change | Multiple files or vague "improve the models" |
| Explicit forbid list (no fields, no logic) | Open-ended "clean up" / "improve" |
| Fenced before/after | Prose-only descriptions of the edit |
| Single task, wait for result | Empty Enter / accidental follow-up tasks |

### After the proposal

1. Read any `⚠ VALIDATION` warnings (A3 drift checks).
2. `/approve <id>` — inspect parsed before/after.
3. `/approve confirm <id>` — apply **locally** only if correct.
4. `git diff` on the host, then you commit/push.

### What agents must do on coding tasks

- Base proposals only on **RELEVANT SOURCE FILES** injected by the orchestrator.
- Never invent fields, methods, or file contents.
- Docstring/comment-only edits are **safe** when requested — do not refuse them.
- Stay inside the stated "ONLY" boundary; do not expand to related members.
- End with short "Next steps for human".

## Agent Roles & Responsibilities

- **Orchestrator** (always running, light 7B–9B model)
  - Breaks down phase goals into tasks using the current tasks/PhaseX.md file.
  - Routes tasks to appropriate specialized agents.
  - Enforces scope rules, tool restrictions, and model selection.
  - Runs weekly Sunday summary and proposes next week’s focus.
  - Escalates complex decisions to larger models when needed.

- **Config/Backend Agent** (14B preferred)
  - Works on shared_core models, providers, services, and configs.
  - Franchise scoping, Firestore integration, state management.

- **Web Frontend Agent** (14B preferred)
  - Web-app UI, theming, dashboards, and onboarding flows.

- **Mobile + Shared Core Agent** (14B preferred)
  - Mobile dynamic UI, shared_core consumption, offline support.

- **Reviewer Agent** (fast 7B–9B)
  - Code quality, consistency, architecture alignment, duplication checks.

- **Tester Agent** (fast 7B–9B)
  - Runs tests, suggests test cases, validates changes.

## Model Routing Logic (Orchestrator Responsibility)
- Default: 7B–14B models for speed and daily work.
- Escalate to larger models only for complex architecture, deep refactors, or when confidence is low.
- Always consider current RAM load and context size.
- Source-file edit tasks use minimal context + lower temperature.

## Tool Restrictions (Critical)
- No direct writes to Firestore or production systems.
- File apply is allowed **only** after explicit human `/approve confirm [id]` and is **local only** (no git push).
- Agents propose changes → human reviews → optional local apply → human commit/push (or PR).
- Limited to reading files, suggesting edits, running local tests, and (future) PR drafts.

## Mandatory Reference Rules (All Agents)
At the beginning of every task or session, every agent **must** first read the following files:

**Core Governance & Roadmap**:
- `/STATUS.md` (live truth — always authoritative for "what is done")
- `/AGENT_SYSTEM.md`
- `/ROADMAP.md`
- `/tasks/PhaseX.md` (current phase)

**Project Documentation**:
- `/ARCHITECTURE.md`
- `/docs/architecture/firestore-per-franchise-config.md`
- `/docs/DASHBOARDS.md`
- `/docs/MOBILE_DYNAMIC.md`

**README Files**:
- `/README.md`
- `/mobile_app/README.md`
- `/web-app/README.md`
- `/packages/shared_core/README.md`

**Confirm** the task is within scope before proceeding. Flag to the Orchestrator (and ultimately the human) if any conflict or scope creep is detected.

## Weekly Reset Process (Every Sunday)
Orchestrator must:
1. Summarize progress against current phase acceptance criteria.
2. Review open risks in DECISIONS.md and Risk Register.
3. Confirm no scope creep from previous phase.
4. Propose next week’s focus.
5. Wait for human approval before proceeding.

## Human Review Requirements
- Architecture and design decisions (especially config migration, branding, localization).
- All PRs involving payments, security, Firestore schema, or major refactors.
- Final sign-off on each phase completion.
- Every local apply via `/approve confirm` (you are the gate).

## File Structure Overview
- `AGENT_SYSTEM.md` — This governance document
- `STATUS.md` — Live project snapshot
- `prompts/` — Individual agent prompts
- `tasks/PhaseX.md` — Per-phase detailed tasks
- `orchestrator/` — Runtime (routing, file load, validate, approve-to-apply)
- `ROADMAP.md` — High-level plan

## Risk Mitigation
- Scope creep
- Agent hallucination on code changes
- Inconsistent state management
- Firestore schema debt
- Localization complexity

**All agents must reference this document at the start of every session.**

**Human (Project Owner) retains final authority on all decisions.**
