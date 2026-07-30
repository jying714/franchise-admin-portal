# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 29, 2026 (~23:30 CDT — customer franchise context v1 complete)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/customer-franchise-context-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Where we are

**On `main` and done:** HQ onboarding, Design & Branding, Platform Owner, Admin ops, menu M1–M5 + wings/calzone, mobile design tokens T1–T9, developer dashboard D0–D10.

**On `feat/customer-franchise-context-v1` (COMPLETE — human merge gate):** Decision 11 customer franchise context — bind pipeline, directory, QR/https, recents/switcher, cart clear, signed-out browse + auth-gated cart/checkout.

**Still locked for release / pilot MVP (not yet built):**

| Slice | Decision |
|--------|----------|
| `docs/slices/stripe-checkout-v1.md` | 12 |
| `docs/slices/kitchen-ops-v1.md` | 13 |

Pilot: **real + mock** franchise; make-line **Android tablet** + Ethernet ESC-POS; DoorDash-like placement.

---

## 2. Decision 11 — Customer multi-franchise (delivered)

Hybrid binary; session = one franchiseId; QR/SMS/https primary + directory foundation; **signed-out browse menu**; **add-to-cart / cart / checkout require auth** (guest cart deferred); cart clear on switch; `FranchiseBindService` single pipeline.

Authority: `docs/slices/customer-franchise-context-v1.md` (closed).

---

## 3. Decision 12 — Stripe (summary)

```text
HQ SaaS     → Platform Stripe account
Card orders → Franchise Connect + application fee → Platform
```

Cash is **not** Connect; see Decision 13 toggles.

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

Pizza optionalAddOns; included not auto-charged; wings 2 portions + W2 pool; no dual menu write paths; no FranchiseProvider zero-arg / DesignTokens color invention; **no silent default tenant**; **no product bind outside FranchiseBindService**.

---

## 6. Implementation order

1. ~~Customer franchise context v1~~ **DONE** (branch; merge when ready)  
2. Stripe checkout v1 (card path enables kitchen paid feed)  
3. Kitchen ops v1 (board + print + cash flags + manager gates)  
4. Pilot polish  

Kitchen can use test paid/submitted orders in parallel once order status model is clear.

---

## 7. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (11–13)  
- `docs/slices/customer-franchise-context-v1.md` (**COMPLETE**)  
- `docs/slices/stripe-checkout-v1.md`  
- `docs/slices/kitchen-ops-v1.md`  
- `docs/slices/mobile-design-tokens-v1.md`  
- `docs/slices/menu-modifier-system-rebuild-v1.md`  

---

**Bottom line:** Customer franchise context is implemented on the feature branch. Next build focus = **dual Stripe + thin kitchen ops**. Cooks never get full Admin on the pass tablet.
