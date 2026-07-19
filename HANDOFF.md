# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 19, 2026  
**Hardware**: MINISFORUM AI X1 Pro-470 (64GB RAM + 1TB SSD)

## Current Project State
- P2.5 Web-App Cleanup Sprint: COMPLETE
- Core ordering flow stable and device-tested
- FranchiseProvider + shared_core unification complete
- Hybrid single/multi-location foundations in place
- Dynamic theming and config system ready for full scoping
- Mobile app transitioning from pizzeria-hardcoded to fully dynamic/config-driven UI
- Core documentation (ARCHITECTURE.md, DASHBOARDS.md, MOBILE_DYNAMIC.md, etc.) expanded

## Key Decisions & Architecture Rules
- `shared_core` is the single source of truth for configs, models, providers
- All data scoped under `franchises/{franchiseId}/...`
- Hybrid single/multi-location with automatic UI simplification
- Dynamic branding & UI via configs + FeatureGate
- Dashboard roles clearly defined (Platform Owner, HQ Owner, Admin/Staff, Developer)
- Design & Branding page in HQ Owner dashboard with live preview + warnings
- Human review required on all payments, auth, security, and major changes
- Small, reviewable PRs with human-readable names + inline "why" comments

## Active Priorities (Next)
1. Phase 0: Set up multi-agent environment on new hardware
2. Phase 1: Full config scoping in shared_core
3. Phase 2: Hybrid logic + Design & Branding page
4. Phase 3: Mobile dynamic UI refactoring

## Agent Instructions (Always Follow)
- Respect franchise scoping and hybrid logic
- Prefer small PRs
- Use human-readable names and inline "why" comments
- Escalate payments, auth, security, and architecture decisions to human
- Reference ARCHITECTURE.md, DASHBOARDS.md, MOBILE_DYNAMIC.md, and this HANDOFF.md

## Current Hardware Setup Notes
- MINISFORUM AI X1 Pro-470, 64GB RAM, 1TB SSD
- Docker + Ollama for multi-agent system
- Expect 7–9 parallel agents comfortably

---

**Usage**: Update this file at the start/end of each major session or phase. It serves as quick context for agents and future handoffs.

**Last Updated**: July 19, 2026