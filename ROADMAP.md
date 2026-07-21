# Doughboys Pizzeria Franchise Platform — Roadmap

**Last Updated**: July 20, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (64GB RAM + 1TB SSD)  
**Current Phase**: Phase 0 – Infrastructure & Documentation

## Vision
Build a scalable, multi-tenant white-label Flutter platform that allows any restaurant/franchise to launch a fully branded ordering system (web + mobile) rapidly and cost-effectively. Use AI-accelerated development and shared architecture to undercut competitors.

---

## Completed Phases

**P1 – Core Ordering Flow Stabilization** (Completed May 2026)  
**P2 – White-Label & Scalability** (Completed June 2026)  
**P2.5 – Web-App Cleanup Sprint** (Completed June 2026)

### Key Achievements
- Auth handoff and persistent spinner resolved
- FranchiseProvider + shared_core unification complete
- Large-scale cleanup of duplicated code, models, and UI issues
- `hq_owner` dashboard functional with correct franchise resolution
- Core ordering flow stable on Samsung S25

---

## Current & Upcoming Phases

### Phase 0: Infrastructure & Documentation (1–3 days)
**Goals**: Prepare the local multi-agent AI system, governance, and foundational documentation.

**Acceptance Criteria**:
- Docker Compose + Ollama + LangGraph environment fully operational with Orchestrator and specialized agents.
- `AGENT_SYSTEM.md` created with strict scoping rules, tool restrictions, human approval gates, and weekly reset process.
- `ARCHITECTURE.md` expanded with Firestore schema design, localization strategy, multi-agent orchestration, and risks section.
- **`/docs/architecture/firestore-per-franchise-config.md`** created as the authoritative reference for all config and Firestore decisions (schema, migration, security rules, provider updates).
- Per-phase task files (`tasks/Phase0.md`, `tasks/Phase1.md`, etc.) created with clear boundaries and acceptance criteria.
- Weekly & PR review templates established.
- Basic test agent run completed with successful PR and human review.
- Ollama models pulled and tested (e.g., 7B and 14B coding models).

**Defensive Items**:
- Firestore schema design started (naming, indexing, migration plan).
- Basic testing/seed data strategy defined.
- Risk register for potential refactors (localization, state management).

### Phase 1: Core Config Scoping & Dynamic Branding (3–5 days)
**Goals**: Make shared_core configs fully franchise-scoped and dynamic via Firestore.

**Acceptance Criteria** (Non-Negotiable):
- All config files (`design_tokens`, `app_config`, `branding_config`, `feature_config`, `ui_config`) updated to be franchise-scoped in Firestore per `/docs/architecture/firestore-per-franchise-config.md`.
- `FranchiseProvider` listens to and merges `config/ui_config`, `config/app_config`, and `config/features`.
- Runtime theming/branding system implemented with live preview in owner_hq dashboard.
- Design & Branding page with live preview functional.
- Hybrid localization strategy (hardcoded base + DB overrides) documented and partially implemented.
- Full human review on architecture decisions and testing on real devices.
- No breaking changes to mobile app without testing.

**Defensive Items**:
- Schema migration plan for existing data.
- Strong defaults in `shared_core` with Firestore overrides.

### Phase 2: Hybrid Single/Multi-Location + Dashboards (5–7 days)
**Goals**: Full hybrid support.

**Acceptance Criteria**:
- Automatic UI simplification for single-location.
- Location switching on mobile and web.
- Primary/secondary location rules.
- Role-based dashboard navigation.
- Full human review and device testing.

### Phase 3: Mobile Multi-Tenant Polish & Roles (4–6 days)
**Goals**: Fully dynamic mobile app.

**Acceptance Criteria**:
- Remove pizzeria hardcoding → config-driven UI for any restaurant type.
- Deep linking, invite flows, offline support.
- Granular staff roles and invitations.
- iOS testing on iPhone 15.
- Full human review.

### Phase 4: Monetization, Analytics & Polish (5–7 days)
**Goals**: Revenue-ready.

**Acceptance Criteria**:
- Stripe integration + tiered plans (Starter, Starter Advanced, Growth).
- Analytics dashboards + CSV/PDF exports.
- Feature gating.
- Error management in Developer dashboard.
- Full human review on payments/security.

### Phase 5: Assisted Onboarding, POS Prep, Legal & Release (3–5 days)
**Goals**: Launch-ready.

**Acceptance Criteria**:
- AI-assisted onboarding flows.
- Printer/terminal abstractions for future POS.
- Basic ToS/Privacy Policy.
- Final testing and App Store readiness.
- Full human review.

---

## Post-MVP Phases (High-Level)
**P4 – Scale & Marketplace** (Q3 2026)  
**P5 – Enterprise & Expansion** (Q4 2026+)

## Success Criteria for Polished MVP
- Hybrid single/multi-location works seamlessly
- Mobile UI fully dynamic across restaurant types
- Design management via HQ Owner dashboard with live preview
- Stripe payments and feature gating functional
- Clean, well-documented architecture with strong agent governance and human-readable code

## Weekly Focus & Review Process
Every Sunday the Orchestrator will:
- Summarize progress against the current phase acceptance criteria.
- Flag any scope creep or risks.
- Review open risks in `DECISIONS.md` and Risk Register.
- Confirm no scope creep from previous phase.
- Propose next week’s focus.
- Wait for human approval before proceeding.

All major changes must go through PR review using the standard template.

## Risk Register (Top Risks)
- Localization complexity and future multi-language support
- Firestore schema migrations becoming painful
- Agent hallucination or scope creep on code changes
- State management inconsistency across web/mobile
- Stripe integration security and webhook reliability
- Mobile offline sync edge cases

## How to Use This Roadmap
- All agent work must stay strictly within the current phase acceptance criteria.
- Human review required on architecture, config changes, Firestore schema, and payments/security.
- Weekly resets are mandatory to prevent scope creep.
- Major updates will be reflected here and in `comprehensive-project-analysis.md`.