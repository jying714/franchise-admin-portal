# Slice: Manager burn-in v1

**Status:** ACTIVE on `feat/manager-burn-in-fixes`  
**Authority for:** Soft-release manager burn-in gaps only  
**Branch:** `feat/manager-burn-in-fixes`  
**Does not:** schema invent, net-new product surfaces, extract refactors (repos / customization)

---

## 1. Goal

Prove soft-release software is safe for soft parallel with Owner.com. Code changes on this branch only when burn-in finds a concrete gap (log path + repro + expected).

---

## 2. Burn-in checklist (operator)

| # | Area | Pass criteria |
|---|------|----------------|
| 1 | Inventory 86 | Mark item 86 → mobile/web/POS block sell-through; restock restores |
| 2 | Clock | Station unlock requires open punch; off-shift needs manager PIN |
| 3 | Web order | customer_web (default or Modern) → pay or COD path completes |
| 4 | Mobile order | Customize → cart → checkout → paid/cash path |
| 5 | Delivery COD | Accept & deliver → Returned → Close out cash |
| 6 | Promo | Admin code + daypart; mobile + web apply; banner → pending code |
| 7 | POS board | Open orders status transitions; void/comp/print if exercised |
| 8 | Staff perms | Station roster grants match allowed actions |

Log failures under §4 with: surface, steps, expected, actual, screenshot/log if any.

---

## 3. Known deferred (do not treat as burn-in blockers)

- SendGrid portal invite email (credits / billing)
- Post-order "How was your order?" → scheduled push (stripe-checkout residual)
- Promo residuals (bundle type, banner auto-nav) unless burn-in requires
- customer mobile iOS (Mac)
- Hardware pilot devices

---

## 4. Gap log (fill during burn-in)

| Date | Gap | Surface | Fix PR / commit | Status |
|------|-----|---------|-----------------|--------|
| | | | | |

---

## 5. Locks

- Human is the merge gate.
- Prefer surgical fix on the failing surface only.
- No god-object extract on this branch.
- Soft parallel ≠ hard Owner.com cutover.

**Last updated:** 2026-08-10
