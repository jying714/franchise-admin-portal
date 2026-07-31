# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 30, 2026 (~20:50 CDT — residual polish COMPLETE; active = Thin POS)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `feat/pos-app-v1`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Where we are

**On `main` and done:** HQ onboarding, Design & Branding, Platform Owner, Admin ops, menu M1–M5 + wings/calzone, mobile design tokens T1–T9, developer dashboard D0–D10, **customer franchise context v1** (Decision 11), **stripe-checkout-v1** (Decision 12), **mobile + web residual design-tokens polish**.

**Just closed:**

| Slice / work | Decision | Notes |
|--------------|----------|--------|
| `docs/slices/stripe-checkout-v1.md` | 12 | COMPLETE — ST0–ST8 smoke pass |
| Mobile + web residual polish | — | `feat/mobile-web-polish-v1` merged to `main` and deleted (July 30) |

**Active:**

| Slice | Decision |
|--------|----------|
| `docs/slices/pos-app-v1.md` | **14** Thin POS Station App — implementation open on `feat/pos-app-v1` |

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

## 4. Residual polish (closed July 30, 2026)

- **Mobile:** residual `UiConfig.*Color` / hard-coded chrome mapped to `Theme.of(context).colorScheme` roles on high-traffic + customization + feedback + address surfaces. **T8 auth/social still deferred.**
- **Web:** HQ secondary text → `onSurfaceVariant`; keep `DesignTokens.primaryColor` / `secondaryColor` as live branding path; customization groups, invoice error honesty, language selector honesty, header help/settings cleanup.
- Firestore rules: `users/{userId}/addresses` owner read/write for signed-in customer.

Do not regress ColorScheme role discipline or invent new DesignTokens per-widget colors.

---

## 5. Decision 14 — Thin POS Station App (summary)

- **Strike** standalone thin Kitchen management app.
- **Station** = `pos_app` (new Flutter target), primary placement **counter / order-taking**.
- Home: Dine-in (full custom 2D table map from web-app) / Carry-out / Delivery.
- Full order entry (menu + modifiers); open-ticket dine-in (pay at close); card-present + cash + drawer; split tenders; discounts; large-order approval; multi-channel 86; allergens; staff/driver/waitress pay tracking; driver assignment on delivery completion.
- PIN session + role permissions; manager-only elevated actions.
- Incoming online orders: auto-print + shared list.
- Offline: cash only.
- Hard release gate includes **customer website**.

Authority: `docs/slices/pos-app-v1.md` · Decision 14.

**First implementation focus (suggested):** P1 shell — `pos_app` target, franchise lock, PIN session, role permissions — then order list + entry.

---

## 6. Do not regress (menu + franchise context + station + tokens)

Pizza optionalAddOns; included not auto-charged; wings 2 portions + W2 pool; no dual menu write paths; no FranchiseProvider zero-arg / DesignTokens color invention; **no silent default tenant**; **no product bind outside FranchiseBindService**; progress load includes **`onboarding_design_branding`**; **do not implement a pure kitchen-only binary**; mobile chrome uses ColorScheme roles; web live brand via DesignTokens primary/secondary.

---

## 7. Implementation order

1. ~~Customer franchise context v1~~ **DONE on `main`**  
2. ~~Stripe checkout v1~~ **DONE on `main`**  
3. ~~Polish mobile_app + web-app management~~ **DONE on `main`**  
4. **Thin POS (`pos_app`)** per Decision 14 / `pos-app-v1.md` ← **NOW**  
5. Customer website (part of hard release gate)  
6. Pilot polish  

---

## 8. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (11–14; **14 is station authority**)  
- `docs/slices/customer-franchise-context-v1.md` (**COMPLETE**)  
- `docs/slices/stripe-checkout-v1.md` (**COMPLETE**)  
- `docs/slices/mobile-design-tokens-v1.md` (**COMPLETE**; residual polish absorbed)  
- `docs/slices/pos-app-v1.md` (**active station surface**)  
- `docs/slices/kitchen-ops-v1.md` (**superseded** — historical only)  
- `docs/slices/menu-modifier-system-rebuild-v1.md`  

---

### 2026-07-30 — residual polish closed; POS branch active
Card path COMPLETE. Mobile+web residual design-tokens polish merged to `main`.  
**Next product focus: Thin POS (`feat/pos-app-v1`) under Decision 14.**

---

**Bottom line:** Platform core, customer context, Stripe, and residual polish are on **`main`**. Station surface is **thin POS (`pos_app`)** — do **not** build a pure kitchen-only app. Hard release gate still includes customer website.
