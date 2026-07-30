# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 30, 2026 (~10:30 CDT — stripe-checkout-v1 active)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/stripe-checkout-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Where we are

**On `main` and done:** HQ onboarding, Design & Branding, Platform Owner, Admin ops, menu M1–M5 + wings/calzone, mobile design tokens T1–T9, developer dashboard D0–D10, **customer franchise context v1** (Decision 11).

**Active implementation:**

| Slice | Decision | Branch |
|--------|----------|--------|
| `docs/slices/stripe-checkout-v1.md` | 12 | `feat/stripe-checkout-v1` (ST0 done; **ST1 next**) |

**Still locked (not started):**

| Slice | Decision |
|--------|----------|
| `docs/slices/kitchen-ops-v1.md` | 13 |

Pilot: **real + mock** franchise; make-line **Android tablet** + Ethernet ESC-POS; DoorDash-like placement.

---

## 2. Decision 11 — Customer multi-franchise (on main)

Hybrid binary; session = one franchiseId; QR/SMS/https primary + directory foundation; **signed-out browse menu**; **add-to-cart / cart / checkout require auth** (guest cart deferred); cart clear on switch; `FranchiseBindService` single pipeline; guest app bar slim (title + change restaurant).

Authority: `docs/slices/customer-franchise-context-v1.md` (**COMPLETE on main**).

---

## 3. Decision 12 — Stripe (summary)

```text
HQ SaaS     → Platform Stripe account
Card orders → Franchise Connect + application fee → Platform
```

Cash is **not** Connect; see Decision 13 toggles.

**Current work:** ST1 — franchise fields (`stripeConnectAccountId`, status, `paymentsEnabled`) + rules honesty. See slice for full ST0–ST8.

---

## 4. Decision 13 — Kitchen ops + cash (summary)

- **Thin Kitchen Flutter app** for cooks (not full Admin on make line).
- **Admin feature cards:** e.g. Inventory toggle, **Cash on pickup** toggle; sub-toggle **require accept before cash print**.
- Card: auto-print on **paid**. Cash: default print on **submit**; optional print after **Accept**.
- Multi-printer: category → printer mapping.
- Void/cancel/refund: **manager-only**.
- Manager **push + SMS** on tablet offline / print failure.
- Pilot hardware: **Android** kitchen tablet; Flutter remains multi-platform.

---

## 5. Do not regress (menu + franchise context)

Pizza optionalAddOns; included not auto-charged; wings 2 portions + W2 pool; no dual menu write paths; no FranchiseProvider zero-arg / DesignTokens color invention; **no silent default tenant**; **no product bind outside FranchiseBindService**; progress load includes **`onboarding_design_branding`**.

---

## 6. Implementation order

1. ~~Customer franchise context v1~~ **DONE on `main`**  
2. **Stripe checkout v1** (card path enables kitchen paid feed) — **in progress**  
3. Kitchen ops v1 (board + print + cash flags + manager gates)  
4. Pilot polish  

Kitchen can use test paid/submitted orders in parallel once order status model is clear.

---

## 7. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (11–13)  
- `docs/slices/customer-franchise-context-v1.md` (**COMPLETE on main**)  
- `docs/slices/stripe-checkout-v1.md` (**active**)  
- `docs/slices/kitchen-ops-v1.md`  
- `docs/slices/mobile-design-tokens-v1.md`  
- `docs/slices/menu-modifier-system-rebuild-v1.md`  

---

**Bottom line:** Customer franchise context is on **`main`**. Active build focus = **dual Stripe on `feat/stripe-checkout-v1`** (ST1 next). Then **thin kitchen ops**. Cooks never get full Admin on the pass tablet.
