# STATUS.md — Live Project Snapshot

**Last Updated**: July 26, 2026 (afternoon — polish-v1 platform billing MVP refined)  
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

### Active slice: `docs/slices/hq-onboarding-hq-polish-v1.md`

**Locked decisions:**

| Topic | Decision |
|-------|----------|
| Branding in onboarding | New step; key **`onboarding_design_branding`** (after feature setup, before foundation) |
| Foundation tab Mark complete | **Remove** |
| HQ billing | **One** “Platform billing” card (in-dev OK). Domain = platform→franchise SaaS bills. **No** dual Billing Summary + Invoices; **no** custom invoice list required for this slice |

**Product key order:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Next implementation order:** W3 Review false positive → W1 foundation chrome → W2 FAB/preview → W6 branding step → W4 feature in-dev → W5 HQ cards.

**Ground truth:** one FranchiseProvider; no new DesignTokens fields; progress under `franchises/{id}/onboarding_progress/progress`; xAI primary.

---

**Update this file after significant sessions.**
