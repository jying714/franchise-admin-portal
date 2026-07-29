# HANDOFF.md — Agent Context & Project Status

**Last Updated**: July 29, 2026 (~15:50 CDT — MVP completion locks documented)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Active branch**: `main`  
**Repo**: https://github.com/jying714/franchise-admin-portal  
**Local path**: `C:\\projects\\franchise-admin-portal`  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Live web**: franchisehq.io (Deploy Web on push to `main` only)

Prefer **STATUS.md + this handoff + `docs/slices/*` + `docs/DECISIONS.md`** over agent memory.

---

## 1. Where we are

**On `main` and done:** HQ onboarding, Design & Branding, Platform Owner MVP, Admin ops v1, menu modifier **M1–M5**, wings/calzone **W0–W7+W2**, mobile design tokens **T1–T9**, developer dashboard **D0–D10**.

**Locked for release / pilot MVP (not yet built):**

1. **`docs/slices/customer-franchise-context-v1.md`** (Decision 11)  
2. **`docs/slices/stripe-checkout-v1.md`** (Decision 12)

Human will pilot with **one real franchise + one mock seeded franchise**.

---

## 2. Decision 11 — Customer multi-franchise (summary)

- **Hybrid binary:** one app, many tenants; **session = one franchiseId**; branding follows bind.  
- **A + B:** QR/SMS/deep link **primary**; **directory** (list + name/city search) **required foundation**.  
- **Same bind pipeline** for link, QR, directory, recents, switcher.  
- **Signed-out:** browse + cart OK; **pay requires sign-in**.  
- **Switch with cart:** confirm → clear cart → switch.  
- **Cold start:** deep link > last/recents > directory; no silent permanent single-tenant trap.

---

## 3. Decision 12 — Stripe (summary)

```text
HQ SaaS subscription / platform invoices  →  Platform Stripe account
Customer food order                      →  Franchise Connect account
                                         +  application fee → Platform
```

- **Not** long-term “platform holds all order money.”  
- Checkout is **Connect-shaped**; refuse pay if `paymentsEnabled` is false.  
- Test mode for mock + real until Connect live on real franchise.

---

## 4. Do not regress (menu)

- Pizza optionalAddOns contract; included toppings not auto-charged  
- Wings: 2 portions, dipping cups, type `sauces` only, W2 pool  
- No dual production menu write paths  
- No `FranchiseProvider()` zero-arg / DesignTokens color invention

---

## 5. What’s next (implementation order)

1. Implement **customer-franchise-context-v1** (CF1–CF9)  
2. Implement **stripe-checkout-v1** (ST0–ST7) against Connect fields  
3. Pilot polish (reorder, status, hours) under explicit tasks  

---

## 6. Key references

- `STATUS.md`  
- `docs/DECISIONS.md` (11, 12)  
- `docs/slices/customer-franchise-context-v1.md`  
- `docs/slices/stripe-checkout-v1.md`  
- `docs/slices/mobile-design-tokens-v1.md`  
- `docs/slices/developer-dashboard-v1.md`  
- `docs/slices/menu-modifier-system-rebuild-v1.md`  
- `docs/MOBILE_DYNAMIC.md`  

---

**Bottom line:** Platform vertical slice is on **main**. Release MVP = **franchise context (A+B)** + **dual Stripe (platform SaaS + Connect orders)** + pilot polish. Start with customer-franchise-context-v1 unless human prioritizes Connect HQ fields first.
