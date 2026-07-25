# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 25, 2026 (HQ onboarding sole host; progress Feature Setup verified)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

## Current Project State
- **P2 – White-Label & Scalability**: COMPLETE
- **P2.5 – Web-App Cleanup Sprint**: COMPLETE
- Config unification complete (`shared_core` is the single source of truth)
- FranchiseProvider + shared_core fully unified
- Dynamic per-franchise config architecture established (Firestore-backed)
- **Phase 1 Workstream B**: live web branding; HQ Design & Branding **v1.1** persistence landed
- **Decision 7 (July 25)**: Onboarding **fully migrated** under HQ Owner. Admin onboarding tree **removed**. Host = `HqOnboardingShellScreen`
- **Decision 8**: HQ Design & Branding v1 complete; v1.1 Save writes franchise branding + ui_config
- **Progress tracking**: path `franchises/{id}/onboarding_progress/progress`; card watches `OnboardingProgressProviderImpl`; Feature Setup → card verified

## Phase 0 / Agent system
- Docker + Ollama + Orchestrator running
- SCOPE_CARD, hard bans, path allowlist, auto-reject, `no_change`, `/metrics`
- **Multi-file parse/apply** supported in proposal_store (July 25)

## Key Decisions & Architecture Rules
- `shared_core` single source of truth
- Data under `franchises/{franchiseId}/...`
- **Onboarding home = HQ Owner only** — no Admin onboarding host
- Progress keys: `onboarding_feature_setup`, `onboarding_menu_foundation`, `onboardingMenuItems`, `onboardingReview`
- Foundation sub-keys (`ingredientTypes` / `ingredients` / `categories`) feed detail % only; step 2 only via foundation continue
- Review summary “Complete” = validation; progress key on publish only
- Review UX direction: drop summary Action/Fix Now; expansion Fix = section-only in-shell nav
- Human review on payments, auth, security, schema, major config

## Active Priorities (Next)
1. Progress writers: menu unmark (`onboardingMenuItems`), foundation → step 2, publish → `onboardingReview`
2. Review UI: strip summary Action column; expansion section-only Fix
3. Optional listenable abstract alias for OnboardingProgressProvider
4. Broader design/branding fields + color picker (later)
5. Agent dual-file product tasks on known-dirty pairs (optional)

## Agent Instructions (Always Follow)
- Read `STATUS.md` first, then `AGENT_SYSTEM.md`, `ROADMAP.md`, `orchestrator/SCOPE_CARD.md`, `docs/architecture/firestore-per-franchise-config.md`
- For Design & Branding: `docs/slices/hq-design-branding-v1.md`
- Do not reintroduce Admin onboarding paths or top-level `onboarding_progress/{id}`
- Do not invent BrandingConfig / DesignTokens fields or `FranchiseProvider()` zero-arg
- Prefer small, safe PRs; escalate schema/auth/payments to human

## Hardware
- MINISFORUM AI X1 Pro-470, 64 GB RAM, 2 TB SSD
- Orchestrator container: `franchise-orchestrator`

---

**Usage**: Update this file and `STATUS.md` at the end of each major session.

**Last Updated**: July 25, 2026
