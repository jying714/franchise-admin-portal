# Dashboards Overview
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 27, 2026

## Purpose
This document defines the four main dashboards, their target users, key features, and flows. All dashboards are built with Flutter Web and respect franchise scoping, hybrid single/multi-location logic, dynamic theming, FeatureGate, and agent-assisted development with strict human review.

## 1. Platform Owner Dashboard
**Location in Code**: `web-app/lib/admin/platform_owner/`

**Primary Users**: Platform owners — managing the SaaS business.

**Key Sections**:
- Overall platform analytics and revenue
- Subscription management and billing (Stripe overview)
- User/Franchise invitation and approvals
- High-level system health metrics (with links to Developer Dashboard)
- Global system settings and feature toggles

**Access**: Full platform visibility.

**Status**: MVP complete (July 2026) — see `docs/slices/platform-owner-dashboard-v1.md`.

## 2. HQ Owner / Franchise Owner Dashboard
**Location in Code**: `web-app/lib/admin/hq_owner/`

**Primary Users**: Restaurant/Franchise owners.

**Key Sections**:
- **Design & Branding** — live preview + Save to franchise branding / ui_config
- **Franchise / menu onboarding** (Decision 7)
  - Progress card → `HqOnboardingShellScreen`
  - Steps: Feature Setup, Design & Branding, Core Menu Foundation, Menu Items, Review & Publish
  - Progress: `franchises/{id}/onboarding_progress/progress`
- Financial / billing / alerts cards on HQ home

**Menu Items in onboarding** = guided **power setup** (templates, schema repair, foundation). After Decision 10, writes the **same** modifier schema as Admin Menu.

**Hybrid Behavior**: Simplified view for single-location owners; full franchise tools for multi-location.

## 3. Admin / Staff Dashboard
**Location in Code**: `web-app/lib/admin/dashboard/` + ops screens (`menu`, `categories`, `orders`, …)

**Primary Users**: Store managers, kitchen staff, delivery team.

**Key Sections** (`section_registry`):
- Dashboard home, Menu, Categories, Inventory, Order Analytics, Orders, Feedback, Promotions
- Staff / Support Chat — **placeholder** entries in registry (real screens exist but unwired as of July 27)

**Access**: Scoped to assigned location(s) via roles.

**Notes**:
- Admin is **not** the onboarding host (Decision 7).
- **Admin Menu** = day-2 ops for managers (Decision 9). Modifier architecture = Decision 10 rebuild — do not dual-write legacy Customize tree long term.
- July 27 smoke: categories add/delete, promos CRUD, orders ⋮, franchise refresh, menu Customize spinner — see `docs/slices/admin-dashboard-ops-fixes-v1.md`.

## 4. Developer Dashboard
**Location in Code**: `web-app/lib/admin/developer/`

**Primary Users**: Platform developers / assisted onboarding support.

**Key Sections**:
- Error logging and debugging tools
- Role/franchise simulation
- System health and feature flags
- Agent workflow monitoring

**Special Ability**: Role/dashboard switching to simulate franchise owner or staff views for support.

**Status**: Inventory / cleanup still open after Admin ops + menu rebuild prioritization.

## Cross-Dashboard Features
- Dynamic theming per franchise
- Role-based navigation and permission guards
- Franchise picker (where allowed by role)
- Dashboard switcher (Admin ↔ HQ ↔ Platform ↔ Developer)
- Agent-assisted development with human merge gate

## Config & Branding Integration
- Dashboards pull config via `FranchiseProvider`
- Design & Branding is the primary HQ interface for branding keys (see `/docs/architecture/firestore-per-franchise-config.md`)
- FeatureGate respected everywhere

## Development Notes
- Major config, design, Firestore schema, and **menu modifier** changes require human review
- Decisions 9–10 govern Admin vs HQ menu surfaces and modifier rebuild
- Agent work: `AGENT_SYSTEM.md`, `orchestrator/SCOPE_CARD.md`, `STATUS.md`

---
