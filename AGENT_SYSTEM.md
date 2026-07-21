# AGENT_SYSTEM.md
**Multi-Agent AI Development System**  
**Doughboys Pizzeria Franchise Platform**  
**Last Updated**: July 20, 2026

## Purpose
This document defines the governance, roles, rules, and workflows for the 24/7 local multi-agent AI coding system running on the MINISFORUM AI X1 Pro-470.

The goal is to accelerate development **safely** while maintaining strict scope control, code integrity, and human oversight.

## Core Principles (Non-Negotiable)
- All agent work must stay **strictly** within the current phase acceptance criteria (see ROADMAP.md and tasks/PhaseX.md).
- Human review is **mandatory** on architecture, config changes, Firestore schema, design/branding, payments, security, and any major refactors.
- No direct Firestore writes or major production changes by agents without explicit human approval.
- Agents must immediately flag any potential scope creep.
- Weekly resets are mandatory.

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
- Escalate to 30–35B MoE only for complex architecture, deep refactors, or when confidence is low.
- Always consider current RAM load and context size.

## Tool Restrictions (Critical)
- No direct writes to Firestore, production code, or major config files.
- Agents propose changes → human reviews → merge via PR.
- Limited to reading files, suggesting edits, running local tests, and creating PR drafts.

## Mandatory Reference Rules (All Agents)
At the beginning of every task or session, every agent **must** first read the following files:

**Core Governance & Roadmap**:
- `/AGENT_SYSTEM.md`
- `/ROADMAP.md`
- `/tasks/PhaseX.md` (current phase)

**Project Documentation**:
- `/ARCHITECTURE.md`
- `/docs/architecture/firestore-per-franchise-config.md`   ← **New: Authoritative config & Firestore schema reference**
- `/DASHBOARDS.md`
- `/MOBILE_DYNAMIC.md`
- `/docs/comprehensive-project-analysis.md`

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

## File Structure Overview
- `AGENT_SYSTEM.md` — This governance document
- `prompts/` — Individual agent prompts
- `tasks/PhaseX.md` — Per-phase detailed tasks
- `ROADMAP.md` — High-level plan

## Risk Mitigation
- Scope creep
- Agent hallucination on code changes
- Inconsistent state management
- Firestore schema debt
- Localization complexity

**All agents must reference this document at the start of every session.**

**Human (Project Owner) retains final authority on all decisions.**