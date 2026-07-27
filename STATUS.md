# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (late evening — Platform Owner dashboard MVP closed)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 – Core Config Scoping & Dynamic Branding + HQ / Platform Owner surfaces**

### Completed (recent)

- [x] Menu Items v1; live HQ branding on franchise switch; branding notify + picker guard
- [x] **Single** web `FranchiseProvider` at app root
- [x] Design & Branding screen v1/v1.1
- [x] **Polish W1–W6 COMPLETE** — `docs/slices/hq-onboarding-hq-polish-v1.md`
- [x] **HQ Financial Honesty v1 COMPLETE** — `docs/slices/hq-financial-honesty-v1.md`
- [x] **HQ Platform Billing v1 COMPLETE** — `docs/slices/hq-platform-billing-v1.md`
- [x] **HQ Alerts card UI honesty (card-only)** — filter, Retry, no dead See all; no producers
- [x] **Platform Owner dashboard MVP COMPLETE** — `docs/slices/platform-owner-dashboard-v1.md`
  - Routes: explicit `/platform/plans`, `/platform/subscriptions` before catch-all
  - Invite Franchisees: Admin `fetchInvitations*` + Firestore rules; dialog Provider scope; inviter user id; Cloud Function `inviteAndSetRole` redeployed **nodejs20**
  - Franchise subscriptions card: Admin `getFranchiseSubscriptions` (+ related getters)
  - Platform revenue: Admin aggregation from top-level `platform_invoices`, `franchise_subscriptions`, `payouts` (placeholders replaced)
  - Layout: HQ-style 3-col grid (`childAspectRatio` 1.5 / 2.8); revenue panel = 2 cell widths; Platform Plans **card removed** (Quick Links only)
  - Invite list: `ListView` inside card (no overflow)

### Active focus (human-chosen next)

1. **Admin dashboard** — inventory / cleanup / real vs stub cards  
2. **Developer dashboard** — same  
3. **HQ Owner residual wiring** — only what little remains (not Cash Flow / Multi-brand)

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| **Cash Flow Forecast** (HQ) | **Post-MVP** |
| **Multi-Brand Overview** (HQ) | **Post-MVP** |
| **Payouts** (HQ product card) | In-dev shell; not honesty-sliced this arc |
| **Alerts producers / AlertListScreen** | Deferred |
| **Mobile app restaurant-type agnostic QA** | Deferred discussion — pizzeria-first history; layout/config acceptance needs dedicated pass |
| **Cloud Functions Node 22** | Node **20** live (nodejs18 decommissioned); 20 decommissions ~2026-10-30 — plan upgrade before then |
| **Franchise-scoped invoice rollup in Platform revenue** | Optional — current path is **top-level** `platform_invoices` only |

**Product key order (onboarding):**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`; progress is load+write (not a stream); HQ + Platform Owner financial/admin reads on **AdminFirestoreService** (not lightweight stubs).

**Known residual (non-blocking):** franchise-switch onboarding progress lag; Liberty `ingredientId` type noise; device re-smoke `mobile_ordering`; Payouts shell; CF Node 22; mobile multi-type layout QA.

---

**Update this file after significant sessions.**
