# STATUS.md — Live Project Snapshot

**Last Updated**: August 2, 2026 (~22:15 CDT — customer_web parity core merged to main)  
**Hardware**: MINISFORUM AI X1 Pro-470  
**Branch (active work)**: **`main`**  
**Main**: HQ Restaurant settings · customer_web MVP + **parity core** (customize/cart/checkout) · POS/mobile/HQ pilots  
**Firebase**: `doughboyspizzeria-2b3d2`  
**Storefront**: https://franchise-storefront.web.app  
**Admin/HQ**: franchisehq.io

> This file is **always loaded in full** by every agent.

---

## Current phase

| Area | State |
|------|--------|
| HQ / Admin / menu / mobile / POS pilot | **On main** |
| HQ Restaurant settings v1 | **Merged to main** (branch deleted) |
| Customer website MVP path | **On main** |
| **customer_web parity core** | **Merged to main** (`feat/customer-web-parity-v1` deleted) |
| Marketing shell / directory / promos / loyalty | **Open** (plan residual) |

---

## customer_web parity core (on main)

**Shipped (2026-08-02):**

| Surface | Detail |
|---------|--------|
| **Menu customize (pizza)** | Size, current toppings + remove, meats/veggies add-ons, cheeses (max 2), sauces (max 2 + L/R rule), double, portion, structural crust/cook/cut, notes, pricing, cart payload |
| **Menu customize (wings)** | Size, **2-portion** Plain/sauce halves, dip cups (free by size + upcharge), validation, payload |
| **Menu customize (sub)** | Cook structural + current toppings path |
| **Widget split** | Size, order details, toppings, cheeses, sauces, notes, qty/total, wings sauce/dips |
| **Cart** | Shared `lineCustomizationSummary`; qty; **Edit line** replace via `cartItemKey` |
| **Checkout** | Pickup / delivery; structured `deliveryAddress` (Address schema); fee $5; tax/hours from `store_ops`; Stripe; line summary |
| **Order model** | `customerPhone` on `Order` + checkout write; `ScheduledOrder.copyWith` override |
| **addToCart** | Always assigns unique `cartItemKey` |

**Authority:** `docs/plans/customer-web-parity-brand-storefront-v1.md` · `docs/slices/customer-website-v1.md` · Decisions **11 / 12 / 14**

### Remaining (parity / storefront wave)

| Priority | Work |
|----------|------|
| **P0** | Marketing shell D0 (StorefrontAppBar, hero home, Story/Contact/Careers) reading `config/storefront` |
| **P1** | Promo codes on checkout |
| **P1** | Out-of-stock option disable; pre-seed edit customize from cart groups |
| **P2** | Directory / change restaurant; delivery fee from `store_ops`; saved addresses |
| **P2** | Loyalty feature-flagged |
| **P3** | Custom domains |

---

## HQ Restaurant settings

**On main.** One card → shell tabs: Brand, Website, Store ops, Channels, Payments, Station, Contact.  
**Authority:** `docs/slices/hq-restaurant-settings-v1.md`

Optional residual: FAQ/gallery/careers editors; Feature Setup deep-link; POS reads `config/pos`.

---

## Next product focus

1. **D0 brand shell / marketing pages** on `customer_web` (config already writable from HQ Website tab).  
2. Promos + store_ops-driven delivery fee.  
3. POS residual hardware / `config/pos` readers as needed.

**Decision locks:** 11 / 12 / 14.

---

**Update this file after significant sessions.**
