# STATUS.md — Live Project Snapshot

**Last Updated**: July 29, 2026 (~17:40 CDT — kitchen-ops + cash on pickup locked for release MVP)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `main`  
**Main**: menu M1–M5, wings/calzone, mobile design tokens T1–T9, developer D0–D10; Hosting deploy on push

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Core platform vertical slice is on `main`.**  
**Release / pilot MVP remaining work is locked** under Decisions **11–13** (customer franchise context, Stripe Connect dual accounts, kitchen ops + cash).

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
| **Kitchen ops v1** (thin app, print, cash toggle) | **Locked — not implemented** |

### Completed (locked)

- [x] HQ onboarding sole host (Decision 7)
- [x] HQ Design & Branding v1/v1.1; financial / platform billing honesty
- [x] Platform Owner dashboard MVP
- [x] Admin dashboard ops fixes v1
- [x] Menu modifier rebuild M1–M5 + wings/calzone + W2 — `main`
- [x] Mobile Design Tokens v1 — `main`
- [x] Developer Dashboard v1 — `main`
- [x] **Decision 11** Customer hybrid multi-tenant path (A+B) — July 29
- [x] **Decision 12** Stripe: platform SaaS + Connect per franchise — July 29
- [x] **Decision 13** Kitchen ops: thin Flutter kitchen app, cash-on-pickup toggles, multi-printer, manager gates — July 29

### Active focus — release MVP

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | **Customer franchise context v1** | `docs/slices/customer-franchise-context-v1.md` · Decision 11 |
| **2** | **Stripe checkout v1** (Connect + platform SaaS) | `docs/slices/stripe-checkout-v1.md` · Decision 12 |
| **3** | **Kitchen ops v1** — thin Kitchen app, auto-print, category→printer routing, Admin cash toggles, manager-only void/refund, manager offline/print alerts | `docs/slices/kitchen-ops-v1.md` · Decision 13 |
| **4** | Pilot polish: reorder, order status, closed hours, cart attach on sign-in | Explicit human tasks |

**Pilot:** real franchise + mock listed franchise; customer QR/SMS primary + directory foundation; **Android kitchen tablet** at make line (Flutter multi-platform code OK; iOS kitchen post-pilot).

### Decision 11 / 12 / 13 locks (do not regress)

| Topic | Lock |
|--------|------|
| App binary | Hybrid multi-tenant; session = one `franchiseId` |
| Acquisition | QR/SMS primary; directory required foundation |
| Signed-out | Browse + cart OK; checkout requires sign-in |
| Cart on switch | Confirm → clear cart & switch |
| Stripe platform | HQ SaaS subscriptions / platform invoices |
| Stripe Connect | Customer card orders → franchise connected account + application fee |
| **Cash on pickup** | **v1 yes**, franchise **Admin feature toggle** |
| **Cash print** | Default **print on submit**; sub-toggle **require cook Accept before print** |
| **Card print** | Auto-print on **`paid`** |
| **Kitchen app** | Thin Flutter; cooks only essential status; **no** full Admin |
| **Void/cancel/refund** | **Manager-only** |
| **Printers** | Multi-printer ready; route by **menu category** (many categories per printer); Ethernet ESC-POS preferred |
| **Pilot kitchen device** | **Android tablet**; codebase stays Flutter multi-platform |
| **Manager alerts** | Push + SMS on tablet offline / printer error |

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| Geo / map directory | Post-MVP |
| Guest checkout (pay without account) | Post-MVP |
| Full POS / cash drawer / card-present terminal | Post-MVP |
| iOS kitchen kiosk bring-up | Post-pilot |
| HQ Design full semantic color editors | Deferred |
| Cash Flow / Multi-Brand HQ cards | Post-MVP |
| Combos / bundles | Deferred |
| Impersonation Phase B | Future |
| CF Node 22 | Before ~2026-10-30 |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no DesignTokens widget color invention; progress under `franchises/{id}/onboarding_progress/progress`; mobile theme = ColorScheme from franchise seeds.

---

**Update this file after significant sessions.**
