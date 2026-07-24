# Dashboards Overview
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 24, 2026

## Purpose
This document defines the four main dashboards, their target users, key features, and flows. All dashboards are built with Flutter Web and respect franchise scoping, hybrid single/multi-location logic, dynamic theming, FeatureGate, and agent-assisted development with strict human review.

## 1. Platform Owner Dashboard (HQ / Business Management)
**Location in Code**: `web-app/lib/admin/platform_owner/`

**Primary Users**: Platform owners — managing the SaaS business.

**Key Sections**:
- Overall platform analytics and revenue
- Subscription management and billing (Stripe overview)
- User/Franchise onboarding queue and approvals
- High-level system health metrics (with links to Developer Dashboard)
- Global system settings and feature toggles

**Access**: Full platform visibility.

## 2. HQ Owner / Franchise Owner Dashboard
**Location in Code**: `web-app/lib/admin/hq_owner/`

**Primary Users**: Restaurant/Franchise owners.

**Key Sections**:
- **Design & Branding** (dedicated page — high priority)
  - Live preview simulator (mobile + web views)
  - Edit design tokens, colors, fonts, logos
  - Warning for non-developer users
  - Franchise-scoped Firestore storage and publish changes
- **Franchise / menu onboarding** (target home — see Decision 7 in `docs/DECISIONS.md`)
  - Categories, ingredients, menu items, feature setup, review/publish
  - Progress tile on `OwnerHQDashboardScreen` while incomplete
  - Reuses existing onboarding screens under `web-app/lib/admin/dashboard/onboarding/`
  - **Current**: still launched primarily from Admin dashboard; migration to HQ Owner is planned
- Menu, categories, ingredients management (post-onboarding)
- Orders, analytics, staff management
- Subscription & billing for their franchise
- Location management (single vs multi)

**Hybrid Behavior**: Simplified view for single-location owners; full franchise tools for multi-location.

## 3. Admin / Staff Dashboard
**Location in Code**: `web-app/lib/admin/staff/` (and related admin ops screens)

**Primary Users**: Store managers, kitchen staff, delivery team.

**Key Sections**:
- Daily operations (orders, kitchen display)
- Menu updates (limited permissions)
- Staff scheduling and tasks
- Location-specific analytics

**Access**: Scoped to assigned location(s) via roles.

**Note**: Admin is **not** the long-term home for franchise/menu onboarding. Onboarding belongs on HQ Owner (Decision 7). Until migration completes, onboarding may still be reachable from Admin paths for continuity.

## 4. Developer Dashboard
**Location in Code**: `web-app/lib/admin/developer/`

**Primary Users**: You or hired developers (paid onboarding assistance).

**Key Sections**:
- Error logging and debugging tools
- Assisted onboarding simulation (switch between roles/franchises)
- System health and performance monitoring
- Feature flag management
- Design preview and testing tools
- Agent workflow monitoring

**Special Ability**: Role/dashboard switching to simulate franchise owner or staff views for support.

## Cross-Dashboard Features
- Dynamic theming applied per franchise
- Role-based navigation and permission guards
- Franchise picker (hidden for single-location)
- Live preview components shared with mobile app
- Agent-assisted development with strict human review on config and design changes

## Config & Branding Integration
- All dashboards pull dynamic config from Firestore per franchise via `FranchiseProvider`
- Design & Branding page is the primary interface for editing `ui_config` (see `/docs/architecture/firestore-per-franchise-config.md`)
- Live preview must reflect real-time changes from Firestore
- FeatureGate respected everywhere

## Future Enhancements
- Version history for design changes
- AI-assisted design suggestions
- White-label template gallery
- Complete onboarding migration to HQ Owner (tile → demote Admin entry)

## Development Notes
- All major config, design, and Firestore schema changes require human review.
- Hybrid single/multi-location logic must be respected in all dashboards.
- Agent work must stay strictly within defined phase scope (see `AGENT_SYSTEM.md` and `ROADMAP.md`).
- Reference `docs/architecture/firestore-per-franchise-config.md` for any theming/branding work.
- Onboarding placement: see `docs/DECISIONS.md` Decision 7.

---
