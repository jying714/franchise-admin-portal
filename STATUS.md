# STATUS.md — Live Project Snapshot

**Last Updated**: July 30, 2026 (~10:30 CDT — stripe-checkout-v1 active; ST1 next)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/stripe-checkout-v1`  
**Main**: menu M1–M5, wings/calzone, mobile design tokens T1–T9, developer D0–D10, **customer franchise context v1**; Hosting deploy on push

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Core platform + customer franchise context on `main`.**  
**Active implementation:** Decision **12** — Stripe checkout v1 (platform SaaS + Connect).  
**Still locked (not started):** Decision **13** kitchen ops + cash.

| Area | State |
|------|--------|
| HQ onboarding + Design & Branding | **Done** |
| Platform Owner MVP | **Done** |
| Admin ops v1 | **Done** |
| Menu modifier M1–M5 + wings/calzone W0–W7+W2 | **Done** |
| Mobile Design Tokens v1 (T1–T9) | **Done** |
| Developer Dashboard v1 (D0–D10) | **Done** |
| **Customer franchise context v1** | **COMPLETE on `main`** |
| **Stripe checkout v1 (Connect)** | **In progress on `feat/stripe-checkout-v1`** (ST0 done; ST1 next) |
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
- [x] **Customer franchise context v1** — CF1–CF10; merged to `main` July 29–30
- [x] **Decision 12** Stripe: platform SaaS + Connect per franchise — July 29 (docs locked)
- [x] **Decision 13** Kitchen ops: thin Flutter kitchen app, cash-on-pickup toggles, multi-printer, manager gates — July 29 (docs locked)

### Active focus — release MVP

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | **Stripe checkout v1** (Connect + platform SaaS) — **ST1** franchise Connect fields + `paymentsEnabled` | `docs/slices/stripe-checkout-v1.md` · Decision 12 |
| **2** | **Kitchen ops v1** — thin Kitchen app, auto-print, category→printer routing, Admin cash toggles, manager-only void/refund, manager offline/print alerts | `docs/slices/kitchen-ops-v1.md` · Decision 13 |
| **3** | Pilot polish: reorder, order status, closed hours, cart attach on sign-in | Explicit human tasks |

**Pilot:** real franchise + mock listed franchise; customer QR/SMS primary + directory foundation; **Android kitchen tablet** at make line (Flutter multi-platform code OK; iOS kitchen post-pilot).

### Decision 11 / 12 / 13 locks (do not regress)

| Topic | Lock |
|--------|------|
| App binary | Hybrid multi-tenant; session = one `franchiseId` |
| Acquisition | QR/SMS primary; directory required foundation |
| Bind | `FranchiseBindService` only (no ad-hoc setFranchiseId for product flows) |
| Signed-out | Browse menu OK; **add-to-cart / cart / checkout require auth** (guest cart deferred) |
| Cart on switch | Confirm → clear cart & switch |
| Share QR | Prefer `https://franchisehq.io/f/{id}` |
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
| Guest cart / guest checkout | Post-MVP |
| Full OS App Links / AASA production hardening | Follow-up polish |
| Geo / map directory | Post-MVP |
| Full POS / cash drawer / card-present terminal | Post-MVP |
| iOS kitchen kiosk bring-up | Post-pilot |
| HQ Design full semantic color editors | Deferred |
| Cash Flow / Multi-Brand HQ cards | Post-MVP |
| Combos / bundles | Deferred |
| Impersonation Phase B | Future |
| CF Node 22 | Before ~2026-10-30 |

**Onboarding product keys:**  
`onboarding_feature_setup` → `onboarding_design_branding` → `onboarding_menu_foundation` → `onboardingMenuItems` → `onboardingReview`

**Ground truth:** one FranchiseProvider; no DesignTokens widget color invention; progress under `franchises/{id}/onboarding_progress/progress`; mobile theme = ColorScheme from franchise seeds; progress load must include **`onboarding_design_branding`** in defaultSteps.

---

**Update this file after significant sessions.**
