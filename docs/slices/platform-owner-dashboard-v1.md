# Slice: platform-owner-dashboard-v1

**Status:** COMPLETE (2026-07-26)  
**Branch:** `feat/onboarding-4step`  
**Surface:** Platform Owner web dashboard

---

## Goal

Make the Platform Owner dashboard usable for MVP: navigation, franchisee invites, subscription summary, platform revenue overview, and HQ-comparable card layout. Remove dead plans card from the dashboard body (keep Quick Links).

---

## Done

### Navigation

- Explicit routes for `/platform/plans` and `/platform/subscriptions` registered **before** generic platform catch-all in `web-app/lib/main.dart`.

### Invite Franchisees

- `AdminFirestoreService`: `fetchInvitations`, streams/update/cancel helpers with Timestamp-safe mapping.
- Firestore rules: top-level `franchisee_invitations` readable/writable for `isHqOwner()` (includes platform_owner / developer).
- Dialog: real `inviterUserId` from `AdminUserProvider`; Provider re-injected for `showDialog` (Impl + abstract).
- Provider: invite uses `_sending`; list uses `_loading`; `fetchInvitations` uses `finally`; Consumer listens to **Impl** (not Proxy-only abstract).
- Cloud Function `inviteAndSetRole` redeployed on **nodejs20** (`doughboyspizzeria-2b3d2`, us-central1).
- Pending list: `ListView` inside grid cell (scroll, no overflow).

### Franchise subscriptions card

- Admin implements `getFranchiseSubscriptions`, `getAllFranchiseSubscriptions`, `getAllFranchiseSubscriptionsRaw`, `getFranchiseSubscription`, `getCurrentSubscriptionForFranchise`.

### Platform revenue

- Replaced zero placeholders on `fetchPlatformRevenueOverview` / `fetchPlatformFinancialKpis` with aggregation:
  - Top-level `platform_invoices` (YTD paid, overdue)
  - `franchise_subscriptions` (MRR/ARR, active franchise count)
  - Top-level `payouts` (last 30 days)
- UI: single card (not eight mini-cards); metrics in two rows with centered divider; elevation matches peer cards.

### Layout

- Top row: revenue width ≈ 2 grid cells; subscriptions 1 cell; shared height via `cellH`.
- Body grid: Quick Links, Invite, Franchise Network, Settings, Announcements, Future — `childAspectRatio` **1.5 mobile / 2.8 desktop** (aligned with HQ Owner).
- **Removed** `PlatformPlansSummaryCard` from dashboard (plans via Quick Links only).
- App bar: logo + title left; `DashboardSwitcherDropdown` + notifications/help/settings/avatar in **actions** (right).

---

## Out of scope / follow-ups

- Franchise Network / Settings / Announcements product wiring (still placeholders).
- Revenue from **franchise-scoped only** `franchises/{id}/platform_invoices` (not in current aggregator).
- Node 22 Functions runtime (before 2026-10-30).
- Admin / Developer dashboard cleanup (next product focus).
- Mobile multi-restaurant-type QA (later discussion).

---

## Key paths

- `web-app/lib/admin/platform_owner/platform_owner_dashboard_screen.dart`
- `web-app/lib/widgets/financials/platform_revenue_summary_panel.dart`
- `web-app/lib/core/services/admin_firestore_service.dart`
- `web-app/lib/core/providers/franchise_invitation_provider_impl.dart`
- `web-app/lib/widgets/dialogs/franchisee_invitation_dialog.dart`
- `functions/` (nodejs20, `main`: `lib/src/index.js`)
