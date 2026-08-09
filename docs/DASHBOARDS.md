# Dashboards Overview
**Doughboys Pizzeria Franchise Platform**  
**Last Updated**: August 8, 2026

## Purpose
Defines the four main dashboards, target users, and IA. Flutter Web; franchise scoping; FeatureGate; human merge gate for agents.

## 1. Platform Owner Dashboard
**Location**: `web-app/lib/admin/platform_owner/`

**Users**: Platform owners (SaaS).

**Key sections**: Platform analytics/revenue, subscriptions, franchisee invitations, system health links, feature toggles.

**Status**: MVP complete — `docs/slices/platform-owner-dashboard-v1.md`.

## 2. HQ Owner / Franchise Owner Dashboard
**Location**: `web-app/lib/admin/hq_owner/`

**Users**: Restaurant / franchise owners.

**Key sections**:
- Design & Branding (live preview + Save)
- Onboarding shell (Decision 7) — Feature Setup → Branding → Foundation → Menu Items → Review
- Financial / billing / alerts cards
- **Quick Links**: Floor plan, Tax & hours, Onboarding, **Portal users**

**Portal users** (`StaffAccessScreen`): web portal invites (`inviteType: portal_staff`), pending/revoke, HQ RoleGuard. Not station PIN staff.

## 3. Admin / Staff Dashboard
**Location**: `web-app/lib/admin/dashboard/` + ops screens · registry `web-app/lib/core/section_registry.dart`

**Users**: Store managers / day-2 ops.

**Sidebar**:
- Dashboard, Menu, Categories, Inventory, Order Analytics, Orders, Feedback, Promotions
- **Staff Management** (expansion):
  - Station staff (PIN roster + **permissions**)
  - Schedule
  - Hours
- Support Chat (as registered)

**Portal users** is **not** on Admin sidebar (`staffAccess.showInSidebar: false`); hosted under HQ.

**Notes**:
- Admin is not the onboarding host (Decision 7).
- Admin Menu = day-2 ops (Decision 9); modifiers = Decision 10 schema.

## 4. Developer Dashboard
**Location**: `web-app/lib/admin/developer/`

Error logs, impersonation Phase A, feature toggles, schema inventory, audit streams.

## Cross-dashboard
- Franchise theming via `FranchiseProvider` / DesignTokens  
- Role guards, franchise picker, dashboard switcher  

## Development notes
- Schema / branding / payment / claims changes need human review  
- Agents: `AGENT_SYSTEM.md`, `orchestrator/SCOPE_CARD.md`, `STATUS.md`  
