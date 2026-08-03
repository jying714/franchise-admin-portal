# customer_web Parity + Brand Storefront — Development Plan

**Status:** **Parity core COMPLETE on `main`** (2026-08-02); marketing D0 + P1 residual **open**  
**Authority:** Decisions **11 / 12 / 14** · mobile_app as functional source of truth · franchise branding tokens · one Hosting site + optional custom domains  
**App path:** `customer_web/`  
**Related:** `docs/slices/customer-website-v1.md` · `docs/plans/customer-website-v1-development-plan.md` · STATUS · HANDOFF

---

## Progress snapshot (2026-08-02)

| Epic | Status |
|------|--------|
| **P0b** Full customize (pizza + wings + structural + payload) | **Done on main** |
| Cart line summary + edit replace (`cartItemKey`) | **Done on main** |
| **P1a** Checkout pickup/delivery + Address schema + customerPhone | **Done on main** (flat $5 fee; store_ops fee later) |
| **P0a** Category-first menu | Partial / prior path — verify vs plan |
| **D0** Brand shell & marketing pages | **Open** |
| **P1b** Promos | **Open** |
| **P1c** Directory & change restaurant | **Open** |
| **P2** Loyalty | **Open** |
| **D1** Custom domains | **Open** |
| **Q** Polish QA | Ongoing |

**Branch:** `feat/customer-web-parity-v1` **merged to main and deleted**.

---

## Product statement

> `customer_web` is the **public franchise storefront**: marketing-quality restaurant website **and** full online ordering.  
> **Ordering logic** matches **mobile_app** (categories, profile-aware customize, cart, pickup/delivery, promos, loyalty, bind).  
> **Visual design** is a **branded web experience** (hero, story, map, inviting layout)—not a reskin of the mobile app UI.  
> Long-term, **custom domains** CNAME to the same Hosting deployment; hostname → `franchiseId` mapping.

---

## Suggested next implementation order

```text
D0.1–D0.10   Brand shell + hero home + Story/Contact/Careers (config/storefront)
P1b          Promo codes
P1a residual store_ops deliveryFee; saved addresses
P1c          Directory / change restaurant
P2           Loyalty
D1           Custom domain cutover
Q            Hardening
```

---

## P0b customize — acceptance (met)

- [x] Profile detection (pizza / wings / sub / …)  
- [x] Size + structural crust/cook/cut  
- [x] Included remove; double; portion L/W/R  
- [x] Cheeses / sauces sections + sauce L/R rule  
- [x] Wings 2-portion Plain/sauce + dip cups free/paid  
- [x] Live price + qty + cart payload  
- [x] Validation  

## P1a delivery — acceptance (met for MVP)

- [x] Pickup vs Delivery toggle  
- [x] Structured `deliveryAddress` (name, street, city, state, zip, label, id)  
- [x] `customerPhone` on Order  
- [x] Flat delivery fee $5 (HQ/store_ops fee optional residual)  
- [x] Hours / tax gate retained  

---

## Explicit non-goals (this wave)

- Guest cart · Tips · Chat · Live tracking · Scheduled orders  
- Second menu/modifier system · Per-franchise Hosting projects  
- Exact mobile visual clone  

---

**Update STATUS/HANDOFF when epics complete.** Full original epic tables remain valid for residual work; this header is the live progress source.
