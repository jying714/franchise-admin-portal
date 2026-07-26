# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (evening — HQ Owner financial surfaces closed; Cash Flow / Multi-brand **post-MVP defer**)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 – Core Config Scoping & Dynamic Branding + HQ surfaces**

### Completed (recent)

- [x] Menu Items v1; live HQ branding on franchise switch; branding notify + picker guard
- [x] **Single** web `FranchiseProvider` at app root
- [x] Design & Branding screen v1/v1.1
- [x] **Polish W1–W6 COMPLETE** — `docs/slices/hq-onboarding-hq-polish-v1.md`
  - Feature Setup GA / in-dev UX + alpha sort; mobile_ordering data fix on `test`
  - HQ grid: Platform billing + Payouts honesty; Live Branding + Onboarding peer-sized; Future Features last
- [x] **HQ Financial Honesty v1 COMPLETE** — `docs/slices/hq-financial-honesty-v1.md`
  - AdminFirestoreService: latest analytics (prefer revenue > 0), outstanding platform invoices, last payout
  - KPI card: 2-decimal display, Expanded tiles, franchise switch reload (ValueKey + provider)
- [x] **HQ Platform Billing v1 COMPLETE** — `docs/slices/hq-platform-billing-v1.md`
  - In-card read-only `franchises/{id}/platform_invoices` list + Outstanding footer (same unpaid-class rule as KPI)
- [x] **HQ Alerts card UI honesty (card-only, not a formal slice)** — filter menu, Retry, no dead `pushNamed('/alerts')`, `ValueKey` on franchise; **no** AlertListScreen / producers

### Active slice

**None.** Next product focus (human): **Platform Owner / Admin dashboard** (not HQ Owner residual shells).

### Explicit post-MVP / long-term in-dev (do not open slices now)

| Surface | Decision |
|---------|----------|
| **Cash Flow Forecast** (HQ card) | **Post-MVP defer** — low MVP value; leave explicit in-dev or stub |
| **Multi-Brand Overview** (HQ card) | **Post-MVP defer** — single-franchise HQ is truth for MVP |
| **Payouts** (HQ card product) | Still in-dev shell; not started as honesty slice this session |
| **Alerts producers / AlertListScreen** | Deferred — consumer card ready; no writers wired |

**Product key order (onboarding):**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`; progress is load+write (not a stream); HQ financial reads on **AdminFirestoreService** (not lightweight stubs).

**Known residual (non-blocking):** franchise-switch onboarding progress lag; Liberty `ingredientId` type noise; device re-smoke `mobile_ordering`; Payouts shell; Cash Flow / Multi-brand post-MVP.

---

**Update this file after significant sessions.**
