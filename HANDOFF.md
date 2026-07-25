# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 24, 2026 (HQ Design & Branding v1 slice locked)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

## Current Project State
- **P2 – White-Label & Scalability**: COMPLETE
- **P2.5 – Web-App Cleanup Sprint**: COMPLETE
- Config unification complete (`shared_core` is the single source of truth)
- FranchiseProvider + shared_core fully unified
- Dynamic per-franchise config architecture established (Firestore-backed)
- Hybrid single/multi-location foundations in place
- Core ordering flow stable and device-tested
- Core documentation expanded and aligned
- **Phase 1 Workstream B**: live web branding path wired; HQ Live Branding card on dashboard; agent 2-file surgical edit reliable; dual-edit not proven on dirty pairs
- **Decision 7 (July 24, 2026)**: Franchise/menu onboarding belongs on **HQ Owner** dashboard, not Admin. Progress card landed; navigation CTA still open.
- **Decision 8 (July 24, 2026)**: **HQ Design & Branding v1** locked — card + **Open Design & Branding** → dedicated screen; local draft; Save snackbar only; logo image + fallback. See `docs/slices/hq-design-branding-v1.md`.

## Phase 0 Progress (Infrastructure & Documentation)
- Docker Compose + Ollama + Orchestrator container → **RUNNING**
- Models pulled: `qwen2.5-coder:7b` + `qwen2.5-coder:14b`
- Multi-agent routing + human-approval gates operational
- `STATUS.md` created (always fully loaded by agents)
- SCOPE_CARD + hard bans + approve-to-apply + `/metrics` + `no_change` landed
- 2-file Stage-C process reliable; open dual-edit / 3-file training optional only

## Key Decisions & Architecture Rules
- `shared_core` is the single source of truth for configs, models, providers
- All config work must follow `/docs/architecture/firestore-per-franchise-config.md`
- All data scoped under `franchises/{franchiseId}/...`
- Hybrid single/multi-location with automatic UI simplification
- Dynamic branding & UI via configs + FeatureGate mandatory
- Dashboard roles clearly defined (Platform Owner, HQ Owner, Admin/Staff, Developer)
- **HQ Design & Branding v1** = Decision 8 / `docs/slices/hq-design-branding-v1.md` (not open-ended agent color drills)
- **Onboarding home = HQ Owner** (not Admin) — Decision 7
- Human review required on all payments, auth, security, Firestore schema, and major config changes
- Small, reviewable PRs with human-readable names + inline "why" comments

## Active Priorities (Next)
1. **Implement HQ Design & Branding v1** (shell → card CTA → screen sections per slice doc)
2. Onboarding navigation CTA from HQ progress card → existing onboarding entry (after route reality confirmed)
3. v1.1 branding Firestore write path (only after v1 UI)
4. Broader franchise-scoped config loaders (features / app config) — later
5. Optional dual-edit agent drills only on known-dirty pairs — not default

## Agent Instructions (Always Follow)
- Read `STATUS.md` first (live truth), then `AGENT_SYSTEM.md`, `ROADMAP.md`, `orchestrator/SCOPE_CARD.md`, and `docs/architecture/firestore-per-franchise-config.md`
- For Design & Branding product work also load `docs/slices/hq-design-branding-v1.md`
- Respect franchise scoping and hybrid logic
- Prefer small, safe PRs
- Use human-readable names and inline "why" comments
- Escalate payments, auth, security, architecture, and config changes to human
- Update relevant READMEs and documentation when making changes
- Do not invent BrandingConfig / DesignTokens fields or `FranchiseProvider()` zero-arg
- Do not invent branding Firestore writes in v1

## Current Hardware Setup Notes
- MINISFORUM AI X1 Pro-470, 64 GB RAM, 2 TB SSD
- Docker + Ollama for multi-agent system (running 24/7)
- Orchestrator container: `franchise-orchestrator`
- WSL memory raised (~40 GB); Ollama `mem_limit: 36g` in root `docker-compose.yml`

---

**Usage**: Update this file (and especially `STATUS.md`) at the start/end of each major session or phase. It serves as quick context for agents and future handoffs.

**Last Updated**: July 24, 2026
