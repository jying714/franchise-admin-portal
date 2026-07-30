# STATUS.md — Live Project Snapshot

**Last Updated**: July 30, 2026 (~15:45 CDT — Decision 14 Thin POS locked; kitchen-only framing superseded)  
**Hardware**: MINISFORUM AI X1 Pro-470 (AMD Ryzen AI 9 HX 470, 64 GB RAM, 2 TB SSD)  
**Branch (active)**: `feat/stripe-checkout-v1`  
**Main**: menu M1–M5, wings/calzone, mobile design tokens T1–T9, developer D0–D10, **customer franchise context v1**; Hosting deploy on push

> This file is **always loaded in full** by every agent.

---

## Current Phase

**Core platform + customer franchise context on `main`.**  
**Active implementation:** Decision **12** — Stripe checkout v1 (platform SaaS + Connect).  
**Station surface (locked, not started):** Decision **14** — Thin POS Station App (`pos_app`). Pure kitchen-only app (Decision 13 framing) is **superseded**.

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
| **Thin POS Station App (`pos_app`)** | **Locked — not implemented** (Decision 14) |
| Kitchen-only app | **Superseded** — do not implement separate kitchen binary |

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
- [x] **Decision 12** Stripe: platform SaaS + Connect per franchise — July 29 (docs locked; impl in progress)
- [x] **Decision 14** Thin POS Station App (`pos_app`) — counter-focused; supersedes pure kitchen framing — July 30 (docs locked)

### Active focus — release MVP

| Priority | Work | Authority |
|----------|------|-----------|
| **1** | **Stripe checkout v1** (Connect + platform SaaS) — **ST1** franchise Connect fields + `paymentsEnabled` | `docs/slices/stripe-checkout-v1.md` · Decision 12 |
| **2** | Polish mobile_app + web-app management to solid MVP quality | Explicit human tasks + existing slices |
| **3** | **Thin POS (`pos_app`)** — counter station, full order entry, dine-in tables, card+cash+drawer, staff/driver pay tracking | `docs/slices/pos-app-v1.md` · Decision 14 |
| **4** | Customer website (part of hard release gate) | TBD slice / decision |
| **5** | Pilot polish | Explicit human tasks |

**Hard release gate:** Thin POS + customer website + polished mobile_app + web-app management must all be at MVP quality before the product is considered releasable.

**Pilot hardware:** Android tablet at **counter** (not pure make-line KDS); Ethernet ESC-POS printers in kitchen(s); cash drawer; card-present reader. Flutter multi-platform retained.

### Decision 11 / 12 / 14 locks (do not regress)

| Topic | Lock |
|--------|------|
| App binary (customer) | Hybrid multi-tenant; session = one `franchiseId` |
| Acquisition | QR/SMS primary; directory required foundation |
| Bind | `FranchiseBindService` only (no ad-hoc setFranchiseId for product flows) |
| Signed-out | Browse menu OK; **add-to-cart / cart / checkout require auth** (guest cart deferred) |
| Cart on switch | Confirm → clear cart & switch |
| Share QR | Prefer `https://franchisehq.io/f/{id}` |
| Stripe platform | HQ SaaS subscriptions / platform invoices |
| Stripe Connect | Customer card orders → franchise connected account + application fee |
| **Station surface** | **Thin POS (`pos_app`)** — counter / order-taking; **not** a pure kitchen-only binary |
| **Void / cancel / refund** | **Manager-only** (elevated permission + PIN) |
| **Printers** | Multi-printer ready; route by **menu category**; Ethernet ESC-POS preferred |
| **Pilot station device** | **Android tablet** at counter; codebase stays Flutter multi-platform |
| **Cash + drawer** | Required in thin POS MVP; auto-open drawer on cash tender |
| **Card-present** | Required in thin POS MVP |
| **Order source** | Structural field on every order for future metrics |
| **Release gate** | Thin POS + customer website + polished mobile + web management |

### Explicit post-MVP / deferred

| Surface | Decision |
|---------|----------|
| Guest cart / guest checkout | Post-MVP |
| Full OS App Links / AASA production hardening | Follow-up polish |
| Geo / map directory | Post-MVP |
| Live delivery status tracking | Out of thin POS MVP |
| Full catering packages | Out of thin POS MVP |
| Complex inventory / recipe costing | Post-MVP |
| Advanced tips pooling / full time-clock | Post-MVP |
| Rich offline card processing | Post-MVP |
| iOS station as primary pilot | Post-pilot |
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
