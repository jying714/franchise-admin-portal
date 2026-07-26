# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (afternoon — **hq-platform-billing-v1 COMPLETE**)  
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
- [x] **HQ Financial Honesty v1 COMPLETE** — KPI card real Admin reads + switch reload
- [x] **HQ Platform Billing v1 COMPLETE** — in-card read-only `platform_invoices` list + outstanding footer

### Active slice

None — pick next product slice when ready.

**Product key order (onboarding):**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`; progress is load+write (not a stream); HQ financial reads on **AdminFirestoreService**.

**Known residual (non-blocking):** franchise-switch progress lag; Liberty `ingredientId` type noise; Cash Flow / Payouts still in-dev shells; device re-smoke `mobile_ordering`.

---

**Update this file after significant sessions.**
