# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (afternoon — **hq-onboarding-hq-polish-v1 COMPLETE**)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch**: `feat/onboarding-4step`

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Phase 1 – Core Config Scoping & Dynamic Branding + HQ/Onboarding polish**

### Completed (recent)

- [x] Menu Items v1; live HQ branding on franchise switch; branding notify + picker guard
- [x] **Single** web `FranchiseProvider` at app root
- [x] Design & Branding screen v1/v1.1
- [x] **Polish W3:** removed Review `menu_management` false critical
- [x] **Polish W1:** foundation chrome honesty
- [x] **Polish W2:** menu-items FAB + preview parity
- [x] **Polish W6:** onboarding step `onboarding_design_branding` (5-step flow)
- [x] **Polish W4:** Feature Setup GA allowlist + In development UX (sorted)
- [x] **Polish W5:** HQ one Platform billing card; Payouts in-dev; dead CTAs removed; grid sizing

### Active slice

**`docs/slices/hq-onboarding-hq-polish-v1.md` — COMPLETE**

**Product key order:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`; progress is load+write (not a stream); xAI primary for residual surgical tasks.

**Known residual (non-blocking):** franchise-switch lag on progress until reload; Liberty `ingredientId` type noise deferred; device re-smoke of `mobile_ordering` after Android Studio re-setup.

**Next:** Open a new product slice only when ready; do not bulk agent inbox against closed polish work.

---

**Update this file after significant sessions.**
