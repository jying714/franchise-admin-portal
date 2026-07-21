# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 20, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (64GB RAM + 1TB SSD)

## Current Project State
- **P2 – White-Label & Scalability**: COMPLETE
- **P2.5 – Web-App Cleanup Sprint**: COMPLETE
- Config unification complete (`shared_core` is the single source of truth)
- FranchiseProvider + shared_core fully unified
- Dynamic per-franchise config architecture established (Firestore-backed)
- Hybrid single/multi-location foundations in place
- Core ordering flow stable and device-tested
- Core documentation expanded and aligned

## Key Decisions & Architecture Rules
- `shared_core` is the single source of truth for configs, models, providers
- All config work must follow `/docs/architecture/firestore-per-franchise-config.md`
- All data scoped under `franchises/{franchiseId}/...`
- Hybrid single/multi-location with automatic UI simplification
- Dynamic branding & UI via configs + FeatureGate mandatory
- Dashboard roles clearly defined (Platform Owner, HQ Owner, Admin/Staff, Developer)
- Design & Branding page in HQ Owner dashboard with live preview + warnings
- Human review required on all payments, auth, security, Firestore schema, and major config changes
- Small, reviewable PRs with human-readable names + inline "why" comments

## Active Priorities (Next)
1. **Phase 0**: Multi-agent environment setup + documentation hardening
2. **Phase 1**: Full dynamic config rollout and Firestore scoping
3. **Phase 2**: Design & Branding page + hybrid enhancements
4. **Phase 3**: Mobile dynamic UI refactoring

## Agent Instructions (Always Follow)
- Read `AGENT_SYSTEM.md`, `ROADMAP.md`, and `docs/architecture/firestore-per-franchise-config.md` first
- Respect franchise scoping and hybrid logic
- Prefer small, safe PRs
- Use human-readable names and inline "why" comments
- Escalate payments, auth, security, architecture, and config changes to human
- Update relevant READMEs and documentation when making changes

## Current Hardware Setup Notes
- MINISFORUM AI X1 Pro-470, 64GB RAM, 1TB SSD
- Docker + Ollama for multi-agent system
- Expect 7–9 parallel agents comfortably

---

**Usage**: Update this file at the start/end of each major session or phase. It serves as quick context for agents and future handoffs.

**Last Updated**: July 20, 2026