# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 30, 2026 (~17:05 CDT — stripe-checkout-v1 COMPLETE)  
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

**Just closed:**

| Slice | Decision | Branch |
|--------|----------|--------|
| `docs/slices/stripe-checkout-v1.md` | 12 | `feat/stripe-checkout-v1` (**COMPLETE** — ST0–ST8 smoke pass) |

**Locked (not started):**

| Slice | Decision |
|--------|----------|
| `docs/slices/pos-app-v1.md` | **14** (Thin POS Station App) |

**Superseded:**

| Slice | Note |
|--------|------|
| `docs/slices/kitchen-ops-v1.md` | Pure kitchen-only framing superseded by Decision 14. Do **not** implement a separate kitchen binary. |

**Hard release gate:** Thin POS + customer website + polished mobile_app + web-app management must all reach MVP quality before the product is considered releasable.

**Pilot:** real + mock franchise; **Android tablet at counter** + Ethernet ESC-POS printers in kitchen(s) + cash drawer + card-present reader.

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

Cash at counter / on pickup is handled by the thin POS (Decision 14), not Connect.

**Status:** **COMPLETE** (test-mode end-to-end smoke pass 2026-07-30). Residual only: move “How was your order?” survey to scheduled push (post-order experience).

---

## 4. Decision 14 — Thin POS Station App (summary)

- **Strike** standalone thin Kitchen management app.
- **Station** = `pos_app` (new Flutter target), primary placement **counter / order-taking**.
- Home: Dine-in (full custom 2D table map from web-app) / Carry-out / Delivery.
- Full order entry (menu + modifiers); open-ticket dine-in (pay at close); card-present + cash + drawer; split tenders; discounts; large-order approval; multi-channel 86; allergens; staff/driver/waitress pay tracking; driver assignment on delivery completion.
- PIN session + role permissions; manager-only elevated actions.
- Incoming online orders: auto-print + shared list.
- Offline: cash only.
- Hard release gate includes **customer website**.

Authority: `docs/slices/pos-app-v1.md` · Decision 14.

---

## 5. Do not regress (menu + franchise context + station)

Pizza optionalAddOns; included not auto-charged; wings 2 portions + W2 pool; no dual menu write paths; no FranchiseProvider zero-arg / DesignTokens color invention; **no silent default tenant**; **no product bind outside FranchiseBindService**; progress load includes **`onboarding_design_branding`**; **do not implement a pure kitchen-only binary**.

---

## 6. Implementation order

1. ~~Customer franchise context v1~~ **DONE on `main`**  
2. ~~Stripe checkout v1~~ **DONE** (`feat/stripe-checkout-v1`, ST0–ST8 smoke pass)  
3. Polish mobile_app + web-app management  
4. **Thin POS (`pos_app`)** per Decision 14 / `pos-app-v1.md`  
5. Customer website (part of hard release gate)  
6. Pilot polish  

---

## 7. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (11–14; **14 is station authority**)  
- `docs/slices/customer-franchise-context-v1.md` (**COMPLETE on main**)  
- `docs/slices/stripe-checkout-v1.md` (**COMPLETE**)  
- `docs/slices/pos-app-v1.md` (**locked station surface**)  
- `docs/slices/kitchen-ops-v1.md` (**superseded** — historical only)  
- `docs/slices/mobile-design-tokens-v1.md`  
- `docs/slices/menu-modifier-system-rebuild-v1.md`  

---

### 2026-07-30 — stripe-checkout-v1 closed
Card path live in test mode on feat/stripe-checkout-v1.  
Residual only: move “How was your order?” survey to scheduled push (post-order experience).  
Next product focus remains polish + Thin POS (Decision 14).

---

**Bottom line:** Customer franchise context is on **`main`**. Stripe card path is **COMPLETE** on `feat/stripe-checkout-v1`. Station surface is **thin POS (`pos_app`)** under Decision 14 — do **not** build a pure kitchen-only app. Hard release gate includes customer website.
