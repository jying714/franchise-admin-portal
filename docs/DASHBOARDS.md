# Dashboards Overview
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 25, 2026

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

## 2. HQ Owner / Franchise Owner Dashboard
**Location in Code**: `web-app/lib/admin/hq_owner/`

**Primary Users**: Restaurant/Franchise owners.

**Key Sections**:
- **Design & Branding** (`screens/design_branding_screen.dart`) — live preview + v1.1 Save to franchise branding / ui_config
- **Franchise / menu onboarding** (Decision 7 — **implemented July 25**)
  - Progress card on `OwnerHQDashboardScreen`
  - **Continue** → `HqOnboardingShellScreen` (`onboarding/screens/`)
  - Steps: Feature Setup, Core Menu Foundation, Menu Items, Review & Publish
  - Code: `web-app/lib/admin/hq_owner/onboarding/**`
  - Progress doc: `franchises/{id}/onboarding_progress/progress`
- Financial / billing / alerts cards on HQ home
- Post-onboarding menu ops may still use Admin ops tools where appropriate

**Hybrid Behavior**: Simplified view for single-location owners; full franchise tools for multi-location.

## 3. Admin / Staff Dashboard
**Location in Code**: `web-app/lib/admin/dashboard/` (ops) and related admin screens

**Primary Users**: Store managers, kitchen staff, delivery team.

**Key Sections**:
- Dashboard home, menu editor, categories, inventory
- Orders, analytics, feedback, promos
- Staff / chat placeholders as gated

**Access**: Scoped to assigned location(s) via roles.

**Note**: Admin is **not** the onboarding host. Franchise/menu onboarding was removed from Admin (`section_registry` ops-only; Admin onboarding tree deleted). Use HQ Owner for setup.

## 4. Developer Dashboard
**Location in Code**: `web-app/lib/admin/developer/`

**Primary Users**: Platform developers / assisted onboarding support.

**Key Sections**:
- Error logging and debugging tools
- Role/franchise simulation
- System health and feature flags
- Agent workflow monitoring

**Special Ability**: Role/dashboard switching to simulate franchise owner or staff views for support.

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
- Major config, design, and Firestore schema changes require human review
- Hybrid single/multi-location logic must be respected
- Agent work: `AGENT_SYSTEM.md`, `orchestrator/SCOPE_CARD.md`, `STATUS.md`
- Onboarding placement: `docs/DECISIONS.md` Decision 7 (implemented)

---
