# Phase 1: Agent Hardening → Core Config Scoping & Dynamic Branding

**Status**: In Progress  
**Estimated Duration**: Agent hardening 1–2 days, then product 3–5 days  
**Owner**: Human (with agent support)  
**Last Updated**: July 23, 2026

## Goals

1. **First**: Make agents reliable enough for precise, reviewable code proposals on real `shared_core` source.
2. **Then**: Make shared_core configs fully franchise-scoped and dynamic, with runtime theming/branding + HQ live preview.

---

## Workstream A — Agent hardening (do this first)

**Why**: Phase 0 proved agents can load and quote real files. They still fail on tight “only change X” instructions (over-refusal or inventing fields). Product tickets will fail the same way until this is fixed.

### Acceptance criteria (Workstream A)

- [ ] Safe docstring/comment-only edits no longer over-refuse when the change is clearly harmless.
- [ ] Natural constrained prompts preferred over ultra-rigid copy-paste-only prompts in agent task guidance.
- [ ] Optional guard: if the task forbids new fields and the proposal adds `final …` / new properties, flag or reject before showing as success.
- [ ] **Prove**: one clean, human-approved docstring or comment improvement on real `packages/shared_core/...` source (agent proposal matches real file; human merges).
- [ ] (Optional) Pull and A/B test another local coding model (e.g. `deepseek-coder-v2`) for edit tasks.
- [ ] Update `STATUS.md` when Workstream A is done.

### Tickets (A)

| ID | Task | Owner | Notes |
|----|------|-------|-------|
| A1 | Soften refuse path in edit-mode prompts — allow class-level docstrings/comments when source is present and task asks only for that | Human + orchestrator prompt tweak | Avoid “I cannot apply safely” on pure docstring adds |
| A2 | Document preferred task style for coding agents (natural + constrained, always include file path) in `AGENT_SYSTEM.md` or orchestrator README | Human / agent proposal | |
| A3 | Optional proposal validator for “no new fields” tasks | Orchestrator | Lightweight string/heuristic check is enough for now |
| A4 | Run one end-to-end docstring/comment test on `user.dart` (or similar); human reviews and merges | Human | Phase 0 tiny-test, redone correctly |
| A5 | (Optional) Model comparison on the same edit task | Human | Only if A1–A4 still weak |

**Do not start Workstream B product tickets until A4 is merged.**

---

## Workstream B — Product (after A)

### Acceptance criteria (Workstream B)

- [ ] Config files (`design_tokens`, `app_config`, `branding_config`, `feature_config`, `ui_config`) franchise-scoped in Firestore per `docs/architecture/firestore-per-franchise-config.md`.
- [ ] Configs owned in `shared_core` and consumed by web + mobile.
- [ ] Runtime theming/branding with live preview in HQ Owner dashboard.
- [ ] Design & Branding page with live preview functional.
- [ ] Hybrid localization (hardcoded base + DB overrides) documented and partially implemented.
- [ ] Full human review on architecture decisions and device testing.

### Key product tasks (B)

1. Audit current config files in `shared_core`.
2. Design/implement franchise-scoped config structure in Firestore.
3. Update providers/services to load configs dynamically.
4. Implement runtime theming/branding system.
5. Build Design & Branding page in HQ Owner dashboard with live preview.
6. Document and begin hybrid localization strategy.
7. Integration tests on web and mobile.
8. Human review and Phase 1 exit approval.

### Defensive items

- Schema migration plan for existing data documented.
- No breaking mobile changes without testing.
- Human approval required for all config schema and Firestore structure decisions.

### Risks

- Agent edit drift if Workstream A is skipped.
- Firestore migration complexity.
- Theming inconsistencies web vs mobile.
- Scope creep into Phase 2 (hybrid location logic).

---

## Human involvement

- Approve all Workstream A prompt/validator changes before relying on them.
- Merge the proving docstring/comment PR (A4).
- Approve final config schema and Firestore structure (B).
- Review Design & Branding UI/UX.
- Sign off Phase 1 completion before Phase 2.

**Approval required to exit Phase 1**: Human sign-off after A proven and B reviewed/tested.
