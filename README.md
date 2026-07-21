# Doughboys Pizzeria — Franchise Platform

**Monorepo** for **Web Admin Portal** + **Mobile Customer App** + **Shared Core**.

- **Web**: `franchisehq.io` — Admin dashboard (Flutter Web)
- **Mobile**: Customer ordering app (Flutter Android/iOS, one published binary)
- **Backend**: Firebase (Firestore, Auth, Functions, Hosting)
- **Shared Core**: Single source of truth for models, providers, configs, and services

---

## Current Status (July 20, 2026)

**P2 – White-Label & Scalability: COMPLETE**  
**P2.5 – Web-App Cleanup Sprint: COMPLETE**  
**Config Unification: COMPLETE** (All configs now in `shared_core`)

### Major Achievements
- Critical auth handoff & persistent spinner resolved
- FranchiseProvider + shared_core unification complete
- Large-scale cleanup of duplicated code, models, and UI issues
- `hq_owner` dashboard functional with correct franchise resolution
- Core ordering flow stable and device-tested
- All config files (`app_config`, `feature_config`, `branding_config`, `design_tokens`, `ui_config`) unified into `shared_core`
- Dynamic theming and hybrid single/multi-location foundations in place

**Next Phase**: Phase 0 (Infrastructure & Documentation) → **Phase 1: Core Config Scoping & Dynamic Branding** (Firestore per-franchise config)

---

## Project Structure
franchise_platform/
├── shared_core/          # Single source of truth (models, providers, configs)
├── web-app/              # Admin dashboards (Flutter Web)
├── mobile_app/           # Customer ordering app (Android + iOS)
├── docs/                 # Architecture and documentation
├── prompts/              # AI agent prompts (when multi-agent active)
└── ROADMAP.md

## Key Architecture Documents
- `ARCHITECTURE.md` — Overall system design
- `docs/architecture/firestore-per-franchise-config.md` ← **Authoritative Config & Firestore Schema**
- `DASHBOARDS.md` — Dashboard roles and flows
- `MOBILE_DYNAMIC.md` — Dynamic mobile UI strategy
- `ROADMAP.md` — Current priorities and milestones
- `AGENT_SYSTEM.md` — Multi-agent governance

## Quick Start
```bash
git clone https://github.com/jying714/franchise-admin-portal.git
cd franchise_platform

# Web Admin Portal
cd web-app
flutter clean && flutter pub get && flutter gen-l10n
flutter run -d chrome

# Mobile App
cd ../mobile_app
flutter clean && flutter pub get && flutter gen-l10n
flutter run
Development Approach

Multi-agent AI system (on MINISFORUM AI X1 Pro-470) for accelerated progress
Strict human review on every PR (especially payments, security, architecture, config)
Small, iterative changes with clear documentation

Last Updated: July 20, 2026