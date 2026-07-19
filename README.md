# Doughboys Pizzeria — Franchise Platform

**Monorepo** for **Web Admin Portal** + **Mobile Customer App** + **Shared Core**.

- **Web**: `franchisehq.io` — Admin dashboard (Flutter Web)
- **Mobile**: Customer ordering app (Flutter Android/iOS, one published binary)
- **Backend**: Firebase (Firestore, Auth, Functions, Hosting)
- **Shared Core**: Single source of truth for models, providers, configs, and services

---

## Current Status (July 19, 2026)

**P2 – White-Label & Scalability: COMPLETE**  
**P2.5 – Web-App Cleanup Sprint: COMPLETE**

### Major Achievements
- Critical auth handoff & persistent spinner resolved
- FranchiseProvider + shared_core unification complete
- Large-scale cleanup of duplicated code, models, and UI issues
- `hq_owner` dashboard functional with correct franchise resolution
- Core ordering flow stable and device-tested
- Dynamic theming and hybrid single/multi-location foundations in place

**Next Phase**: Phase 0 (Infrastructure) upon new hardware arrival, then **P3 – Advanced Features & Production Readiness**

---

## Project Structure
franchise_platform/
├── shared_core/          # Single source of truth (models, providers, configs)
├── web-app/              # Admin dashboards (Flutter Web)
├── mobile_app/           # Customer ordering app (Android + iOS)
├── docs/                 # Architecture and documentation
├── prompts/              # AI agent prompts (when multi-agent active)
└── ROADMAP.md


## Quick Start
```bash

# Clone the repo

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

Key Architecture Documents

ARCHITECTURE.md — Overall system design
DASHBOARDS.md — Dashboard roles and flows
MOBILE_DYNAMIC.md — Dynamic mobile UI strategy
ROADMAP.md — Current priorities and milestones
CONTRIBUTING.md — Development standards

## Development Approach

Multi-agent AI system (on MINISFORUM AI X1 Pro-470) for accelerated progress
Strict human review on every PR (especially payments, security, architecture)
Small, iterative changes with clear documentation

Last Updated: July 19, 2026