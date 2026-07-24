# Phase 1: Agent Hardening → Core Config Scoping & Dynamic Branding

**Status**: In Progress  
**Estimated Duration**: Agent hardening 1–2 days, then product 3–5 days  
**Owner**: Human (with agent support)  
**Last Updated**: July 24, 2026

## Goals

1. **First**: Make agents reliable enough for precise, reviewable code proposals on real `shared_core` source.
2. **Then**: Make shared_core configs fully franchise-scoped and dynamic, with runtime theming/branding + HQ live preview.

---

## Workstream A — Agent hardening (do this first)

**Why**: Phase 0 proved agents can load and quote real files. They still fail on tight “only change X” instructions (over-refusal or inventing fields). Product tickets will fail the same way until this is fixed.

### Acceptance criteria (Workstream A)

- [x] Safe docstring/comment-only edits no longer over-refuse when the change is clearly harmless.
- [x] Natural constrained prompts preferred over ultra-rigid copy-paste-only prompts in agent task guidance.
- [x] Optional guard: if the task forbids new fields and the proposal adds `final …` / new properties, flag or reject before showing as success.
- [x] **Prove**: one clean, human-approved docstring or comment improvement on real `packages/shared_core/...` source (agent proposal matches real file; human merges).
- [x] SCOPE_CARD + hard bans + 2-file Stage-C process reliable on live-branding path.
- [ ] (Optional) Pull and A/B test another local coding model for edit tasks.
- [ ] 3-file Stage-C reliable without timeout/format collapse.
- [ ] Update `STATUS.md` when Workstream A is done.

### Tickets (A)

| ID | Task | Owner | Notes |
|----|------|-------|-------|
| A1 | Soften refuse path in edit-mode prompts — allow class-level docstrings/comments when source is present and task asks only for that | Human + orchestrator prompt tweak | Done |
| A2 | Document preferred task style for coding agents in `AGENT_SYSTEM.md` / orchestrator README | Human / agent proposal | Done |
| A3 | Optional proposal validator for “no new fields” tasks | Orchestrator | Done + hard bans |
| A4 | Run one end-to-end docstring/comment test; human reviews and merges | Human | Done |
| A5 | (Optional) Model comparison on the same edit task | Human | Only if needed |
| A6 | Multi-file quote discipline (2-file proven; 3-file still open) | Human + training | In progress |

---

## Workstream B — Product (after A)

### Acceptance criteria (Workstream B)

- [ ] Config files (`design_tokens`, `app_config`, `branding_config`, `feature_config`, `ui_config`) franchise-scoped in Firestore per `docs/architecture/firestore-per-franchise-config.md`.
- [x] Configs owned in `shared_core` and consumed by web + mobile.
- [x] Runtime theming/branding with live preview card in HQ Owner dashboard (colors + app name path).
- [ ] Design & Branding page with full live preview functional.
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

### Onboarding migration (Decision 7 — tracked here)

Franchise/menu onboarding must move to **HQ Owner** dashboard (not remain primarily on Admin).

| ID | Task | Owner | Notes |
|----|------|-------|-------|
| B-ONB-1 | Read-only audit: how Admin launches onboarding + `OnboardingProgressProvider` surface | Human + agent | Quote real source first |
| B-ONB-2 | Add conditional Onboarding progress tile on `OwnerHQDashboardScreen` (incomplete only) | Agent proposal → human | Reuse existing progress state |
| B-ONB-3 | Wire tile navigation to existing onboarding screens/routes | Agent proposal → human | Do not rewrite step UIs |
| B-ONB-4 | Demote Admin primary onboarding entry; update DASHBOARDS / web-app README / STATUS | Human | After HQ entry works |

**Reference**: `docs/DECISIONS.md` Decision 7, `docs/DASHBOARDS.md`.

### Defensive items

- Schema migration plan for existing data documented.
- No breaking mobile changes without testing.
- Human approval required for all config schema and Firestore structure decisions.
- Onboarding migration is surgical (tile + navigation), not a second onboarding system.

### Risks

- Agent edit drift if Workstream A is skipped.
- Firestore migration complexity.
- Theming inconsistencies web vs mobile.
- Scope creep into Phase 2 (hybrid location logic).
- Large-file / multi-file agent timeouts on `main.dart` and 3-file tasks.

---

## Human involvement

- Approve all Workstream A prompt/validator changes before relying on them.
- Merge the proving docstring/comment PR (A4).
- Approve final config schema and Firestore structure (B).
- Review Design & Branding UI/UX.
- Approve onboarding tile design and Admin demotion (B-ONB-*).
- Sign off Phase 1 completion before Phase 2.

**Approval required to exit Phase 1**: Human sign-off after A proven and B reviewed/tested.
