# Dashboards Overview
**Doughboys Pizzeria Franchise Platform**
**Last Updated**: July 20, 2026

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
- Menu, categories, ingredients management (onboarding flows)
- Orders, analytics, staff management
- Subscription & billing for their franchise
- Location management (single vs multi)

**Hybrid Behavior**: Simplified view for single-location owners; full franchise tools for multi-location.

## 3. Admin / Staff Dashboard
**Location in Code**: `web-app/lib/admin/staff/`

**Primary Users**: Store managers, kitchen staff, delivery team.

**Key Sections**:
- Daily operations (orders, kitchen display)
- Menu updates (limited permissions)
- Staff scheduling and tasks
- Location-specific analytics

**Access**: Scoped to assigned location(s) via roles.

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

## Future Enhancements
- Version history for design changes
- AI-assisted design suggestions
- White-label template gallery

## Development Notes
- All major config and design changes require human review.
- Hybrid single/multi-location logic must be respected in all dashboards.
- Agent work must stay within defined phase scope (see `AGENT_SYSTEM.md`).

---