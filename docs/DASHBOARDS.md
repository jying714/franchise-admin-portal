# Dashboards Overview
**Doughboys Pizzeria Franchise Platform**  
**Last Updated**: July 19, 2026

## Purpose
This document defines the four main dashboards, their target users, key features, and flows. All dashboards are built with Flutter Web and respect franchise scoping, hybrid single/multi-location logic, dynamic theming, and FeatureGate.

## 1. Platform Owner Dashboard (HQ / Business Management)
**Location in Code**: `web-app/lib/admin/platform_owner/`

**Primary Users**: (platform owner) — managing the SaaS business.

**Key Sections**:
- Overall platform analytics and revenue
- Subscription management and billing (Stripe overview)
- User/Franchise onboarding queue and approvals
- High-level system health metrics (e.g., "XX Critical Errors" tile with direct link to Developer Dashboard)
- Global system settings and feature toggles

**Access**: Full platform visibility. No direct error logs or dev tools (those live in Developer Dashboard).

## 2. HQ Owner / Franchise Owner Dashboard
**Location in Code**: `web-app/lib/admin/hq_owner/`

**Primary Users**: Restaurant/Franchise owners.

**Key Sections**:
- **Design & Branding** (new dedicated page)
  - Live preview simulator (mobile + web)
  - Edit colors, fonts, logos, design tokens
  - Warning for non-developer users
  - Publish changes (franchise-scoped)
- Menu, categories, ingredients management
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

**Special Ability**: Role/dashboard switching to simulate franchise owner or staff views for support.

## Cross-Dashboard Features
- Dynamic theming applied per franchise
- Role-based navigation and permission guards
- Franchise picker (hidden for single-location)
- Live preview components shared with mobile app

## Future Enhancements
- Version history for design changes
- AI-assisted design suggestions
- White-label template gallery

---