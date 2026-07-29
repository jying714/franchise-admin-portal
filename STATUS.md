# STATUS.md — Live Project Snapshot

**Last Updated**: July 29, 2026 (~15:50 CDT — MVP completion locks: franchise context + Stripe Connect)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `main`  
**Main**: menu M1–M5, wings/calzone, mobile design tokens T1–T9, developer D0–D10; Hosting deploy on push

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Core platform vertical slice is on `main`.**  
**Release / pilot MVP remaining work is locked** under Decisions **11** (customer multi-franchise path) and **12** (Stripe dual-account model).

| Area | State |
|------|--------|
| HQ onboarding + Design & Branding | **Done** |
| Platform Owner MVP | **Done** |
| Admin ops v1 | **Done** |
| Menu modifier M1–M5 + wings/calzone W0–W7+W2 | **Done** |
| Mobile Design Tokens v1 (T1–T9) | **Done** |
| Developer Dashboard v1 (D0–D10) | **Done** |
| **Customer franchise context v1** | **Locked — not implemented** |
| **Stripe checkout v1 (Connect)** | **Locked — not implemented** |

### Completed (locked)

- [x] HQ onboarding sole host (Decision 7)
- [x] HQ Design & Branding v1/v1.1; financial / platform billing honesty
- [x] Platform Owner dashboard MVP
- [x] Admin dashboard ops fixes v1
- [x] Menu modifier rebuild M1–M5 + wings/calzone + W2 — `main`
- [x] Mobile Design Tokens v1 — `main` (`docs/slices/mobile-design-tokens-v1.md`)
- [x] Developer Dashboard v1 — `main` (`docs/slices/developer-dashboard-v1.md`)
- [x] **Decision 11** Customer hybrid multi-tenant path (A+B) — product lock July 29
- [x] **Decision 12** Stripe: platform SaaS account + Connect per franchise — product lock July 29

### Active focus — release MVP

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | **Customer franchise context v1** — cold start, deep link/QR, recents, switcher, directory foundation, signed-out browse, cart clear on switch; test with **real + mock** listed franchises | `docs/slices/customer-franchise-context-v1.md` · Decision 11 |
| **2** | **Stripe checkout v1** — platform account for HQ subscriptions; Connect destination + application fee for customer orders; HQ onboarding status; `paymentsEnabled` gate | `docs/slices/stripe-checkout-v1.md` · Decision 12 |
| **3** | Pilot polish: reorder honesty, basic order status, closed hours gate, cart attach on sign-in | Explicit human tasks |

**Pilot acquisition:** every pilot customer gets QR/SMS link; **directory foundation still required** for cold start and second-tenant QA.

### Decision 11 / 12 locks (do not regress in implementation)

| Topic | Lock |
|--------|------|
| App binary | Hybrid multi-tenant; **session = one `franchiseId`**; branding follows selection |
| Acquisition | **QR/SMS primary**; **directory secondary but real** |
| Bind pipeline | Link, QR, directory, recents, switcher → **same** `setFranchiseId` + branding + menu |
| Signed-out | Browse menu + cart allowed; **checkout requires sign-in** |
| Cart on switch | Confirm → **clear cart & switch**; no cross-franchise merge |
| Stripe platform | Charges **HQ owners** for SaaS (subscriptions / platform invoices) |
| Stripe Connect | **Each franchise** connected account; **customer order** money + application fee to platform |
| Live charges | Only when franchise `paymentsEnabled` (Connect ready) |
| Test | Real franchise + mock seeded franchise both listable |

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| Geo / map directory | Post-MVP |
| Guest checkout (pay without account) | Post-MVP |
| HQ Design full semantic color editors | Deferred — seeds only |
| Cash Flow / Multi-Brand HQ cards | Post-MVP |
| Alerts producers / full AlertListScreen | Deferred |
| Combos / bundles | Deferred |
| Auth ColorScheme residual (T8) | Deferred polish |
| Order-experience post-delivery trigger | Post-MVP |
| Impersonation Phase B (real claims) | Future |
| CF Node 22 | Before ~2026-10-30 |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no DesignTokens widget color invention; progress under `franchises/{id}/onboarding_progress/progress`; mobile theme = ColorScheme from franchise seeds.

---

**Update this file after significant sessions.**
