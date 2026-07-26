# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (afternoon — polish-v1 W1–W3 + W6 implemented)  
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
- [x] **Polish W3:** removed Review `menu_management` false critical (`FranchiseFeatureProviderImpl.validate`)
- [x] **Polish W1:** foundation chrome — no nested AppBars/JSON/tab Mark complete; TabBar selection = weight/size not primary red
- [x] **Polish W2:** menu-items FAB on list pane; preview without Center; dependencies line uses `DesignTokens.textColor`
- [x] **Polish W6:** onboarding step `onboarding_design_branding` (shell, Save→progress, Continue, HQ cascades, Review 5/5 + progress-key status)

### Active slice: `docs/slices/hq-onboarding-hq-polish-v1.md`

**Status:** Implementation in progress — **W1, W2, W3, W6 done**; **W4 + W5 open**.

**Locked decisions:**

| Topic | Decision |
|-------|----------|
| Branding in onboarding | New step; key **`onboarding_design_branding`** (after feature setup, before foundation) |
| Foundation tab Mark complete | **Remove** |
| HQ billing | **One** “Platform billing” card (in-dev OK). Domain = platform→franchise SaaS bills. **No** dual Billing Summary + Invoices |
| Feature gates | Higher-tier only; do **not** reintroduce phantom `menu_management` Review gate |

**Product key order:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Next implementation order:** **W4** Feature Setup in-dev UX → **W5** HQ dashboard (one Platform billing card + dead links + card sizing).

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`; progress is load+write (not a stream); xAI primary for residual surgical tasks.

**Known residual:** franchise-switch lag on progress/domain data possible until reload; Liberty `ingredientId` type noise deferred.

---

**Update this file after significant sessions.**
