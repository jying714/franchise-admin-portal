# Phase 0: Infrastructure & Documentation

**Status**: Not Started  
**Estimated Duration**: 1–3 days (upon hardware arrival)  
**Owner**: Human (with agent support)

## Goals
Prepare the local multi-agent AI system, governance, and foundational documentation so that subsequent phases can be executed safely and efficiently.

## Acceptance Criteria
- Docker Compose + Ollama + LangGraph environment fully operational with Orchestrator and specialized agents.
- `AGENT_SYSTEM.md` created and all agents reference it.
- `ARCHITECTURE.md` expanded with Firestore schema design, localization strategy, multi-agent orchestration, and Risk Register.
- Per-phase task files created (`tasks/Phase0.md`, `tasks/Phase1.md`, etc.) with clear boundaries.
- Weekly & PR review templates established and tested.
- Basic test agent run completed with successful PR and human review.
- Ollama models pulled and tested (e.g., 7B–9B and 14B coding models).
- Small safe test task completed in `shared_core` (e.g., minor refactor) with full human review.

## Defensive Items
- Firestore schema design started (naming conventions, indexing strategy, migration plan).
- Basic testing/seed data strategy defined.
- Risk register reviewed and updated.
- Localization hybrid strategy documented.

## Key Tasks
1. Set up Docker multi-agent environment + Ollama + LangGraph.
2. Pull and test core models (7B–14B range).
3. Create `AGENT_SYSTEM.md` with strict rules.
4. Expand core documentation (`ARCHITECTURE.md`, `DASHBOARDS.md`, `MOBILE_DYNAMIC.md`).
5. Create task file template and weekly/PR templates.
6. Run a small, safe test task in `shared_core` and perform full human review.
7. Validate agent coordination and scope control.

## Human Involvement Required
- Review and approve `AGENT_SYSTEM.md`.
- Approve final Phase 0 completion before moving to Phase 1.
- Review all architecture and config-related decisions.

## Risks
- Agent setup instability.
- Scope creep into Phase 1 work.
- Model performance lower than expected.

**Approval Required to Exit Phase**: Human sign-off after successful test task and documentation review.